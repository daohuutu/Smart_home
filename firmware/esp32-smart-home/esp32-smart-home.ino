/**
 * Smart Home — ESP32 Firmware
 *
 * Thư viện cần cài (Arduino Library Manager):
 *   - WebSockets by Markus Sattler
 *   - DHT sensor library by Adafruit (+ Adafruit Unified Sensor)
 *   - ArduinoJson by Benoit Blanchon
 *   - ESP32Servo by Kevin Harrington
 *
 * Board: ESP32 DevKit (WROOM-32)
 */

#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include "config.h"

// ── Socket.IO event names (phải khớp server Phần 2) ──
static const char* EVT_SENSOR_DATA   = "sensor_data";
static const char* EVT_DEVICE_STATUS = "device_status";
static const char* EVT_DEVICE_CMD    = "device_command";
static const char* EVT_GAS_ALERT     = "gas_alert";

// ── Hardware ──────────────────────────────────────────
DHT dht(PIN_DHT22, DHT22);
Servo lockServo;
WebSocketsClient webSocket;

// ── Trạng thái thiết bị ───────────────────────────────
struct DeviceState {
  bool light       = false;
  bool fan         = false;
  bool buzzer      = false;
  bool lockOpen    = false;
  bool gasAlert    = false;
} state;

// ── Timing ────────────────────────────────────────────
unsigned long lastSensorMs    = 0;
unsigned long lastWifiRetryMs = 0;
unsigned long lastWsRetryMs   = 0;
bool socketConnected          = false;
bool pendingConnect           = false;

// ── Relay helper ──────────────────────────────────────
void setRelay(int pin, bool on) {
#if RELAY_ACTIVE_LOW
  digitalWrite(pin, on ? LOW : HIGH);
#else
  digitalWrite(pin, on ? HIGH : LOW);
#endif
}

void applyOutputs() {
  setRelay(PIN_RELAY_LIGHT,  state.light);
  setRelay(PIN_RELAY_FAN,    state.fan);
  // Còi: bật khi server yêu cầu HOẶC cảnh báo gas local
  setRelay(PIN_RELAY_BUZZER, state.buzzer || state.gasAlert);
  lockServo.write(state.lockOpen ? SERVO_ANGLE_OPEN : SERVO_ANGLE_CLOSED);
  digitalWrite(PIN_LED_STATUS, socketConnected ? HIGH : LOW);
}

// ── Socket.IO helpers ─────────────────────────────────
void socketEmit(const char* event, JsonDocument& doc) {
  if (!socketConnected) return;

  String payload;
  serializeJson(doc, payload);

  String packet = "42[\"" + String(event) + "\",";
  packet += payload;
  packet += "]";

  webSocket.sendTXT(packet);
}

void socketEmitRaw(const char* event, const String& jsonBody) {
  if (!socketConnected) return;
  String packet = "42[\"" + String(event) + "\"," + jsonBody + "]";
  webSocket.sendTXT(packet);
}

void handleSocketMessage(char* message) {
  // Engine.IO ping → trả pong
  if (message[0] == '2' && message[1] == '\0') {
    webSocket.sendTXT("3");
    return;
  }

  // Mở kết nối Engine.IO → gửi CONNECT namespace "/"
  if (message[0] == '0') {
    webSocket.sendTXT("40");
    return;
  }

  // Namespace connected
  if (strncmp(message, "40", 2) == 0) {
    socketConnected = true;
    pendingConnect  = false;
    Serial.println("[Socket.IO] Connected");

    JsonDocument reg;
    reg["role"]     = "esp32";
    reg["deviceId"] = DEVICE_ID;
    socketEmit("register", reg);

    emitDeviceStatus();
    return;
  }

  // Event packet: 42["event_name", {...}]
  if (strncmp(message, "42", 2) != 0) return;

  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, message + 2);
  if (err) return;

  JsonArray arr = doc.as<JsonArray>();
  if (arr.isNull() || arr.size() < 2) return;

  const char* event = arr[0];
  JsonObject  data  = arr[1];

  if (strcmp(event, EVT_DEVICE_CMD) != 0) return;
  if (!data["deviceId"].isNull() && strcmp(data["deviceId"], DEVICE_ID) != 0) return;

  const char* device = data["device"];
  if (!device) return;

  if (strcmp(device, "light") == 0) {
    state.light = data["state"] | false;
  } else if (strcmp(device, "fan") == 0) {
    state.fan = data["state"] | false;
  } else if (strcmp(device, "buzzer") == 0) {
    state.buzzer = data["state"] | false;
  } else if (strcmp(device, "lock") == 0) {
    state.lockOpen = data["state"] | false;
  }

  applyOutputs();
  emitDeviceStatus();
}

void webSocketEvent(WStype_t type, uint8_t* payload, size_t length) {
  switch (type) {
    case WStype_DISCONNECTED:
      socketConnected = false;
      Serial.println("[WebSocket] Disconnected");
      break;

    case WStype_CONNECTED:
      Serial.println("[WebSocket] TCP connected, waiting for Socket.IO handshake...");
      pendingConnect = true;
      break;

    case WStype_TEXT: {
      char msg[length + 1];
      memcpy(msg, payload, length);
      msg[length] = '\0';
      handleSocketMessage(msg);
      break;
    }

    default:
      break;
  }
}

// ── WiFi ──────────────────────────────────────────────
void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;

  unsigned long now = millis();
  if (now - lastWifiRetryMs < WIFI_RETRY_MS) return;
  lastWifiRetryMs = now;

  Serial.printf("[WiFi] Connecting to %s ...\n", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

void connectWebSocket() {
  if (WiFi.status() != WL_CONNECTED) return;
  if (socketConnected || pendingConnect) return;

  unsigned long now = millis();
  if (now - lastWsRetryMs < WS_RECONNECT_MS) return;
  lastWsRetryMs = now;

  Serial.printf("[WebSocket] Connecting to %s:%d ...\n", SERVER_HOST, SERVER_PORT);
  webSocket.begin(SERVER_HOST, SERVER_PORT, "/socket.io/?EIO=4&transport=websocket");
  webSocket.onEvent(webSocketEvent);
  webSocket.setReconnectInterval(WS_RECONNECT_MS);
}

// ── Sensor read ───────────────────────────────────────
SensorReading readSensors() {
  SensorReading r = {NAN, NAN, 0, 0, false};
  r.temperature = dht.readTemperature();
  r.humidity    = dht.readHumidity();
  r.gas         = analogRead(PIN_MQ2);
  r.airQuality  = analogRead(PIN_MQ135);
  r.motion      = digitalRead(PIN_PIR) == HIGH;
  return r;
}

// ── Emit events ───────────────────────────────────────
void emitSensorData(const SensorReading& r) {
  JsonDocument doc;
  doc["deviceId"] = DEVICE_ID;
  if (!isnan(r.temperature)) doc["temperature"] = r.temperature;
  if (!isnan(r.humidity))    doc["humidity"]    = r.humidity;
  doc["gas"]         = r.gas;
  doc["airQuality"]  = r.airQuality;
  doc["motion"]      = r.motion;
  doc["timestamp"]   = millis();

  socketEmit(EVT_SENSOR_DATA, doc);
}

void emitDeviceStatus() {
  JsonDocument doc;
  doc["deviceId"]   = DEVICE_ID;
  doc["light"]      = state.light;
  doc["fan"]        = state.fan;
  doc["buzzer"]     = state.buzzer;
  doc["lockOpen"]   = state.lockOpen;
  doc["gasAlert"]   = state.gasAlert;
  doc["timestamp"]  = millis();

  socketEmit(EVT_DEVICE_STATUS, doc);
}

void emitGasAlert(int gasValue) {
  JsonDocument doc;
  doc["deviceId"]  = DEVICE_ID;
  doc["gas"]       = gasValue;
  doc["threshold"] = THRESHOLD_GAS_MQ2;
  doc["timestamp"] = millis();

  socketEmit(EVT_GAS_ALERT, doc);
}

// ── Local gas check ───────────────────────────────────
void checkGasAlert(int gasValue) {
  bool alert = gasValue >= THRESHOLD_GAS_MQ2;

  if (alert && !state.gasAlert) {
    state.gasAlert = true;
    applyOutputs();
    emitGasAlert(gasValue);
    emitDeviceStatus();
    Serial.printf("[ALERT] Gas detected! ADC=%d\n", gasValue);
  } else if (!alert && state.gasAlert) {
    state.gasAlert = false;
    applyOutputs();
    emitDeviceStatus();
    Serial.println("[ALERT] Gas level normal");
  }
}

// ── Sensor loop (5s) ──────────────────────────────────
void processSensors() {
  unsigned long now = millis();
  if (now - lastSensorMs < SENSOR_INTERVAL_MS) return;
  lastSensorMs = now;

  SensorReading r = readSensors();

  if (isnan(r.temperature) || isnan(r.humidity)) {
    Serial.println("[DHT22] Read failed, retrying next cycle");
  } else {
    Serial.printf("[Sensor] T=%.1f°C H=%.1f%% Gas=%d AQI=%d Motion=%s\n",
                  r.temperature, r.humidity, r.gas, r.airQuality,
                  r.motion ? "YES" : "NO");
  }

  checkGasAlert(r.gas);

  if (socketConnected) {
    emitSensorData(r);
  }
}

// ── Setup / Loop ──────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== Smart Home ESP32 ===");

  pinMode(PIN_RELAY_LIGHT,  OUTPUT);
  pinMode(PIN_RELAY_FAN,    OUTPUT);
  pinMode(PIN_RELAY_BUZZER, OUTPUT);
  pinMode(PIN_PIR,          INPUT);
  pinMode(PIN_LED_STATUS,   OUTPUT);

  setRelay(PIN_RELAY_LIGHT,  false);
  setRelay(PIN_RELAY_FAN,    false);
  setRelay(PIN_RELAY_BUZZER, false);

  lockServo.setPeriodHertz(50);
  lockServo.attach(PIN_SERVO_LOCK, 500, 2400);
  lockServo.write(SERVO_ANGLE_CLOSED);

  dht.begin();

  analogReadResolution(12); // 0–4095

  connectWiFi();
}

void loop() {
  connectWiFi();
  connectWebSocket();
  webSocket.loop();
  processSensors();
}

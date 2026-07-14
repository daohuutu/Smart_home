/**
 * LƯU Ý VỀ CODE NON-BLOCKING (KHÔNG DÙNG FREERTOS)
 * 
 * Đây là cấu trúc cơ bản sử dụng millis() thay vì delay().
 * Tuy nhiên, bản thân hàm dht.readTemperature() của thư viện Adafruit là hàm BLOCKING.
 * Nó sẽ tự động đứng im (chặn chương trình) mất ~250 mili-giây mỗi khi được gọi.
 * 
 * Để hệ thống THỰC SỰ non-blocking 100% trên Arduino thông thường (chỉ dùng 1 Core),
 * bạn BẮT BUỘC phải tải và thay thế thư viện DHT.h hiện tại bằng thư viện DHTesp 
 * (hoặc DHT_Async) hỗ trợ chạy bất đồng bộ (Asynchronous).
 * 
 * Code dưới đây biểu diễn cấu trúc State Machine sử dụng millis() để điều phối.
 */

#include <WiFi.h>
#include <WebSocketsClient.h>
#include <ArduinoJson.h>
#include <DHT.h>
#include <ESP32Servo.h>
#include "config.h"

// ── Socket.IO event names ──
static const char* EVT_SENSOR_DATA   = "sensor_data";
static const char* EVT_DEVICE_STATUS = "device_status";
static const char* EVT_DEVICE_CMD    = "device_command";
static const char* EVT_GAS_ALERT     = "gas_alert";

DHT dht(PIN_DHT22, DHT22);
Servo lockServo;
WebSocketsClient webSocket;

struct DeviceState {
  bool light       = false;
  bool fan         = false;
  bool buzzer      = false;
  bool lockOpen    = false;
  bool gasAlert    = false;
} state;

unsigned long lastSensorMs    = 0;
unsigned long lastWifiRetryMs = 0;
unsigned long lastWsRetryMs   = 0;
bool socketConnected          = false;
bool pendingConnect           = false;

void setup() {
  Serial.begin(115200);
  delay(500);
  Serial.println("\n=== Smart Home ESP32 (Non-Blocking State Machine) ===");

  // Khởi tạo phần cứng (y hệt code cũ)
  // ...
  dht.begin();
}

// ── State Machine Loop ──────────────────────────────────
void loop() {
  unsigned long currentMillis = millis();

  // 1. Máy trạng thái WiFi (Không dùng delay)
  if (WiFi.status() != WL_CONNECTED) {
    if (currentMillis - lastWifiRetryMs >= WIFI_RETRY_MS) {
      lastWifiRetryMs = currentMillis;
      Serial.printf("[WiFi] Connecting to %s ...\n", WIFI_SSID);
      WiFi.mode(WIFI_STA);
      WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    }
  } 
  
  // 2. Máy trạng thái WebSocket (Không dùng delay)
  else if (!socketConnected && !pendingConnect) {
    if (currentMillis - lastWsRetryMs >= WS_RECONNECT_MS) {
      lastWsRetryMs = currentMillis;
      Serial.printf("[WebSocket] Connecting to %s:%d ...\n", SERVER_HOST, SERVER_PORT);
      webSocket.begin(SERVER_HOST, SERVER_PORT, "/socket.io/?EIO=4&transport=websocket");
      webSocket.onEvent(webSocketEvent); // Hàm này chứa logic bắt tay
      webSocket.setReconnectInterval(WS_RECONNECT_MS);
    }
  }

  // 3. Luôn luôn giữ liên lạc mạng (Cực kỳ nhanh, không block)
  if (WiFi.status() == WL_CONNECTED) {
    webSocket.loop();
  }

  // 4. Máy trạng thái Cảm biến (Thực thi mỗi 5 giây)
  if (currentMillis - lastSensorMs >= SENSOR_INTERVAL_MS) {
    lastSensorMs = currentMillis;
    
    // CẢNH BÁO: Hàm readTemperature() vẫn tốn ~250ms (nếu lỗi).
    // Trong 250ms này, webSocket.loop() sẽ không được chạy.
    float t = dht.readTemperature();
    float h = dht.readHumidity();
    int gas = analogRead(PIN_MQ2);
    int aqi = analogRead(PIN_MQ135);
    bool motion = digitalRead(PIN_PIR) == HIGH;

    // Gửi data
    // ... emitSensorData ...
  }
}

// (Các hàm socketEmit, webSocketEvent, helper tương tự như file gốc)

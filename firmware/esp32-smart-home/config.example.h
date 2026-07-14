#pragma once

// Sao chép file này thành config.h và điền thông tin thực tế.

// ── WiFi ──────────────────────────────────────────────
#define WIFI_SSID     "YOUR_WIFI_SSID"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// ── Server Socket.IO (LAN) ────────────────────────────
#define SERVER_HOST   "192.168.1.100"
#define SERVER_PORT   3000

// ── Thiết bị ──────────────────────────────────────────
#define DEVICE_ID     "esp32-living-room"

// ── GPIO — Cảm biến ───────────────────────────────────
#define PIN_DHT22     4
#define PIN_MQ2       34   // ADC1, input-only
#define PIN_MQ135     35   // ADC1, input-only
#define PIN_PIR       27

// ── GPIO — Actuator ───────────────────────────────────
#define PIN_RELAY_LIGHT   26
#define PIN_RELAY_FAN     25
#define PIN_RELAY_BUZZER  33
#define PIN_SERVO_LOCK    13
#define PIN_LED_STATUS    2    // LED onboard DevKit

// Relay active LOW (module xanh phổ biến): LOW = ON, HIGH = OFF
#define RELAY_ACTIVE_LOW  true

// ── Servo khóa cửa (SG90) ─────────────────────────────
#define SERVO_ANGLE_CLOSED  0
#define SERVO_ANGLE_OPEN    90

// ── Ngưỡng cảnh báo ───────────────────────────────────
#define THRESHOLD_TEMP_FAN   30.0f   // °C — server cũng có thể bật quạt
#define THRESHOLD_GAS_MQ2    2000    // ADC 0–4095
#define THRESHOLD_AQI_MQ135  1500    // ADC 0–4095

// ── Timing ────────────────────────────────────────────
#define SENSOR_INTERVAL_MS   5000   // Gửi dữ liệu mỗi 5 giây
#define WIFI_RETRY_MS        5000
#define WS_RECONNECT_MS      5000

struct SensorReading {
  float temperature;
  float humidity;
  int   gas;
  int   airQuality;
  bool  motion;
};

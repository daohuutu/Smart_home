#pragma once

// Cấu hình mặc định — sửa SSID/password và IP server trước khi nạp.

#define WIFI_SSID     "LAPTOP-6OAUEONV 5565"
#define WIFI_PASSWORD "18012005"

#define SERVER_HOST   "192.168.133.181"
#define SERVER_PORT   3000

#define DEVICE_ID     "esp32-living-room"

#define PIN_DHT22     4
#define PIN_MQ2       34
#define PIN_MQ135     35
#define PIN_PIR       27

#define PIN_RELAY_LIGHT   26
#define PIN_RELAY_FAN     25
#define PIN_RELAY_BUZZER  33
#define PIN_SERVO_LOCK    13
#define PIN_LED_STATUS    2

#define RELAY_ACTIVE_LOW  true

#define SERVO_ANGLE_CLOSED  0
#define SERVO_ANGLE_OPEN    90

#define THRESHOLD_TEMP_FAN   30.0f
#define THRESHOLD_GAS_MQ2    2000
#define THRESHOLD_AQI_MQ135  1500

#define SENSOR_INTERVAL_MS   5000
#define WIFI_RETRY_MS        5000
#define WS_RECONNECT_MS      5000

// Khai báo struct trong header để Arduino IDE auto-prototype không bị lỗi
struct SensorReading {
  float temperature;
  float humidity;
  int   gas;
  int   airQuality;
  bool  motion;
};

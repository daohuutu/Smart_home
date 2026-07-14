const config = require('../config');

/** Ban đêm: từ nightStartHour tới nightEndHour (hỗ trợ qua nửa đêm) */
function isNightTime(date = new Date()) {
  const hour = date.getHours();
  const { nightStartHour, nightEndHour } = config;

  if (nightStartHour > nightEndHour) {
    return hour >= nightStartHour || hour < nightEndHour;
  }
  return hour >= nightStartHour && hour < nightEndHour;
}

/**
 * Trả về danh sách lệnh tự động cần gửi tới ESP32.
 * @returns {Array<{device: string, state: boolean, reason: string}>}
 */
function evaluateAutomation(device, sensor) {
  const commands = [];
  const state = device.state || {};

  // Bật quạt khi nhiệt độ cao
  if (sensor.temperature != null && sensor.temperature >= config.autoFanTemp) {
    if (!state.fan) {
      commands.push({
        device: 'fan',
        state: true,
        reason: `Nhiệt độ ${sensor.temperature.toFixed(1)}°C >= ${config.autoFanTemp}°C`,
      });
    }
  } else if (state.fan && sensor.temperature != null && sensor.temperature < config.autoFanTemp - 2) {
    // Tắt quạt khi nhiệt giảm (hysteresis 2°C)
    commands.push({
      device: 'fan',
      state: false,
      reason: `Nhiệt độ giảm còn ${sensor.temperature.toFixed(1)}°C`,
    });
  }

  // Bật đèn khi có chuyển động ban đêm
  if (sensor.motion && isNightTime()) {
    if (!state.light) {
      commands.push({
        device: 'light',
        state: true,
        reason: 'Phát hiện chuyển động ban đêm',
      });
    }
  }

  return commands;
}

async function createAlertIfNew(Alert, { deviceId, type, message, severity, data }) {
  const since = new Date(Date.now() - 5 * 60 * 1000);
  const existing = await Alert.findOne({
    deviceId,
    type,
    resolved: false,
    createdAt: { $gte: since },
  });

  if (existing) return null;

  return Alert.create({ deviceId, type, message, severity, data });
}

module.exports = {
  isNightTime,
  evaluateAutomation,
  createAlertIfNew,
};

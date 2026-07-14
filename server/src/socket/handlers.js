const Device = require('../db/models/Device');
const SensorData = require('../db/models/SensorData');
const ActivityLog = require('../db/models/ActivityLog');
const Alert = require('../db/models/Alert');
const config = require('../config');
const { evaluateAutomation, createAlertIfNew } = require('../services/automation');

// deviceId → socket.id (ESP32)
const esp32Sockets = new Map();
// socket.id → 'esp32' | 'client'
const socketRoles = new Map();

async function upsertDevice(deviceId) {
  return Device.findOneAndUpdate(
    { deviceId },
    { $set: { online: true, lastSeen: new Date() } },
    { upsert: true, new: true, setDefaultsOnInsert: true }
  );
}

async function logActivity({ deviceId, action, target, state, source, message }) {
  return ActivityLog.create({ deviceId, action, target, state, source, message });
}

function sendDeviceCommand(io, deviceId, payload) {
  const esp32SocketId = esp32Sockets.get(deviceId);
  if (!esp32SocketId) {
    console.warn(`[Command] ESP32 offline: ${deviceId}`);
    return false;
  }
  io.to(esp32SocketId).emit('device_command', { deviceId, ...payload });
  return true;
}

function broadcastDashboard(io, payload) {
  io.emit('dashboard_update', payload);
}

function registerSocketHandlers(io) {
  io.on('connection', (socket) => {
    console.log(`[Socket] Connected: ${socket.id}`);
    socketRoles.set(socket.id, 'client');

    socket.on('register', async ({ role, deviceId }) => {
      if (role === 'esp32' && deviceId) {
        socketRoles.set(socket.id, 'esp32');
        esp32Sockets.set(deviceId, socket.id);
        socket.join(`device:${deviceId}`);
        socket.data.deviceId = deviceId;

        const device = await upsertDevice(deviceId);
        socket.emit('registered', { ok: true, deviceId, role: 'esp32' });
        broadcastDashboard(io, { type: 'device_online', deviceId, device });
        console.log(`[Socket] ESP32 registered: ${deviceId}`);
      } else {
        socketRoles.set(socket.id, 'client');
        socket.emit('registered', { ok: true, role: 'client' });
      }
    });

    // ── ESP32 → Server ────────────────────────────────
    socket.on('sensor_data', async (data) => {
      const deviceId = data.deviceId || socket.data.deviceId;
      if (!deviceId) return;

      socketRoles.set(socket.id, 'esp32');
      esp32Sockets.set(deviceId, socket.id);
      socket.data.deviceId = deviceId;

      await SensorData.create({
        deviceId,
        temperature: data.temperature,
        humidity: data.humidity,
        gas: data.gas,
        airQuality: data.airQuality,
        motion: !!data.motion,
      });

      const device = await Device.findOneAndUpdate(
        { deviceId },
        {
          $set: {
            online: true,
            lastSeen: new Date(),
            latestSensor: {
              temperature: data.temperature,
              humidity: data.humidity,
              gas: data.gas,
              airQuality: data.airQuality,
              motion: !!data.motion,
              updatedAt: new Date(),
            },
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );

      broadcastDashboard(io, { type: 'sensor_data', deviceId, data, device });

      // Cảnh báo AQI kém
      if (data.airQuality >= config.autoAqiThreshold) {
        const alert = await createAlertIfNew(Alert, {
          deviceId,
          type: 'aqi',
          severity: 'warning',
          message: `Chất lượng không khí kém (AQI ADC: ${data.airQuality})`,
          data: { airQuality: data.airQuality, threshold: config.autoAqiThreshold },
        });
        if (alert) {
          io.emit('alert_new', alert);
          await logActivity({
            deviceId,
            action: 'alert',
            target: 'system',
            source: 'automation',
            message: alert.message,
          });
        }
      }

      // Tự động hóa
      const autoCommands = evaluateAutomation(device, data);
      for (const cmd of autoCommands) {
        const sent = sendDeviceCommand(io, deviceId, { device: cmd.device, state: cmd.state });
        if (sent) {
          await logActivity({
            deviceId,
            action: cmd.state ? 'turn_on' : 'turn_off',
            target: cmd.device,
            state: cmd.state,
            source: 'automation',
            message: cmd.reason,
          });
        }
      }
    });

    socket.on('device_status', async (data) => {
      const deviceId = data.deviceId || socket.data.deviceId;
      if (!deviceId) return;

      const device = await Device.findOneAndUpdate(
        { deviceId },
        {
          $set: {
            online: true,
            lastSeen: new Date(),
            state: {
              light: !!data.light,
              fan: !!data.fan,
              buzzer: !!data.buzzer,
              lockOpen: !!data.lockOpen,
              gasAlert: !!data.gasAlert,
            },
          },
        },
        { upsert: true, new: true, setDefaultsOnInsert: true }
      );

      broadcastDashboard(io, { type: 'device_status', deviceId, data, device });
    });

    socket.on('gas_alert', async (data) => {
      const deviceId = data.deviceId || socket.data.deviceId;
      if (!deviceId) return;

      const alert = await createAlertIfNew(Alert, {
        deviceId,
        type: 'gas',
        severity: 'critical',
        message: `Rò rỉ khí gas! Giá trị ADC: ${data.gas}`,
        data: { gas: data.gas, threshold: data.threshold },
      });

      if (alert) {
        io.emit('alert_new', alert);
        await logActivity({
          deviceId,
          action: 'alert',
          target: 'system',
          source: 'esp32',
          message: alert.message,
        });
      }

      broadcastDashboard(io, { type: 'gas_alert', deviceId, data, alert });
    });

    // ── Flutter/Client → Server → ESP32 ───────────────
    socket.on('device_command', async (data) => {
      const { deviceId, device: target, state } = data;
      if (!deviceId || !target) return;

      const sent = sendDeviceCommand(io, deviceId, { device: target, state });
      if (sent) {
        await logActivity({
          deviceId,
          action: state ? 'turn_on' : 'turn_off',
          target,
          state,
          source: 'manual',
          message: `Điều khiển thủ công: ${target} → ${state ? 'ON' : 'OFF'}`,
        });
      }

      socket.emit('command_result', { ok: sent, deviceId, device: target, state });
    });

    socket.on('disconnect', async () => {
      const role = socketRoles.get(socket.id);
      const deviceId = socket.data.deviceId;

      if (role === 'esp32' && deviceId) {
        esp32Sockets.delete(deviceId);
        await Device.updateOne({ deviceId }, { $set: { online: false } });

        const alert = await Alert.create({
          deviceId,
          type: 'device_offline',
          severity: 'warning',
          message: `Thiết bị ${deviceId} mất kết nối`,
        });

        io.emit('alert_new', alert);
        broadcastDashboard(io, { type: 'device_offline', deviceId });
        console.log(`[Socket] ESP32 offline: ${deviceId}`);
      }

      socketRoles.delete(socket.id);
      console.log(`[Socket] Disconnected: ${socket.id}`);
    });
  });
}

module.exports = { registerSocketHandlers, sendDeviceCommand };

const mongoose = require('mongoose');
const config = require('../../config');

const sensorDataSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true, index: true },
    temperature: { type: Number },
    humidity: { type: Number },
    gas: { type: Number, required: true },
    airQuality: { type: Number, required: true },
    motion: { type: Boolean, default: false },
  },
  { timestamps: true }
);

// TTL index — tự xóa sau N ngày (Phần 5)
sensorDataSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: config.sensorTtlDays * 24 * 60 * 60 }
);

sensorDataSchema.index({ deviceId: 1, createdAt: -1 });

module.exports = mongoose.model('SensorData', sensorDataSchema);

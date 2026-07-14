const mongoose = require('mongoose');
const config = require('../../config');

const alertSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true, index: true },
    type: {
      type: String,
      enum: ['gas', 'aqi', 'motion', 'temperature', 'abnormal', 'device_offline'],
      required: true,
    },
    severity: {
      type: String,
      enum: ['info', 'warning', 'critical'],
      default: 'warning',
    },
    message: { type: String, required: true },
    data: { type: mongoose.Schema.Types.Mixed },
    resolved: { type: Boolean, default: false },
    resolvedAt: { type: Date },
  },
  { timestamps: true }
);

alertSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: config.alertTtlDays * 24 * 60 * 60 }
);

alertSchema.index({ deviceId: 1, createdAt: -1 });
alertSchema.index({ resolved: 1, createdAt: -1 });

module.exports = mongoose.model('Alert', alertSchema);

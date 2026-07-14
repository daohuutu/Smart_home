const mongoose = require('mongoose');
const config = require('../../config');

const activityLogSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true, index: true },
    action: {
      type: String,
      enum: ['turn_on', 'turn_off', 'open', 'close', 'alert', 'auto'],
      required: true,
    },
    target: {
      type: String,
      enum: ['light', 'fan', 'buzzer', 'lock', 'system'],
      required: true,
    },
    state: { type: Boolean },
    source: {
      type: String,
      enum: ['manual', 'automation', 'esp32', 'system'],
      default: 'system',
    },
    message: { type: String },
  },
  { timestamps: true }
);

activityLogSchema.index(
  { createdAt: 1 },
  { expireAfterSeconds: config.activityTtlDays * 24 * 60 * 60 }
);

activityLogSchema.index({ deviceId: 1, createdAt: -1 });

module.exports = mongoose.model('ActivityLog', activityLogSchema);

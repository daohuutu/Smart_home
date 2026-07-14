const mongoose = require('mongoose');

const deviceStateSchema = new mongoose.Schema(
  {
    light: { type: Boolean, default: false },
    fan: { type: Boolean, default: false },
    buzzer: { type: Boolean, default: false },
    lockOpen: { type: Boolean, default: false },
    gasAlert: { type: Boolean, default: false },
  },
  { _id: false }
);

const deviceSchema = new mongoose.Schema(
  {
    deviceId: { type: String, required: true, unique: true, index: true },
    name: { type: String, default: 'Smart Home Device' },
    location: { type: String, default: 'Living Room' },
    online: { type: Boolean, default: false },
    lastSeen: { type: Date },
    state: { type: deviceStateSchema, default: () => ({}) },
    latestSensor: {
      temperature: Number,
      humidity: Number,
      gas: Number,
      airQuality: Number,
      motion: Boolean,
      updatedAt: Date,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Device', deviceSchema);

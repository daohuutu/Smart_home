const express = require('express');
const Device = require('../db/models/Device');
const SensorData = require('../db/models/SensorData');
const ActivityLog = require('../db/models/ActivityLog');
const Alert = require('../db/models/Alert');

const router = express.Router();

router.get('/health', (_req, res) => {
  res.json({ ok: true, time: new Date().toISOString() });
});

router.get('/devices', async (_req, res) => {
  const devices = await Device.find().sort({ updatedAt: -1 });
  res.json(devices);
});

router.get('/dashboard/:deviceId', async (req, res) => {
  const device = await Device.findOne({ deviceId: req.params.deviceId });
  if (!device) return res.status(404).json({ error: 'Device not found' });

  const recentAlerts = await Alert.find({ deviceId: req.params.deviceId })
    .sort({ createdAt: -1 })
    .limit(5);

  res.json({ device, recentAlerts });
});

router.get('/sensors/:deviceId', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit || '100', 10), 500);
  const query = { deviceId: req.params.deviceId };

  if (req.query.from || req.query.to) {
    query.createdAt = {};
    if (req.query.from) query.createdAt.$gte = new Date(req.query.from);
    if (req.query.to) query.createdAt.$lte = new Date(req.query.to);
  }

  const data = await SensorData.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(data);
});

router.get('/activity/:deviceId', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
  const data = await ActivityLog.find({ deviceId: req.params.deviceId })
    .sort({ createdAt: -1 })
    .limit(limit);
  res.json(data);
});

router.get('/alerts/:deviceId', async (req, res) => {
  const limit = Math.min(parseInt(req.query.limit || '50', 10), 200);
  const query = { deviceId: req.params.deviceId };
  if (req.query.resolved !== undefined) {
    query.resolved = req.query.resolved === 'true';
  }

  const data = await Alert.find(query).sort({ createdAt: -1 }).limit(limit);
  res.json(data);
});

router.patch('/alerts/:id/resolve', async (req, res) => {
  const alert = await Alert.findByIdAndUpdate(
    req.params.id,
    { $set: { resolved: true, resolvedAt: new Date() } },
    { new: true }
  );
  if (!alert) return res.status(404).json({ error: 'Alert not found' });
  res.json(alert);
});

module.exports = router;

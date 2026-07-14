const cron = require('node-cron');
const config = require('../config');
const SensorData = require('../db/models/SensorData');
const ActivityLog = require('../db/models/ActivityLog');
const Alert = require('../db/models/Alert');

/**
 * TTL index xử lý phần lớn việc dọn dữ liệu.
 * Cron job bổ sung: xóa document resolved cũ, log thống kê.
 */
async function runCleanup() {
  const resolvedCutoff = new Date(Date.now() - config.alertTtlDays * 24 * 60 * 60 * 1000);

  const [resolvedAlerts] = await Promise.all([
    Alert.deleteMany({ resolved: true, resolvedAt: { $lt: resolvedCutoff } }),
  ]);

  const counts = {
    sensors: await SensorData.estimatedDocumentCount(),
    activities: await ActivityLog.estimatedDocumentCount(),
    alerts: await Alert.estimatedDocumentCount(),
  };

  console.log('[Cleanup] Done.', {
    deletedResolvedAlerts: resolvedAlerts.deletedCount,
    remaining: counts,
  });

  return counts;
}

function startCleanupCron() {
  if (!cron.validate(config.cleanupCron)) {
    console.warn('[Cleanup] Invalid CRON expression, skipped:', config.cleanupCron);
    return;
  }

  cron.schedule(config.cleanupCron, () => {
    runCleanup().catch((err) => console.error('[Cleanup] Error:', err.message));
  });

  console.log('[Cleanup] Cron scheduled:', config.cleanupCron);
}

module.exports = { runCleanup, startCleanupCron };

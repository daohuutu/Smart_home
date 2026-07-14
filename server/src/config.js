require('dotenv').config();

module.exports = {
  port: parseInt(process.env.PORT || '3000', 10),
  mongoUri: process.env.MONGODB_URI || 'mongodb://localhost:27017/smart_home',

  autoFanTemp: parseFloat(process.env.AUTO_FAN_TEMP || '30'),
  nightStartHour: parseInt(process.env.NIGHT_START_HOUR || '18', 10),
  nightEndHour: parseInt(process.env.NIGHT_END_HOUR || '6', 10),
  autoAqiThreshold: parseInt(process.env.AUTO_AQI_THRESHOLD || '1500', 10),

  sensorTtlDays: parseInt(process.env.SENSOR_TTL_DAYS || '30', 10),
  activityTtlDays: parseInt(process.env.ACTIVITY_TTL_DAYS || '90', 10),
  alertTtlDays: parseInt(process.env.ALERT_TTL_DAYS || '90', 10),

  cleanupCron: process.env.CLEANUP_CRON || '0 3 * * *',
};

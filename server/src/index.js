const express = require('express');
const http = require('http');
const cors = require('cors');
const { Server } = require('socket.io');

const config = require('./config');
const { connectDB } = require('./db/connection');
const apiRoutes = require('./routes/api');
const { registerSocketHandlers } = require('./socket/handlers');
const { startCleanupCron } = require('./services/cleanup');

async function main() {
  await connectDB();

  const app = express();
  app.use(cors());
  app.use(express.json());
  app.use('/api', apiRoutes);

  const server = http.createServer(app);
  const io = new Server(server, {
    cors: { origin: '*' },
    transports: ['websocket', 'polling'],
  });

  registerSocketHandlers(io);
  startCleanupCron();

  server.listen(config.port, '0.0.0.0', () => {
    console.log(`[Server] Running on http://0.0.0.0:${config.port}`);
    console.log('[Server] Socket.IO ready — ESP32 + Flutter');
  });
}

main().catch((err) => {
  console.error('[Server] Fatal:', err);
  process.exit(1);
});

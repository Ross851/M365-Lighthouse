import { getWebSocketServer } from './websocket-server';

// Initialize WebSocket server on startup
let initialized = false;

export function initializeWebSocketServer() {
  if (initialized) return;
  
  console.log('Initializing WebSocket server...');
  
  try {
    const wsServer = getWebSocketServer();
    console.log(`WebSocket server started on port ${process.env.WS_PORT || '8080'}`);
    initialized = true;
  } catch (error) {
    console.error('Failed to initialize WebSocket server:', error);
  }
}

// Initialize on module load if in server environment
if (typeof process !== 'undefined' && process.env.NODE_ENV !== 'test') {
  initializeWebSocketServer();
}
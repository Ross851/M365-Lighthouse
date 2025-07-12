import { WebSocketServer, WebSocket } from 'ws';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';

interface Client {
  id: string;
  ws: WebSocket;
  userId: string;
  sessionId?: string;
  isAlive: boolean;
}

interface Message {
  type: 'auth' | 'subscribe' | 'unsubscribe' | 'ping' | 'pong';
  token?: string;
  sessionId?: string;
  data?: any;
}

class PowerReviewWebSocketServer {
  private wss: WebSocketServer;
  private clients: Map<string, Client> = new Map();
  private sessions: Map<string, Set<string>> = new Map(); // sessionId -> clientIds
  private heartbeatInterval: NodeJS.Timeout;

  constructor(port: number = 8080) {
    this.wss = new WebSocketServer({ port });
    this.setupServer();
    this.startHeartbeat();
  }

  private setupServer() {
    this.wss.on('connection', (ws: WebSocket) => {
      const clientId = uuidv4();
      const client: Client = {
        id: clientId,
        ws,
        userId: '',
        isAlive: true
      };

      // Handle connection
      console.log(`New WebSocket connection: ${clientId}`);
      
      // Send welcome message
      ws.send(JSON.stringify({
        type: 'connected',
        clientId,
        message: 'Connected to PowerReview WebSocket server'
      }));

      // Handle messages
      ws.on('message', (data: Buffer) => {
        try {
          const message: Message = JSON.parse(data.toString());
          this.handleMessage(client, message);
        } catch (error) {
          console.error('Invalid message format:', error);
          ws.send(JSON.stringify({
            type: 'error',
            message: 'Invalid message format'
          }));
        }
      });

      // Handle pong for heartbeat
      ws.on('pong', () => {
        client.isAlive = true;
      });

      // Handle disconnect
      ws.on('close', () => {
        console.log(`Client disconnected: ${clientId}`);
        this.removeClient(clientId);
      });

      // Handle errors
      ws.on('error', (error) => {
        console.error(`WebSocket error for client ${clientId}:`, error);
      });

      // Store client temporarily (requires auth to be fully registered)
      this.clients.set(clientId, client);
    });
  }

  private handleMessage(client: Client, message: Message) {
    switch (message.type) {
      case 'auth':
        this.handleAuth(client, message.token);
        break;
      case 'subscribe':
        this.handleSubscribe(client, message.sessionId);
        break;
      case 'unsubscribe':
        this.handleUnsubscribe(client, message.sessionId);
        break;
      case 'ping':
        client.ws.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  }

  private handleAuth(client: Client, token?: string) {
    if (!token) {
      client.ws.send(JSON.stringify({
        type: 'error',
        message: 'Authentication token required'
      }));
      return;
    }

    try {
      const decoded = jwt.verify(token, JWT_SECRET) as any;
      client.userId = decoded.email;
      
      client.ws.send(JSON.stringify({
        type: 'authenticated',
        userId: client.userId,
        message: 'Authentication successful'
      }));
    } catch (error) {
      client.ws.send(JSON.stringify({
        type: 'error',
        message: 'Invalid authentication token'
      }));
      // Close connection after failed auth
      setTimeout(() => client.ws.close(), 1000);
    }
  }

  private handleSubscribe(client: Client, sessionId?: string) {
    if (!client.userId) {
      client.ws.send(JSON.stringify({
        type: 'error',
        message: 'Authentication required'
      }));
      return;
    }

    if (!sessionId) {
      client.ws.send(JSON.stringify({
        type: 'error',
        message: 'Session ID required'
      }));
      return;
    }

    // Add client to session
    if (!this.sessions.has(sessionId)) {
      this.sessions.set(sessionId, new Set());
    }
    this.sessions.get(sessionId)!.add(client.id);
    client.sessionId = sessionId;

    client.ws.send(JSON.stringify({
      type: 'subscribed',
      sessionId,
      message: `Subscribed to session ${sessionId}`
    }));
  }

  private handleUnsubscribe(client: Client, sessionId?: string) {
    if (!sessionId || !this.sessions.has(sessionId)) {
      return;
    }

    this.sessions.get(sessionId)!.delete(client.id);
    if (this.sessions.get(sessionId)!.size === 0) {
      this.sessions.delete(sessionId);
    }

    if (client.sessionId === sessionId) {
      client.sessionId = undefined;
    }

    client.ws.send(JSON.stringify({
      type: 'unsubscribed',
      sessionId,
      message: `Unsubscribed from session ${sessionId}`
    }));
  }

  private removeClient(clientId: string) {
    const client = this.clients.get(clientId);
    if (!client) return;

    // Remove from all sessions
    this.sessions.forEach((clients, sessionId) => {
      clients.delete(clientId);
      if (clients.size === 0) {
        this.sessions.delete(sessionId);
      }
    });

    this.clients.delete(clientId);
  }

  private startHeartbeat() {
    this.heartbeatInterval = setInterval(() => {
      this.clients.forEach((client) => {
        if (!client.isAlive) {
          console.log(`Client ${client.id} failed heartbeat, terminating`);
          client.ws.terminate();
          this.removeClient(client.id);
          return;
        }

        client.isAlive = false;
        client.ws.ping();
      });
    }, 30000); // 30 seconds
  }

  // Public method to send updates to a session
  public sendToSession(sessionId: string, data: any) {
    const sessionClients = this.sessions.get(sessionId);
    if (!sessionClients) return;

    const message = JSON.stringify({
      type: 'update',
      sessionId,
      timestamp: new Date().toISOString(),
      data
    });

    sessionClients.forEach(clientId => {
      const client = this.clients.get(clientId);
      if (client && client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message);
      }
    });
  }

  // Public method to broadcast to all authenticated clients
  public broadcast(data: any) {
    const message = JSON.stringify({
      type: 'broadcast',
      timestamp: new Date().toISOString(),
      data
    });

    this.clients.forEach(client => {
      if (client.userId && client.ws.readyState === WebSocket.OPEN) {
        client.ws.send(message);
      }
    });
  }

  public close() {
    clearInterval(this.heartbeatInterval);
    this.wss.close();
  }
}

// Export singleton instance
let wsServer: PowerReviewWebSocketServer | null = null;

export function getWebSocketServer(): PowerReviewWebSocketServer {
  if (!wsServer) {
    const port = parseInt(process.env.WS_PORT || '8080');
    wsServer = new PowerReviewWebSocketServer(port);
  }
  return wsServer;
}

export { PowerReviewWebSocketServer };
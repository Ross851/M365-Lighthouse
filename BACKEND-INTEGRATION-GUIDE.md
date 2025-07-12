# PowerReview Backend Integration Guide

## Overview

The PowerReview backend integration system provides a secure, real-time bridge between the web UI and PowerShell assessment scripts. It features WebSocket support for live updates, secure authentication, session management, and safe PowerShell execution.

## Architecture

### Core Components

1. **WebSocket Server** (`src/lib/websocket-server.ts`)
   - Real-time bidirectional communication
   - JWT-based authentication
   - Session-based message routing
   - Automatic heartbeat/keep-alive
   - Reconnection support

2. **PowerShell Executor** (`src/lib/powershell-executor.ts`)
   - Secure script execution with sandboxing
   - Process lifecycle management
   - Real-time output streaming
   - Timeout and resource limits
   - Clean process termination

3. **Session Manager** (`src/lib/session-manager.ts`)
   - Assessment session tracking
   - Progress monitoring
   - Results storage
   - User ownership verification

4. **Authentication Middleware** (`src/lib/auth-middleware.ts`)
   - JWT token validation
   - Role-based access control
   - Permission checking
   - Session ownership verification

## API Endpoints

### Assessment Management

#### Start Assessment
```
POST /api/assessment/start
Authorization: Bearer <jwt-token>
Content-Type: application/json

{
  "assessments": ["azuread", "exchange", "sharepoint"],
  "config": {
    "tenant": "contoso.onmicrosoft.com",
    "sharepointUrl": "https://contoso.sharepoint.com",
    "exchangeUrl": "https://outlook.office365.com"
  }
}

Response:
{
  "success": true,
  "sessionId": "session_1234567890_abc123",
  "websocketUrl": "ws://localhost:8080",
  "message": "Assessment started successfully"
}
```

#### Cancel Assessment
```
POST /api/sessions/{sessionId}/cancel
Authorization: Bearer <jwt-token>

Response:
{
  "success": true,
  "message": "Session cancelled successfully"
}
```

### Session Management

#### List Sessions
```
GET /api/sessions/list?all=true&status=running
Authorization: Bearer <jwt-token>

Response:
{
  "success": true,
  "sessions": [...],
  "count": 5
}
```

#### Get Session Logs
```
GET /api/sessions/{sessionId}/logs?type=execution
Authorization: Bearer <jwt-token>

Response:
{
  "success": true,
  "sessionId": "session_1234567890_abc123",
  "logType": "execution",
  "content": "...",
  "size": 2048
}
```

### Process Management

#### List Active Processes
```
GET /api/processes/list
Authorization: Bearer <jwt-token>

Response:
{
  "success": true,
  "processes": [
    {
      "processId": "uuid",
      "sessionId": "session_id",
      "startTime": "2024-01-01T00:00:00Z",
      "duration": 120000
    }
  ],
  "count": 1
}
```

## WebSocket Protocol

### Connection Flow

1. **Connect to WebSocket server**
   ```javascript
   const ws = new WebSocket('ws://localhost:8080');
   ```

2. **Authenticate**
   ```javascript
   ws.send(JSON.stringify({
     type: 'auth',
     token: 'your-jwt-token'
   }));
   ```

3. **Subscribe to session**
   ```javascript
   ws.send(JSON.stringify({
     type: 'subscribe',
     sessionId: 'session_1234567890_abc123'
   }));
   ```

### Message Types

#### System Messages
- `connected` - Initial connection established
- `authenticated` - Authentication successful
- `subscribed` - Subscribed to session updates
- `error` - Error occurred

#### Assessment Updates
- `session-created` - New session created
- `session-completed` - Assessment finished
- `session-failed` - Assessment failed
- `session-cancelled` - Assessment cancelled

#### Progress Updates
```javascript
{
  "type": "update",
  "sessionId": "session_1234567890_abc123",
  "data": {
    "type": "progress",
    "assessment": "azuread",
    "status": "running",
    "currentStep": 5,
    "totalSteps": 10
  }
}
```

#### Log Messages
```javascript
{
  "type": "update",
  "sessionId": "session_1234567890_abc123",
  "data": {
    "type": "log",
    "level": "INFO",
    "message": "[INFO] Scanning Azure AD configuration..."
  }
}
```

#### Metrics
```javascript
{
  "type": "update",
  "sessionId": "session_1234567890_abc123",
  "data": {
    "type": "metric",
    "name": "users-scanned",
    "value": 245
  }
}
```

## PowerShell Integration

### WebBridge Script

The `PowerReview-WebBridge.ps1` script acts as the interface between the web system and PowerShell assessments:

```powershell
# Send updates to the web UI
Send-WebUpdate -Type "log" -Data @{
    level = "INFO"
    message = "[INFO] Starting assessment..."
}

# Send metrics
Send-WebUpdate -Type "metric" -Data @{
    name = "users-scanned"
    value = $users.Count
}

# Send progress
Send-WebUpdate -Type "progress" -Data @{
    assessment = "azuread"
    status = "completed"
    duration = "15:23"
}
```

### Output Format

All PowerShell output is captured and parsed:
- Lines starting with `STREAM:` are parsed as JSON updates
- Other output is logged as raw text

## Security Features

### Authentication
- JWT-based authentication required for all API endpoints
- Token validation on every request
- Role-based permissions (admin, developer, viewer)

### Authorization
- Session ownership verification
- Role-based access control
- Granular permissions system

### Process Security
- PowerShell execution with `-NoProfile -NonInteractive`
- Execution policy bypass for signed scripts only
- Process timeout limits (default: 30 minutes)
- Resource monitoring and limits
- Clean process termination on cancellation

### Data Protection
- Session data isolated by user
- Output files stored in secure directories
- Sensitive information filtering in logs

## Client Integration

### JavaScript/TypeScript Client

```typescript
import { WebSocketClient } from './lib/websocket-client';

// Initialize client
const wsClient = new WebSocketClient('ws://localhost:8080', authToken);

// Connect
await wsClient.connect();

// Subscribe to session
wsClient.subscribeToSession(sessionId);

// Handle messages
wsClient.onMessage((message) => {
  console.log('Received:', message);
  
  if (message.type === 'update' && message.data.type === 'log') {
    // Handle log message
    console.log(message.data.message);
  }
});

// Cleanup
wsClient.disconnect();
```

### React Hook Example

```typescript
function useAssessment(sessionId: string) {
  const [logs, setLogs] = useState<string[]>([]);
  const [progress, setProgress] = useState(0);
  
  useEffect(() => {
    const client = new WebSocketClient(wsUrl, token);
    
    client.connect().then(() => {
      client.subscribeToSession(sessionId);
    });
    
    const unsubscribe = client.onMessage((message) => {
      if (message.data?.type === 'log') {
        setLogs(prev => [...prev, message.data.message]);
      } else if (message.data?.type === 'progress') {
        setProgress(message.data.currentStep / message.data.totalSteps * 100);
      }
    });
    
    return () => {
      unsubscribe();
      client.disconnect();
    };
  }, [sessionId]);
  
  return { logs, progress };
}
```

## Testing

### WebSocket Test Console

Access the test console at: `/api/websocket-test`

Features:
- Manual WebSocket connection testing
- Authentication flow testing
- Session subscription testing
- Real-time message monitoring

### API Testing with cURL

```bash
# Get auth token
TOKEN=$(curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"demo@powerreview.com","password":"demo"}' \
  | jq -r '.token')

# Start assessment
SESSION_ID=$(curl -X POST http://localhost:3000/api/assessment/start \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "assessments": ["azuread"],
    "config": {"tenant": "contoso.onmicrosoft.com"}
  }' | jq -r '.sessionId')

# Get session logs
curl -X GET "http://localhost:3000/api/sessions/$SESSION_ID/logs?type=execution" \
  -H "Authorization: Bearer $TOKEN"
```

## Deployment Considerations

### Environment Variables

```env
# JWT Configuration
JWT_SECRET=your-production-secret-key

# WebSocket Configuration
WS_PORT=8080
WS_HOST=0.0.0.0

# PowerShell Configuration
PS_EXECUTION_TIMEOUT=1800000  # 30 minutes
PS_MAX_CONCURRENT=5

# Session Configuration
SESSION_CLEANUP_DAYS=30
SESSION_OUTPUT_PATH=/var/powerreview/sessions
```

### Production Setup

1. **WebSocket Proxy Configuration**
   ```nginx
   location /ws {
       proxy_pass http://localhost:8080;
       proxy_http_version 1.1;
       proxy_set_header Upgrade $http_upgrade;
       proxy_set_header Connection "upgrade";
       proxy_set_header Host $host;
       proxy_set_header X-Real-IP $remote_addr;
   }
   ```

2. **Process Limits**
   - Set appropriate ulimits for the service user
   - Configure systemd resource limits
   - Monitor memory and CPU usage

3. **Security Hardening**
   - Run PowerShell executor with limited user privileges
   - Use AppArmor/SELinux profiles
   - Enable audit logging
   - Implement rate limiting

## Troubleshooting

### Common Issues

1. **WebSocket Connection Failed**
   - Check firewall rules for port 8080
   - Verify WebSocket server is running
   - Check proxy configuration

2. **PowerShell Execution Errors**
   - Verify PowerShell is installed
   - Check execution policy settings
   - Review script permissions

3. **Authentication Issues**
   - Verify JWT secret matches
   - Check token expiration
   - Validate user credentials

### Debug Mode

Enable debug logging:
```javascript
// Client-side
localStorage.setItem('DEBUG', 'powerreview:*');

// Server-side
DEBUG=powerreview:* npm run dev
```

## Performance Optimization

### WebSocket Optimization
- Use binary frames for large data
- Implement message compression
- Batch small updates
- Use heartbeat intervals appropriately

### PowerShell Optimization
- Pre-compile scripts
- Use runspaces for parallel execution
- Implement output buffering
- Cache authentication tokens

### Session Management
- Implement session pooling
- Clean up old sessions automatically
- Use efficient file storage
- Compress archived logs

## Future Enhancements

1. **Scaling**
   - Redis-based session storage
   - Multiple WebSocket server instances
   - Load balancing support
   - Horizontal scaling

2. **Features**
   - Real-time collaboration
   - Assessment scheduling
   - Webhook notifications
   - API rate limiting

3. **Security**
   - OAuth2/SAML support
   - Multi-factor authentication
   - Audit trail enhancements
   - Encryption at rest
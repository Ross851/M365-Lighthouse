import type { APIRoute } from 'astro';

export const GET: APIRoute = async () => {
  const html = `
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Test</title>
    <style>
        body {
            font-family: monospace;
            padding: 20px;
            background: #1a1a1a;
            color: #00ff00;
        }
        #status {
            padding: 10px;
            background: #333;
            margin-bottom: 20px;
            border-radius: 5px;
        }
        #messages {
            height: 400px;
            overflow-y: auto;
            background: #000;
            padding: 10px;
            border: 1px solid #00ff00;
            white-space: pre-wrap;
        }
        button {
            background: #00ff00;
            color: #000;
            border: none;
            padding: 10px 20px;
            margin: 5px;
            cursor: pointer;
            font-family: monospace;
            font-weight: bold;
        }
        button:hover {
            background: #00cc00;
        }
        input {
            background: #000;
            color: #00ff00;
            border: 1px solid #00ff00;
            padding: 5px;
            font-family: monospace;
            width: 300px;
        }
    </style>
</head>
<body>
    <h1>PowerReview WebSocket Test Console</h1>
    
    <div id="status">Status: Disconnected</div>
    
    <div>
        <input type="text" id="token" placeholder="JWT Token" value="demo-token">
        <button onclick="connect()">Connect</button>
        <button onclick="disconnect()">Disconnect</button>
    </div>
    
    <div>
        <input type="text" id="sessionId" placeholder="Session ID">
        <button onclick="subscribe()">Subscribe</button>
        <button onclick="unsubscribe()">Unsubscribe</button>
    </div>
    
    <div id="messages"></div>
    
    <script>
        let ws = null;
        let messageCount = 0;
        
        function log(message, type = 'info') {
            const messages = document.getElementById('messages');
            const timestamp = new Date().toISOString();
            const color = type === 'error' ? '#ff0000' : 
                         type === 'success' ? '#00ff00' : 
                         type === 'warn' ? '#ffff00' : '#00ffff';
            
            messages.innerHTML += \`<span style="color: \${color}">[\${timestamp}] \${message}</span>\\n\`;
            messages.scrollTop = messages.scrollHeight;
            messageCount++;
            
            // Limit messages
            if (messageCount > 1000) {
                const lines = messages.innerHTML.split('\\n');
                messages.innerHTML = lines.slice(-500).join('\\n');
                messageCount = 500;
            }
        }
        
        function updateStatus(status, color = '#00ff00') {
            document.getElementById('status').innerHTML = \`Status: <span style="color: \${color}">\${status}</span>\`;
        }
        
        function connect() {
            if (ws && ws.readyState === WebSocket.OPEN) {
                log('Already connected', 'warn');
                return;
            }
            
            const token = document.getElementById('token').value;
            if (!token) {
                log('Token required', 'error');
                return;
            }
            
            log('Connecting to WebSocket server...');
            updateStatus('Connecting...', '#ffff00');
            
            ws = new WebSocket('ws://localhost:8080');
            
            ws.onopen = () => {
                log('Connected! Authenticating...', 'success');
                updateStatus('Connected', '#00ff00');
                
                // Send auth
                ws.send(JSON.stringify({
                    type: 'auth',
                    token: token
                }));
            };
            
            ws.onmessage = (event) => {
                try {
                    const message = JSON.parse(event.data);
                    
                    switch(message.type) {
                        case 'authenticated':
                            log('Authentication successful!', 'success');
                            break;
                        case 'error':
                            log(\`Error: \${message.message || 'Unknown error'}\`, 'error');
                            break;
                        case 'update':
                            log(\`[UPDATE] \${JSON.stringify(message.data, null, 2)}\`);
                            break;
                        default:
                            log(\`[\${message.type}] \${JSON.stringify(message, null, 2)}\`);
                    }
                } catch (error) {
                    log(\`Raw message: \${event.data}\`);
                }
            };
            
            ws.onerror = (error) => {
                log(\`WebSocket error: \${error}\`, 'error');
                updateStatus('Error', '#ff0000');
            };
            
            ws.onclose = (event) => {
                log(\`Disconnected: \${event.code} - \${event.reason}\`, 'warn');
                updateStatus('Disconnected', '#ff0000');
                ws = null;
            };
        }
        
        function disconnect() {
            if (ws) {
                log('Closing connection...');
                ws.close();
            } else {
                log('Not connected', 'warn');
            }
        }
        
        function subscribe() {
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                log('Not connected', 'error');
                return;
            }
            
            const sessionId = document.getElementById('sessionId').value;
            if (!sessionId) {
                log('Session ID required', 'error');
                return;
            }
            
            ws.send(JSON.stringify({
                type: 'subscribe',
                sessionId: sessionId
            }));
            log(\`Subscribing to session: \${sessionId}\`);
        }
        
        function unsubscribe() {
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                log('Not connected', 'error');
                return;
            }
            
            const sessionId = document.getElementById('sessionId').value;
            if (!sessionId) {
                log('Session ID required', 'error');
                return;
            }
            
            ws.send(JSON.stringify({
                type: 'unsubscribe',
                sessionId: sessionId
            }));
            log(\`Unsubscribing from session: \${sessionId}\`);
        }
        
        // Auto-connect on load
        window.onload = () => {
            log('WebSocket Test Console Ready');
            log('Use a valid JWT token or "demo-token" for testing');
        };
    </script>
</body>
</html>
  `;

  return new Response(html, {
    status: 200,
    headers: { 'Content-Type': 'text/html' }
  });
};
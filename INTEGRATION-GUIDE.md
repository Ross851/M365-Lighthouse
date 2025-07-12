# PowerReview Integration Guide: Web UI to PowerShell Scripts

## Overview

This guide explains how the PowerReview web UI connects to and executes real PowerShell security assessment scripts.

## Architecture

```
┌─────────────────────┐     ┌─────────────────────┐     ┌─────────────────────┐
│   Web UI (Astro)    │────▶│   API Backend       │────▶│  PowerShell Scripts │
│                     │     │   (Node.js)         │     │                     │
│ • Assessment Form   │     │ • Authentication    │     │ • Real M365 Checks  │
│ • Real-time Updates │◀────│ • Session Manager   │◀────│ • Security Analysis │
│ • Progress Tracking │     │ • WebSocket Server  │     │ • Report Generation │
└─────────────────────┘     └─────────────────────┘     └─────────────────────┘
```

## How It Works

### 1. User Fills Assessment Form
The enhanced assessment page (`assessment-enhanced.astro`) collects:
- Customer information
- Environment size and custom metrics
- Services to assess (M365, Azure, DevOps)
- Assessment depth (quick, standard, deep)
- Detailed Purview questions
- Compliance requirements

### 2. API Call to Start Assessment
When user clicks "Start Assessment":
```javascript
// Web UI calls backend API
const response = await fetch('/api/assessment/start', {
    method: 'POST',
    headers: {
        'Authorization': `Bearer ${token}`
    },
    body: JSON.stringify(assessmentConfig)
});
```

### 3. Backend Executes PowerShell
The API endpoint (`/api/assessment/start.ts`):
- Creates a session with unique ID
- Executes `PowerReview-WebBridge-Enhanced.ps1`
- Passes configuration as parameters
- Streams real-time updates via WebSocket

### 4. PowerShell Bridge Script
`PowerReview-WebBridge-Enhanced.ps1`:
- Loads actual assessment modules
- Connects to Microsoft 365
- Runs real security checks
- Streams progress using STREAM: protocol
- Generates JSON results

### 5. Real-Time Updates
Progress updates flow back through:
```
PowerShell ──▶ STREAM:JSON ──▶ Backend ──▶ WebSocket ──▶ Web UI
```

Example stream message:
```json
STREAM:{"type":"progress","progress":45,"message":"Checking Azure AD users..."}
```

### 6. Results and Reporting
Assessment results are:
- Saved as JSON in session output folder
- Analyzed for executive insights
- Displayed in dashboard with evidence
- Available for export

## Key Components

### PowerShell Scripts

1. **PowerReview-WebBridge-Enhanced.ps1**
   - Main bridge between web and PowerShell
   - Handles authentication to M365
   - Executes actual security checks
   - Streams real-time updates

2. **PowerReview-ErrorHandling.ps1**
   - Provides safe command execution
   - Comprehensive error logging
   - Graceful failure handling

3. **PowerReview-Executive-Analysis.ps1**
   - Generates executive summaries
   - Creates tiered recommendations
   - Calculates business impact

### Backend Services

1. **PowerShellExecutor** (`lib/powershell-executor.ts`)
   - Spawns PowerShell processes
   - Captures output streams
   - Manages timeouts and cleanup

2. **SessionManager** (`lib/session-manager.ts`)
   - Tracks assessment sessions
   - Stores progress and results
   - Manages user access

3. **WebSocketServer** (`lib/websocket-server.ts`)
   - Real-time bidirectional communication
   - JWT authentication
   - Session-based routing

### Authentication Flow

1. User logs in via web UI
2. JWT token issued and stored
3. All API calls include bearer token
4. PowerShell runs under authenticated context

## Running a Test Assessment

1. **Start the Web UI**:
   ```bash
   cd powerreview-ui
   npm run dev
   ```

2. **Test PowerShell Integration**:
   ```powershell
   # Run test script
   .\Test-WebIntegration.ps1
   ```

3. **Monitor Output**:
   - Check `Output\[SessionId]\` folder
   - View `assessment.log` for details
   - Check `results.json` for findings

## Security Considerations

1. **Authentication Required**
   - JWT tokens for all API calls
   - Role-based access control
   - Session ownership verification

2. **PowerShell Execution**
   - Runs with `-NoProfile -NonInteractive`
   - Timeout limits enforced
   - Output sanitization

3. **Data Protection**
   - Results stored in secure folders
   - No credentials in logs
   - Encrypted WebSocket connections

## Troubleshooting

### Common Issues

1. **"Authentication failed"**
   - Ensure you have Global Reader or Security Admin role
   - Check if MFA is blocking non-interactive auth
   - Verify Azure AD app permissions

2. **"Script not found"**
   - Check POWERSHELL_SCRIPTS_PATH environment variable
   - Ensure scripts are in correct location
   - Verify file permissions

3. **"WebSocket connection failed"**
   - Check if WebSocket server is running
   - Verify firewall allows port 8080
   - Check JWT token validity

### Debug Mode

Enable detailed logging:
```powershell
$env:POWERREVIEW_DEBUG = "true"
.\PowerReview-WebBridge-Enhanced.ps1 -SessionId "debug-001" -Services "m365" -Depth "quick" -CustomerName "Test"
```

## Production Deployment

1. **Environment Variables**:
   ```env
   POWERSHELL_SCRIPTS_PATH=C:\PowerReview\Scripts
   JWT_SECRET=your-secret-key
   WEBSOCKET_PORT=8080
   ```

2. **Service Account**:
   - Create dedicated service account
   - Grant minimum required permissions
   - Enable certificate-based auth

3. **Monitoring**:
   - Enable application insights
   - Monitor session completion rates
   - Track error patterns

## Next Steps

1. **Extend Assessment Coverage**:
   - Add more security checks
   - Integrate additional services
   - Enhance AI analysis

2. **Improve Performance**:
   - Parallel execution for large tenants
   - Caching for repeat assessments
   - Optimize PowerShell queries

3. **Enhanced Reporting**:
   - Custom report templates
   - Automated remediation scripts
   - Compliance mapping

## Support

For issues or questions:
- Check logs in `Output\[SessionId]\`
- Review error.json for failures
- Enable debug mode for detailed output
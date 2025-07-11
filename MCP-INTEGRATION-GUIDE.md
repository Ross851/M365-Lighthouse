# PowerReview MCP Integration Guide

## 🚀 Overview

PowerReview v2.0 now integrates with Model Context Protocol (MCP) servers to provide AI-powered security assessments. This enables:

- **Automated M365 scanning** using browser automation
- **Intelligent analysis** with AI recommendations
- **Real-time monitoring** of security configurations
- **Automated remediation** script generation
- **Compliance tracking** against industry standards

## 📦 Integrated MCP Servers

### 1. **GitHub MCP Server**
- Manages PowerReview codebase
- Tracks assessment versions
- Handles issue reporting
- Automates deployments

### 2. **File System MCP Server**
- Reads/writes assessment reports
- Manages configuration files
- Stores assessment history
- Handles evidence collection

### 3. **Browser Tools MCP Server**
- Automates M365 portal interactions
- Captures screenshots for evidence
- Navigates admin centers
- Extracts configuration data

### 4. **Git MCP Server**
- Version controls assessments
- Tracks configuration changes
- Manages assessment branches
- Handles rollbacks

### 5. **Sequential Thinking MCP Server**
- Processes complex assessment logic
- Chains multiple security checks
- Builds assessment workflows
- Handles conditional logic

### 6. **Fetch MCP Server**
- Retrieves data from Microsoft APIs
- Fetches Graph API data
- Gets compliance reports
- Downloads audit logs

### 7. **Puppeteer MCP Server**
- Advanced browser automation
- Handles complex UI interactions
- Bypasses MFA challenges
- Captures dynamic content

### 8. **PowerReview AI Server**
- Custom MCP server for assessments
- Integrates all other MCP servers
- Provides AI-powered analysis
- Generates remediation scripts

## 🛠️ Installation

### Prerequisites
```bash
# Install Node.js 18+
# Install Python 3.8+
# Install Docker (optional)
```

### Install MCP Servers
```bash
cd /mnt/c/Users/Ross/M365-Lighthouse/mcp
npm install

# Install global MCP servers
npm run install-mcp
```

### Configure MCP
1. Copy `mcp.json` to your MCP configuration directory
2. Update environment variables:
```bash
export GITHUB_TOKEN="your-github-token"
export OPENAI_API_KEY="your-openai-key"  # Optional
```

### Start PowerReview AI Server
```bash
cd mcp
npm start
```

## 🎯 AI Assistant Features

### 1. **Automated Security Assessment**
```javascript
// The AI can run comprehensive assessments
{
  "tool": "run_security_assessment",
  "args": {
    "tenant": "contoso.onmicrosoft.com",
    "assessments": ["azuread", "exchange", "sharepoint"],
    "depth": "deep"
  }
}
```

### 2. **Security Posture Analysis**
```javascript
// Analyze specific services with AI insights
{
  "tool": "analyze_security_posture",
  "args": {
    "service": "azuread",
    "includeRecommendations": true
  }
}
```

### 3. **Remediation Script Generation**
```javascript
// Generate PowerShell scripts to fix issues
{
  "tool": "generate_remediation_script",
  "args": {
    "findings": ["MFA not enforced", "External sharing unrestricted"],
    "priority": "critical"
  }
}
```

### 4. **Compliance Comparison**
```javascript
// Compare with industry standards
{
  "tool": "compare_with_best_practices",
  "args": {
    "configPath": "./current-config.json",
    "framework": "microsoft"
  }
}
```

### 5. **Security Drift Monitoring**
```javascript
// Monitor configuration changes
{
  "tool": "monitor_security_drift",
  "args": {
    "baselineDate": "2025-01-01",
    "currentDate": "2025-07-11",
    "alertThreshold": 10
  }
}
```

## 💻 Web UI Integration

### AI Assistant Page
Navigate to `/ai-assistant` to access:
- Live MCP server status
- Interactive chat interface
- Quick action buttons
- Real-time results display

### Example Interactions
1. **"Run a security assessment"**
   - AI connects to M365 tenant
   - Uses browser automation to scan
   - Analyzes findings with AI
   - Presents actionable results

2. **"Fix MFA issues"**
   - Identifies users without MFA
   - Generates remediation script
   - Provides step-by-step guidance
   - Tracks implementation

3. **"Compare with CIS benchmarks"**
   - Loads current configuration
   - Compares with CIS standards
   - Identifies compliance gaps
   - Suggests improvements

## 🔧 Advanced Configuration

### Custom MCP Tools
Add custom tools to `powerreview-ai-server.js`:

```javascript
{
  name: 'custom_security_check',
  description: 'Your custom security check',
  inputSchema: {
    type: 'object',
    properties: {
      // Your parameters
    }
  }
}
```

### Browser Automation Setup
For headless operation:
```javascript
"puppeteer": {
  "env": {
    "BROWSER_HEADLESS": "true",
    "CHROME_PATH": "/usr/bin/google-chrome"
  }
}
```

### API Integration
Configure Microsoft Graph API:
```javascript
"fetch": {
  "env": {
    "GRAPH_API_ENDPOINT": "https://graph.microsoft.com/v1.0",
    "GRAPH_API_TOKEN": "${GRAPH_TOKEN}"
  }
}
```

## 📊 Assessment Workflow

1. **Pre-flight Checks**
   - Verify credentials
   - Check PIM activation
   - Validate URLs

2. **MCP Initialization**
   - Start required MCP servers
   - Verify connections
   - Load configurations

3. **AI-Powered Assessment**
   - Browser automation for portal access
   - API calls for data collection
   - AI analysis of findings
   - Real-time progress updates

4. **Report Generation**
   - Compile findings
   - Generate recommendations
   - Create remediation scripts
   - Export to multiple formats

5. **Continuous Monitoring**
   - Schedule periodic assessments
   - Track configuration drift
   - Alert on critical changes
   - Update compliance status

## 🔒 Security Considerations

- **Credentials**: Never store credentials in code
- **MCP Access**: Limit MCP server permissions
- **Data Protection**: Encrypt assessment results
- **Audit Trail**: Log all MCP operations
- **Network Security**: Use secure connections

## 🚨 Troubleshooting

### MCP Server Not Connecting
```bash
# Check server status
npm run status

# Restart servers
npm run restart

# Check logs
tail -f mcp/logs/powerreview-ai.log
```

### Browser Automation Issues
```bash
# Install Chrome dependencies
sudo apt-get install -y chromium-browser

# Set Chrome path
export CHROME_PATH=/usr/bin/chromium-browser
```

### API Rate Limits
- Implement exponential backoff
- Use caching for repeated requests
- Batch API calls when possible

## 📈 Future Enhancements

- **GPT-4 Integration**: Advanced threat analysis
- **Real-time Alerts**: Webhook notifications
- **Multi-tenant Dashboard**: Centralized view
- **Automated Remediation**: Direct fix implementation
- **Threat Intelligence**: Integration with threat feeds

## 🤝 Contributing

To add new MCP integrations:
1. Create MCP server wrapper
2. Add to `mcp.json`
3. Implement tool handlers
4. Update documentation
5. Submit pull request

## 📄 License

MIT License - See LICENSE file for details

---

**PowerReview v2.0** - AI-Powered M365 Security Assessments with MCP Integration
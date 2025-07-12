# PowerReview MCP Integration Guide

## Overview
The PowerReview UI now integrates with MCP (Model Context Protocol) servers to provide real assessment data and parallel PowerShell script execution.

## Key Features

### 1. Real Assessment Data Loading
- When users click "View" on a report in the reports page, they are redirected to the dedicated report viewer
- The report viewer fetches real assessment data from the `/api/assessment-data` endpoint
- This endpoint uses the Sequential Thinking MCP server to run PowerShell scripts in parallel

### 2. MCP Server Integration
The system uses several MCP servers configured in `mcp.json`:
- **Sequential Thinking**: Runs PowerShell assessment scripts in parallel
- **GitHub**: Version control for assessments
- **Filesystem**: Access to PowerReview files and reports
- **Browser Tools**: Automate M365 portal interactions

### 3. Dynamic Evidence Display
- PowerShell script outputs are stored as evidence
- Users can click "View Output" to see the full PowerShell execution results
- Evidence includes timestamps and can be copied to clipboard

### 4. Remediation Scripts
- Each finding includes remediation steps with PowerShell scripts
- Scripts can be viewed, copied, or downloaded as .ps1 files
- The `/api/remediation-script` endpoint provides context-aware scripts

## Architecture

```
User clicks "View Report"
    ↓
reports.astro → Navigates to → report-viewer.astro
    ↓
report-viewer loads assessment data via API
    ↓
/api/assessment-data.ts → Executes MCP command → Sequential Thinking MCP
    ↓
MCP runs PowerShell scripts in parallel
    ↓
Results parsed into findings, metrics, and evidence
    ↓
Report viewer displays real data with interactive features
```

## API Endpoints

### GET /api/assessment-data
Fetches assessment results using MCP servers.

Query parameters:
- `id`: Report ID
- `type`: Assessment type (full, security, compliance)
- `org`: Organization name
- `cache`: Whether to use cached results (default: true)

### GET /api/remediation-script
Fetches PowerShell remediation scripts for findings.

Query parameters:
- `id`: Script ID (e.g., 'enable-mfa-admins', 'AAD-001-remediate')

## How Real Data Flows

1. **Assessment Execution**:
   - Sequential Thinking MCP server runs PowerShell scripts based on assessment type
   - Scripts are grouped by priority and executed in parallel batches
   - Results include stdout, stderr, return codes, and timestamps

2. **Data Parsing**:
   - PowerShell outputs are parsed to extract security findings
   - Each finding includes severity, impact, evidence, and remediation steps
   - Metrics are calculated based on finding severities

3. **Display**:
   - Findings are dynamically rendered with real evidence
   - Charts update to show actual risk distribution
   - Evidence can be viewed in modal windows

## Fallback Behavior

If MCP servers are unavailable or scripts fail:
- The API returns demo data to ensure UI functionality
- Error messages notify users that demo data is being shown
- The UI remains fully interactive with sample findings

## Security Considerations

- MCP servers run in isolated processes
- PowerShell scripts execute with limited permissions
- All outputs are sanitized before display
- Sensitive data is not stored in browser storage

## Future Enhancements

1. **Real-time Progress**: Show script execution progress
2. **Scheduled Assessments**: Run assessments on a schedule
3. **Custom Scripts**: Allow users to add custom assessment scripts
4. **Export Options**: Generate PDF/Excel reports with real data
5. **Comparison View**: Compare assessments over time
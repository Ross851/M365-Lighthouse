// Code snippets for documentation page
export const codeSnippets = {
  quickStart: `# Clone the repository
git clone https://github.com/Ross851/M365-Lighthouse.git
cd M365-Lighthouse

# Install PowerShell modules
./Install-PowerReview.ps1

# Start the web UI
cd powerreview-ui
npm install
npm run dev`,

  powershellDirect: `# Run comprehensive assessment
./Start-PowerReview-Enhanced.ps1

# Run specific module
./Start-PowerReview-Enhanced.ps1 -Module "AzureAD"`,

  connectM365: `# Connect to Microsoft 365
Connect-AzureAD
Connect-ExchangeOnline
Connect-MicrosoftTeams

# Or use the all-in-one connection
Connect-AzureAD`,

  apiLogin: `POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@powerreview.com",
  "password": "your-password"
}`,

  apiAssessment: `POST /api/assessment/start
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "modules": ["azuread", "exchange", "sharepoint"],
  "depth": "comprehensive",
  "outputFormat": "json"
}`,

  apiResults: `GET /api/results/[sessionId]
Authorization: Bearer YOUR_TOKEN`,

  apiReport: `POST /api/reports/executive
Authorization: Bearer YOUR_TOKEN
Content-Type: application/json

{
  "format": "pdf",
  "includeEvidence": true,
  "clientName": "Organization Name"
}`,

  troubleshootModules: `# Install missing modules
Install-Module -Name ExchangeOnlineManagement -Force
Install-Module -Name Microsoft.Graph -Force
Install-Module -Name Microsoft.Online.SharePoint.PowerShell -Force`
};
# PowerReview Web Dashboard

Interactive web dashboard for PowerReview M365 Security Assessment Framework.

## 🚀 Deploy to Vercel

### Option 1: Deploy with Vercel CLI

```bash
# Install Vercel CLI
npm i -g vercel

# In the web directory
cd web
npm install

# Deploy
vercel

# Follow prompts:
# - Link to existing project? No
# - What's your project name? powerreview-dashboard
# - Which directory is your code in? ./
# - Want to override settings? No
```

### Option 2: Deploy via GitHub

1. Push this code to GitHub
2. Go to [vercel.com](https://vercel.com)
3. Click "Add New Project"
4. Import your GitHub repository
5. Select the `web` directory as root
6. Deploy!

### Option 3: Deploy via Web UI

1. Go to [vercel.com](https://vercel.com)
2. Sign up/Login (free account)
3. Click "Add New Project"
4. Click "Upload"
5. Drag the `web` folder
6. Click Deploy

## 🛠️ Local Development

```bash
cd web
npm install
npm run dev
```

Visit http://localhost:3000

## 📊 Features

- **Live Demo Dashboard** - Interactive demo of assessment results
- **Security Score Visualization** - Doughnut and bar charts
- **Service Breakdown** - Individual service scores
- **Findings Summary** - Categorized security findings
- **Remediation Roadmap** - Phased improvement plan
- **Responsive Design** - Works on all devices

## 🔗 Integration with PowerReview

This dashboard showcases PowerReview capabilities. To run actual assessments:

1. Clone the full PowerReview repository
2. Run PowerShell scripts on Windows
3. Export results to JSON
4. (Future) API integration for live data

## 📝 Customization

Edit `pages/index.tsx` to:
- Update demo data
- Add your branding
- Modify color schemes
- Add new features

## 🌐 Environment Variables

No environment variables needed for the demo. For production:

```env
NEXT_PUBLIC_API_URL=your-api-url
NEXT_PUBLIC_ANALYTICS_ID=your-analytics-id
```

## 📱 Preview

The dashboard includes:
- Overview tab with security score
- Findings distribution chart
- Service-by-service breakdown
- Remediation roadmap timeline

Perfect for showcasing PowerReview to stakeholders!
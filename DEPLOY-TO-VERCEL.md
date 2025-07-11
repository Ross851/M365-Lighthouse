# 🚀 Deploy PowerReview Dashboard to Vercel (FREE)

## Quick Deploy Steps

### 1️⃣ Prepare the Web Dashboard

The web dashboard is ready in the `web` folder with:
- ✅ Next.js React app
- ✅ Interactive demo dashboard
- ✅ Charts and visualizations
- ✅ Responsive design
- ✅ Vercel configuration

### 2️⃣ Deploy Options

## Option A: Deploy via Vercel CLI (Fastest)

```bash
# Install Vercel CLI globally
npm install -g vercel

# Navigate to web directory
cd C:\SharePointScripts\Lighthouse\web

# Install dependencies
npm install

# Deploy to Vercel
vercel

# Answer the prompts:
# - Set up and deploy? Y
# - Which scope? (select your account)
# - Link to existing project? N
# - Project name? powerreview-m365
# - Directory? ./ (current directory)
# - Override settings? N
```

Your site will be live at: `https://powerreview-m365.vercel.app`

## Option B: Deploy via GitHub (Recommended)

1. **Push to GitHub:**
```bash
cd C:\SharePointScripts\Lighthouse
git add web/
git commit -m "Add web dashboard for Vercel deployment"
git push origin main
```

2. **Connect to Vercel:**
- Go to [vercel.com](https://vercel.com)
- Sign up/Login (FREE)
- Click "Add New Project"
- Import from GitHub
- Select `Ross851/M365-Lighthouse`
- **IMPORTANT**: Set root directory to `web`
- Click Deploy

## Option C: Direct Upload

1. Go to [vercel.com](https://vercel.com)
2. Click "Add New Project"
3. Click "Continue with CLI/Third Party"
4. Drag and drop the `web` folder
5. Deploy!

## 🎯 What You'll Get

A live web dashboard at `https://your-project.vercel.app` showing:

- **Interactive Demo** - Click "Live Demo" to see assessment results
- **Security Score** - Visual representation with charts
- **Findings Summary** - Categorized security issues
- **Service Breakdown** - Individual service assessments
- **Remediation Roadmap** - Phased improvement plan

## 🔧 Post-Deployment

### Custom Domain (Optional)
1. In Vercel dashboard → Settings → Domains
2. Add your custom domain
3. Follow DNS instructions

### Environment Variables (Future API)
```
NEXT_PUBLIC_API_URL=https://your-api.com
NEXT_PUBLIC_TENANT_ID=your-tenant-id
```

### Update Demo Data
Edit `web/pages/index.tsx` to customize:
- Company name
- Demo scores
- Findings data
- Service names

## 📱 Share Your Dashboard

Once deployed, share the URL with:
- Stakeholders for demos
- Potential clients
- Team members
- Include in proposals

## 🎨 Customization

The dashboard is built with:
- **Next.js** - React framework
- **Tailwind CSS** - Styling
- **Chart.js** - Data visualization
- **TypeScript** - Type safety

To customize:
1. Edit `web/pages/index.tsx`
2. Update colors in Tailwind config
3. Add new pages in `pages/` directory
4. Commit and push (auto-deploys)

## 🚨 Important Notes

- The web dashboard is a **demo visualization**
- Actual assessments run via PowerShell scripts
- No real M365 data is exposed
- Perfect for showcasing capabilities

## 🔗 Quick Links

- Your GitHub: https://github.com/Ross851/M365-Lighthouse
- Vercel Dashboard: https://vercel.com/dashboard
- Next.js Docs: https://nextjs.org/docs

---

**Ready to deploy? The web dashboard showcases PowerReview's capabilities beautifully!**
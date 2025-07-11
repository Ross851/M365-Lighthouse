# PowerReview UI

Modern web interface for PowerReview M365 Security Suite built with Astro.

## Features

- 🚀 Lightning-fast static site generation with Astro
- 🎨 Beautiful, modern UI with gradient accents
- 📱 Fully responsive design
- 🧙‍♂️ Interactive assessment wizard
- 📊 Real-time progress tracking
- 🔒 Security-focused interface

## Getting Started

1. Navigate to the UI directory:
```bash
cd powerreview-ui
```

2. Install dependencies:
```bash
npm install
```

3. Start development server:
```bash
npm run dev
```

4. Build for production:
```bash
npm run build
```

5. Preview production build:
```bash
npm run preview
```

## Pages

- **Home** (`/`) - Landing page with feature overview
- **Assessment** (`/assessment`) - Interactive security assessment wizard
- **Reports** (`/reports`) - View and manage assessment reports
- **Documentation** (`/documentation`) - User guides and API docs
- **Settings** (`/settings`) - Configure assessment parameters

## Integration with PowerShell

The UI can trigger PowerShell scripts through a backend API (to be implemented). The assessment wizard collects parameters that will be passed to the PowerReview PowerShell scripts.

## Deployment

The UI can be deployed to any static hosting service:

- GitHub Pages
- Netlify
- Vercel
- Azure Static Web Apps

## Tech Stack

- [Astro](https://astro.build) - Static site generator
- Pure CSS with CSS custom properties
- Vanilla JavaScript for interactivity
- SVG icons for crisp graphics

## Future Enhancements

- [ ] Backend API integration
- [ ] Real-time assessment progress via WebSockets
- [ ] Report visualization with charts
- [ ] Export to multiple formats (PDF, Excel, Word)
- [ ] Multi-tenant support
- [ ] User authentication
- [ ] Assessment scheduling
- [ ] Historical comparison
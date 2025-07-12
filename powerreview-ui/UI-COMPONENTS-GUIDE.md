# PowerReview UI Components & Frontend Architecture Guide

## 🎨 Frontend Architecture Overview

PowerReview's frontend is built with Astro.js, leveraging server-side rendering (SSR) for optimal performance and SEO while providing rich interactive experiences through progressive enhancement.

## 🏗️ Architecture Principles

### **Performance-First Design**
- **Server-Side Rendering (SSR)** - Fast initial page loads
- **Progressive Enhancement** - JavaScript added only where needed
- **Component Islands** - Isolated interactive components
- **Optimized Assets** - Automatic code splitting and optimization

### **User Experience Focus**
- **Responsive Design** - Mobile-first approach
- **Accessibility** - WCAG 2.1 AA compliance
- **Interactive Visualizations** - Real-time data presentation
- **Professional Aesthetics** - Enterprise-ready design system

## 📁 Component Structure

```
src/
├── 🎨 LAYOUTS/
│   └── Layout.astro                 # Base page layout
├── 🧩 COMPONENTS/
│   └── CodeBlock.astro             # Syntax-highlighted code display
├── 📄 PAGES/
│   ├── assessment/                 # Assessment workflow
│   ├── dashboards/                # Interactive dashboards
│   ├── reports/                   # Report generation
│   └── api/                       # API endpoints
├── 🎯 STATIC ASSETS/
│   └── public/                    # Images, fonts, static files
└── 📊 DATA/
    └── src/data/                  # Static data and configurations
```

## 🎛️ Core UI Components

### **1. Base Layout Component**
```astro
---
// src/layouts/Layout.astro
export interface Props {
    title: string;
    description?: string;
    canonical?: string;
}

const { title, description, canonical } = Astro.props;
---

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>{title} - PowerReview</title>
    <meta name="description" content={description || "Enterprise security assessment platform"} />
    {canonical && <link rel="canonical" href={canonical} />}
    
    <!-- Performance optimizations -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="dns-prefetch" href="//api.powerreview.com">
    
    <!-- PWA manifest -->
    <link rel="manifest" href="/manifest.json">
    
    <!-- Security headers -->
    <meta http-equiv="Content-Security-Policy" content="default-src 'self'; script-src 'self' 'unsafe-inline';">
</head>

<body>
    <!-- Navigation component -->
    <nav class="main-navigation">
        <div class="nav-container">
            <div class="nav-brand">
                <img src="/logo.svg" alt="PowerReview" width="120" height="40" />
            </div>
            <div class="nav-links">
                <a href="/dashboard" class="nav-link">Dashboard</a>
                <a href="/assessments" class="nav-link">Assessments</a>
                <a href="/reports" class="nav-link">Reports</a>
                <a href="/compliance" class="nav-link">Compliance</a>
            </div>
        </div>
    </nav>
    
    <!-- Main content -->
    <main class="main-content">
        <slot />
    </main>
    
    <!-- Footer -->
    <footer class="main-footer">
        <div class="footer-content">
            <p>&copy; 2024 PowerReview. Enterprise Security Assessment Platform.</p>
        </div>
    </footer>
</body>
</html>
```

### **2. Interactive Dashboard Components**

#### **A. Security Score Gauge**
```astro
---
// Component: SecurityScoreGauge.astro
export interface Props {
    score: number;
    previousScore?: number;
    size?: 'small' | 'medium' | 'large';
}

const { score, previousScore, size = 'medium' } = Astro.props;
const circumference = 2 * Math.PI * 90;
const offset = circumference - (score / 100) * circumference;
---

<div class={`security-gauge ${size}`}>
    <svg viewBox="0 0 200 200" class="gauge-svg">
        <!-- Background circle -->
        <circle
            cx="100"
            cy="100"
            r="90"
            fill="none"
            stroke="#e5e7eb"
            stroke-width="20"
        />
        
        <!-- Progress circle -->
        <circle
            cx="100"
            cy="100"
            r="90"
            fill="none"
            stroke={score >= 80 ? "#10b981" : score >= 60 ? "#f59e0b" : "#ef4444"}
            stroke-width="20"
            stroke-dasharray={circumference}
            stroke-dashoffset={offset}
            stroke-linecap="round"
            transform="rotate(-90 100 100)"
            class="gauge-progress"
        />
        
        <!-- Score text -->
        <text x="100" y="100" text-anchor="middle" dy="0.3em" class="gauge-text">
            {score}%
        </text>
    </svg>
    
    {previousScore && (
        <div class="score-comparison">
            <span class={`trend ${score > previousScore ? 'up' : 'down'}`}>
                {score > previousScore ? '↗' : '↘'} 
                {Math.abs(score - previousScore)}%
            </span>
        </div>
    )}
</div>

<style>
    .security-gauge {
        display: inline-block;
        position: relative;
    }
    
    .security-gauge.small { width: 120px; height: 120px; }
    .security-gauge.medium { width: 200px; height: 200px; }
    .security-gauge.large { width: 300px; height: 300px; }
    
    .gauge-svg {
        width: 100%;
        height: 100%;
    }
    
    .gauge-progress {
        transition: stroke-dashoffset 2s ease-in-out;
    }
    
    .gauge-text {
        font-size: 2rem;
        font-weight: 700;
        fill: #1e293b;
    }
    
    .score-comparison {
        position: absolute;
        bottom: 10px;
        left: 50%;
        transform: translateX(-50%);
        font-size: 0.875rem;
        font-weight: 600;
    }
    
    .trend.up { color: #10b981; }
    .trend.down { color: #ef4444; }
</style>
```

#### **B. Real-Time Activity Feed**
```astro
---
// Component: ActivityFeed.astro
export interface Props {
    maxItems?: number;
    refreshInterval?: number;
}

const { maxItems = 10, refreshInterval = 5000 } = Astro.props;
---

<div class="activity-feed" data-max-items={maxItems} data-refresh={refreshInterval}>
    <div class="feed-header">
        <h3>Live Security Activity</h3>
        <div class="feed-controls">
            <button class="feed-toggle" aria-label="Pause feed">⏸️</button>
            <button class="feed-clear" aria-label="Clear feed">🗑️</button>
        </div>
    </div>
    
    <div class="feed-container" id="activityFeedContainer">
        <!-- Activity items populated by JavaScript -->
    </div>
</div>

<script>
class ActivityFeed {
    constructor(container, options = {}) {
        this.container = container;
        this.maxItems = options.maxItems || 10;
        this.refreshInterval = options.refreshInterval || 5000;
        this.isPaused = false;
        this.items = [];
        
        this.setupEventListeners();
        this.startFeed();
    }
    
    setupEventListeners() {
        const toggleBtn = this.container.querySelector('.feed-toggle');
        const clearBtn = this.container.querySelector('.feed-clear');
        
        toggleBtn?.addEventListener('click', () => this.toggleFeed());
        clearBtn?.addEventListener('click', () => this.clearFeed());
    }
    
    addActivity(activity) {
        if (this.isPaused) return;
        
        const item = this.createActivityItem(activity);
        const feedContainer = this.container.querySelector('#activityFeedContainer');
        
        // Add new item at top
        feedContainer.insertBefore(item, feedContainer.firstChild);
        
        // Remove excess items
        while (feedContainer.children.length > this.maxItems) {
            feedContainer.removeChild(feedContainer.lastChild);
        }
        
        // Animate new item
        item.style.opacity = '0';
        item.style.transform = 'translateX(-20px)';
        
        requestAnimationFrame(() => {
            item.style.transition = 'all 0.3s ease';
            item.style.opacity = '1';
            item.style.transform = 'translateX(0)';
        });
    }
    
    createActivityItem(activity) {
        const item = document.createElement('div');
        item.className = `activity-item ${activity.type}`;
        
        const timestamp = new Date().toLocaleTimeString();
        
        item.innerHTML = `
            <div class="activity-icon">${this.getActivityIcon(activity.type)}</div>
            <div class="activity-content">
                <div class="activity-message">${activity.message}</div>
                <div class="activity-time">${timestamp}</div>
            </div>
        `;
        
        return item;
    }
    
    getActivityIcon(type) {
        const icons = {
            'security': '🛡️',
            'warning': '⚠️',
            'error': '🚨',
            'success': '✅',
            'info': 'ℹ️'
        };
        return icons[type] || '📋';
    }
    
    startFeed() {
        // Simulate real-time activities
        this.feedInterval = setInterval(() => {
            if (!this.isPaused) {
                this.simulateActivity();
            }
        }, this.refreshInterval);
    }
    
    simulateActivity() {
        const activities = [
            { type: 'security', message: 'MFA enabled for user@company.com' },
            { type: 'warning', message: 'Suspicious login attempt detected' },
            { type: 'success', message: 'Vulnerability patch applied successfully' },
            { type: 'info', message: 'Security scan completed' },
            { type: 'error', message: 'Critical security policy violation' }
        ];
        
        const randomActivity = activities[Math.floor(Math.random() * activities.length)];
        this.addActivity(randomActivity);
    }
    
    toggleFeed() {
        this.isPaused = !this.isPaused;
        const toggleBtn = this.container.querySelector('.feed-toggle');
        toggleBtn.textContent = this.isPaused ? '▶️' : '⏸️';
    }
    
    clearFeed() {
        const feedContainer = this.container.querySelector('#activityFeedContainer');
        feedContainer.innerHTML = '';
    }
}

// Initialize activity feed on page load
document.addEventListener('DOMContentLoaded', () => {
    const feedElements = document.querySelectorAll('.activity-feed');
    feedElements.forEach(element => {
        const maxItems = parseInt(element.dataset.maxItems) || 10;
        const refreshInterval = parseInt(element.dataset.refresh) || 5000;
        
        new ActivityFeed(element, { maxItems, refreshInterval });
    });
});
</script>

<style>
    .activity-feed {
        background: white;
        border-radius: 12px;
        padding: 1.5rem;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
        max-width: 400px;
    }
    
    .feed-header {
        display: flex;
        justify-content: space-between;
        align-items: center;
        margin-bottom: 1rem;
        padding-bottom: 1rem;
        border-bottom: 1px solid #e5e7eb;
    }
    
    .feed-header h3 {
        margin: 0;
        font-size: 1.125rem;
        color: #1e293b;
    }
    
    .feed-controls {
        display: flex;
        gap: 0.5rem;
    }
    
    .feed-controls button {
        background: none;
        border: none;
        cursor: pointer;
        padding: 0.25rem;
        border-radius: 4px;
        transition: background-color 0.2s;
    }
    
    .feed-controls button:hover {
        background: #f3f4f6;
    }
    
    .feed-container {
        max-height: 300px;
        overflow-y: auto;
    }
    
    .activity-item {
        display: flex;
        align-items: flex-start;
        gap: 0.75rem;
        padding: 0.75rem 0;
        border-bottom: 1px solid #f3f4f6;
    }
    
    .activity-item:last-child {
        border-bottom: none;
    }
    
    .activity-icon {
        font-size: 1.25rem;
        flex-shrink: 0;
    }
    
    .activity-content {
        flex: 1;
        min-width: 0;
    }
    
    .activity-message {
        font-size: 0.875rem;
        color: #374151;
        line-height: 1.4;
    }
    
    .activity-time {
        font-size: 0.75rem;
        color: #9ca3af;
        margin-top: 0.25rem;
    }
    
    .activity-item.security { border-left: 3px solid #10b981; }
    .activity-item.warning { border-left: 3px solid #f59e0b; }
    .activity-item.error { border-left: 3px solid #ef4444; }
    .activity-item.success { border-left: 3px solid #10b981; }
    .activity-item.info { border-left: 3px solid #6366f1; }
</style>
```

### **3. Data Visualization Components**

#### **A. Interactive Risk Matrix**
```astro
---
// Component: RiskMatrix.astro
export interface Props {
    risks: Array<{
        name: string;
        probability: number; // 1-5
        impact: number; // 1-5
        category: string;
    }>;
}

const { risks } = Astro.props;
---

<div class="risk-matrix-container">
    <h3>Risk Assessment Matrix</h3>
    
    <div class="risk-matrix">
        <!-- Y-axis labels -->
        <div class="matrix-labels-y">
            <span>Very High</span>
            <span>High</span>
            <span>Medium</span>
            <span>Low</span>
            <span>Very Low</span>
        </div>
        
        <!-- Matrix grid -->
        <div class="matrix-grid" id="riskMatrixGrid">
            {Array.from({ length: 25 }, (_, index) => {
                const row = Math.floor(index / 5) + 1;
                const col = (index % 5) + 1;
                const riskLevel = this.calculateRiskLevel(row, col);
                
                return (
                    <div 
                        class={`matrix-cell ${riskLevel}`}
                        data-row={row}
                        data-col={col}
                    ></div>
                );
            })}
        </div>
        
        <!-- X-axis labels -->
        <div class="matrix-labels-x">
            <span>Very Low</span>
            <span>Low</span>
            <span>Medium</span>
            <span>High</span>
            <span>Very High</span>
        </div>
    </div>
    
    <!-- Risk legend -->
    <div class="risk-legend">
        <div class="legend-item critical">
            <span class="legend-color"></span>
            <span>Critical Risk</span>
        </div>
        <div class="legend-item high">
            <span class="legend-color"></span>
            <span>High Risk</span>
        </div>
        <div class="legend-item medium">
            <span class="legend-color"></span>
            <span>Medium Risk</span>
        </div>
        <div class="legend-item low">
            <span class="legend-color"></span>
            <span>Low Risk</span>
        </div>
    </div>
</div>

<script define:vars={{ risks }}>
class RiskMatrix {
    constructor(risks) {
        this.risks = risks;
        this.initializeMatrix();
    }
    
    calculateRiskLevel(probability, impact) {
        const score = probability * impact;
        if (score >= 20) return 'critical';
        if (score >= 15) return 'high';
        if (score >= 10) return 'medium';
        return 'low';
    }
    
    initializeMatrix() {
        const grid = document.getElementById('riskMatrixGrid');
        
        // Place risks on matrix
        this.risks.forEach(risk => {
            const cell = grid.querySelector(
                `[data-row="${risk.probability}"][data-col="${risk.impact}"]`
            );
            
            if (cell) {
                this.addRiskToCell(cell, risk);
            }
        });
        
        // Add hover effects
        grid.addEventListener('mouseover', this.handleCellHover.bind(this));
        grid.addEventListener('mouseout', this.handleCellLeave.bind(this));
    }
    
    addRiskToCell(cell, risk) {
        const riskDot = document.createElement('div');
        riskDot.className = 'risk-dot';
        riskDot.title = `${risk.name} (${risk.category})`;
        riskDot.textContent = risk.name.charAt(0).toUpperCase();
        
        cell.appendChild(riskDot);
    }
    
    handleCellHover(event) {
        if (event.target.classList.contains('matrix-cell')) {
            const row = event.target.dataset.row;
            const col = event.target.dataset.col;
            
            // Show tooltip with risk details
            this.showTooltip(event.target, row, col);
        }
    }
    
    handleCellLeave(event) {
        this.hideTooltip();
    }
    
    showTooltip(cell, probability, impact) {
        const tooltip = document.createElement('div');
        tooltip.className = 'risk-tooltip';
        tooltip.innerHTML = `
            <strong>Risk Level: ${this.calculateRiskLevel(probability, impact).toUpperCase()}</strong><br>
            Probability: ${probability}/5<br>
            Impact: ${impact}/5
        `;
        
        document.body.appendChild(tooltip);
        
        const rect = cell.getBoundingClientRect();
        tooltip.style.left = rect.left + 'px';
        tooltip.style.top = (rect.top - tooltip.offsetHeight - 10) + 'px';
    }
    
    hideTooltip() {
        const tooltip = document.querySelector('.risk-tooltip');
        if (tooltip) {
            tooltip.remove();
        }
    }
}

// Initialize risk matrix
document.addEventListener('DOMContentLoaded', () => {
    new RiskMatrix(risks);
});
</script>

<style>
    .risk-matrix-container {
        background: white;
        padding: 2rem;
        border-radius: 12px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.08);
    }
    
    .risk-matrix-container h3 {
        margin: 0 0 2rem 0;
        font-size: 1.5rem;
        color: #1e293b;
        text-align: center;
    }
    
    .risk-matrix {
        display: grid;
        grid-template-columns: auto 1fr;
        grid-template-rows: 1fr auto;
        gap: 1rem;
        margin-bottom: 2rem;
    }
    
    .matrix-labels-y {
        display: flex;
        flex-direction: column-reverse;
        justify-content: space-around;
        align-items: flex-end;
        padding-right: 1rem;
        font-size: 0.875rem;
        color: #64748b;
    }
    
    .matrix-grid {
        display: grid;
        grid-template-columns: repeat(5, 1fr);
        grid-template-rows: repeat(5, 1fr);
        gap: 2px;
        height: 300px;
    }
    
    .matrix-cell {
        position: relative;
        border-radius: 4px;
        cursor: pointer;
        transition: all 0.2s;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-wrap: wrap;
        gap: 2px;
        padding: 2px;
    }
    
    .matrix-cell:hover {
        transform: scale(1.05);
        z-index: 10;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    }
    
    .matrix-cell.critical { background: #dc2626; }
    .matrix-cell.high { background: #ea580c; }
    .matrix-cell.medium { background: #ca8a04; }
    .matrix-cell.low { background: #65a30d; }
    
    .matrix-labels-x {
        grid-column: 2;
        display: flex;
        justify-content: space-around;
        align-items: center;
        font-size: 0.875rem;
        color: #64748b;
        padding-top: 1rem;
    }
    
    .risk-dot {
        width: 20px;
        height: 20px;
        border-radius: 50%;
        background: rgba(255, 255, 255, 0.9);
        color: #1e293b;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 0.75rem;
        font-weight: 700;
        cursor: pointer;
        transition: all 0.2s;
    }
    
    .risk-dot:hover {
        transform: scale(1.2);
        background: white;
    }
    
    .risk-legend {
        display: flex;
        justify-content: center;
        gap: 2rem;
        flex-wrap: wrap;
    }
    
    .legend-item {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        font-size: 0.875rem;
        color: #64748b;
    }
    
    .legend-color {
        width: 16px;
        height: 16px;
        border-radius: 4px;
    }
    
    .legend-item.critical .legend-color { background: #dc2626; }
    .legend-item.high .legend-color { background: #ea580c; }
    .legend-item.medium .legend-color { background: #ca8a04; }
    .legend-item.low .legend-color { background: #65a30d; }
    
    .risk-tooltip {
        position: absolute;
        background: #1e293b;
        color: white;
        padding: 0.75rem;
        border-radius: 6px;
        font-size: 0.875rem;
        z-index: 1000;
        pointer-events: none;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
    }
    
    .risk-tooltip::after {
        content: '';
        position: absolute;
        top: 100%;
        left: 50%;
        transform: translateX(-50%);
        border: 5px solid transparent;
        border-top-color: #1e293b;
    }
</style>
```

## 🎯 Design System

### **Color Palette**
```css
:root {
    /* Primary Colors */
    --color-primary: #6366f1;
    --color-primary-dark: #4f46e5;
    --color-primary-light: #a5b4fc;
    
    /* Semantic Colors */
    --color-success: #10b981;
    --color-warning: #f59e0b;
    --color-error: #ef4444;
    --color-info: #3b82f6;
    
    /* Neutral Colors */
    --color-dark: #1e293b;
    --color-gray: #64748b;
    --color-light-gray: #94a3b8;
    --color-border: #e2e8f0;
    --color-background: #f8fafc;
    
    /* Gradients */
    --gradient-primary: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    --gradient-success: linear-gradient(135deg, #10b981 0%, #059669 100%);
    --gradient-warning: linear-gradient(135deg, #f59e0b 0%, #d97706 100%);
}
```

### **Typography Scale**
```css
/* Typography System */
:root {
    --font-family-sans: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    --font-family-mono: 'SF Mono', 'Monaco', 'Cascadia Code', monospace;
    
    /* Font Sizes */
    --text-xs: 0.75rem;      /* 12px */
    --text-sm: 0.875rem;     /* 14px */
    --text-base: 1rem;       /* 16px */
    --text-lg: 1.125rem;     /* 18px */
    --text-xl: 1.25rem;      /* 20px */
    --text-2xl: 1.5rem;      /* 24px */
    --text-3xl: 1.875rem;    /* 30px */
    --text-4xl: 2.25rem;     /* 36px */
    
    /* Font Weights */
    --font-normal: 400;
    --font-medium: 500;
    --font-semibold: 600;
    --font-bold: 700;
    --font-extrabold: 800;
}

/* Typography Classes */
.text-xs { font-size: var(--text-xs); }
.text-sm { font-size: var(--text-sm); }
.text-base { font-size: var(--text-base); }
.text-lg { font-size: var(--text-lg); }
.text-xl { font-size: var(--text-xl); }
.text-2xl { font-size: var(--text-2xl); }
.text-3xl { font-size: var(--text-3xl); }
.text-4xl { font-size: var(--text-4xl); }

.font-normal { font-weight: var(--font-normal); }
.font-medium { font-weight: var(--font-medium); }
.font-semibold { font-weight: var(--font-semibold); }
.font-bold { font-weight: var(--font-bold); }
.font-extrabold { font-weight: var(--font-extrabold); }
```

### **Spacing System**
```css
:root {
    /* Spacing Scale */
    --space-1: 0.25rem;   /* 4px */
    --space-2: 0.5rem;    /* 8px */
    --space-3: 0.75rem;   /* 12px */
    --space-4: 1rem;      /* 16px */
    --space-5: 1.25rem;   /* 20px */
    --space-6: 1.5rem;    /* 24px */
    --space-8: 2rem;      /* 32px */
    --space-10: 2.5rem;   /* 40px */
    --space-12: 3rem;     /* 48px */
    --space-16: 4rem;     /* 64px */
    --space-20: 5rem;     /* 80px */
}

/* Spacing Utilities */
.p-1 { padding: var(--space-1); }
.p-2 { padding: var(--space-2); }
.p-4 { padding: var(--space-4); }
.p-6 { padding: var(--space-6); }
.p-8 { padding: var(--space-8); }

.m-1 { margin: var(--space-1); }
.m-2 { margin: var(--space-2); }
.m-4 { margin: var(--space-4); }
.m-6 { margin: var(--space-6); }
.m-8 { margin: var(--space-8); }
```

## 📱 Responsive Design

### **Breakpoint System**
```css
:root {
    /* Breakpoints */
    --breakpoint-sm: 640px;   /* Small tablets */
    --breakpoint-md: 768px;   /* Large tablets */
    --breakpoint-lg: 1024px;  /* Small desktops */
    --breakpoint-xl: 1280px;  /* Large desktops */
    --breakpoint-2xl: 1536px; /* Extra large screens */
}

/* Responsive Utilities */
@media (max-width: 640px) {
    .sm\:hidden { display: none; }
    .sm\:block { display: block; }
    .sm\:flex { display: flex; }
    .sm\:grid { display: grid; }
}

@media (max-width: 768px) {
    .md\:hidden { display: none; }
    .md\:block { display: block; }
    .md\:flex { display: flex; }
    .md\:grid { display: grid; }
}

@media (max-width: 1024px) {
    .lg\:hidden { display: none; }
    .lg\:block { display: block; }
    .lg\:flex { display: flex; }
    .lg\:grid { display: grid; }
}
```

### **Mobile-First Approach**
```css
/* Mobile-first responsive design example */
.dashboard-grid {
    display: grid;
    grid-template-columns: 1fr;
    gap: 1rem;
    padding: 1rem;
}

@media (min-width: 768px) {
    .dashboard-grid {
        grid-template-columns: repeat(2, 1fr);
        gap: 2rem;
        padding: 2rem;
    }
}

@media (min-width: 1024px) {
    .dashboard-grid {
        grid-template-columns: repeat(3, 1fr);
        gap: 2rem;
    }
}

@media (min-width: 1280px) {
    .dashboard-grid {
        grid-template-columns: repeat(4, 1fr);
        gap: 3rem;
    }
}
```

## ♿ Accessibility Features

### **ARIA Implementation**
```astro
<!-- Accessible dashboard card example -->
<div 
    class="dashboard-card"
    role="region"
    aria-labelledby="security-score-title"
    aria-describedby="security-score-desc"
>
    <h3 id="security-score-title">Security Score</h3>
    <div 
        id="security-score-desc"
        class="sr-only"
    >
        Current security score is 78 out of 100, showing an improvement from last month
    </div>
    
    <!-- Interactive elements with proper ARIA -->
    <button 
        aria-label="View detailed security score breakdown"
        aria-expanded="false"
        aria-controls="score-details"
        class="score-toggle"
    >
        View Details
    </button>
    
    <div 
        id="score-details"
        class="score-details"
        aria-hidden="true"
    >
        <!-- Detailed breakdown content -->
    </div>
</div>
```

### **Keyboard Navigation**
```css
/* Focus styles for keyboard navigation */
:focus-visible {
    outline: 2px solid var(--color-primary);
    outline-offset: 2px;
    border-radius: 4px;
}

/* Skip links for screen readers */
.skip-link {
    position: absolute;
    top: -40px;
    left: 6px;
    background: var(--color-dark);
    color: white;
    padding: 8px;
    text-decoration: none;
    border-radius: 4px;
    z-index: 1000;
    transition: top 0.3s;
}

.skip-link:focus {
    top: 6px;
}

/* Screen reader only content */
.sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
}
```

## 🔧 Performance Optimization

### **Image Optimization**
```astro
---
// Optimized image component
export interface Props {
    src: string;
    alt: string;
    width?: number;
    height?: number;
    loading?: 'lazy' | 'eager';
    sizes?: string;
}

const { 
    src, 
    alt, 
    width, 
    height, 
    loading = 'lazy',
    sizes = '(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw'
} = Astro.props;
---

<picture>
    <!-- WebP format for modern browsers -->
    <source 
        srcset={`${src}?format=webp&w=320 320w, ${src}?format=webp&w=640 640w, ${src}?format=webp&w=1280 1280w`}
        sizes={sizes}
        type="image/webp"
    />
    
    <!-- Fallback for older browsers -->
    <img 
        src={src}
        alt={alt}
        width={width}
        height={height}
        loading={loading}
        sizes={sizes}
        srcset={`${src}?w=320 320w, ${src}?w=640 640w, ${src}?w=1280 1280w`}
        class="optimized-image"
    />
</picture>

<style>
    .optimized-image {
        max-width: 100%;
        height: auto;
        transition: opacity 0.3s;
    }
    
    .optimized-image[loading="lazy"] {
        opacity: 0;
    }
    
    .optimized-image.loaded {
        opacity: 1;
    }
</style>

<script>
    // Add loading effect for lazy images
    document.addEventListener('DOMContentLoaded', () => {
        const lazyImages = document.querySelectorAll('img[loading="lazy"]');
        
        lazyImages.forEach(img => {
            img.addEventListener('load', () => {
                img.classList.add('loaded');
            });
        });
    });
</script>
```

### **Code Splitting Strategy**
```javascript
// Dynamic imports for heavy components
// Located in: src/lib/dynamic-imports.ts

export class ComponentLoader {
    static async loadChart() {
        const { ChartComponent } = await import('./chart-component.js');
        return ChartComponent;
    }
    
    static async loadDataTable() {
        const { DataTable } = await import('./data-table.js');
        return DataTable;
    }
    
    static async loadThreatMap() {
        const { ThreatMap } = await import('./threat-map.js');
        return ThreatMap;
    }
}

// Usage in components
document.addEventListener('DOMContentLoaded', async () => {
    // Load chart only when needed
    const chartContainer = document.getElementById('chart-container');
    if (chartContainer) {
        const ChartComponent = await ComponentLoader.loadChart();
        new ChartComponent(chartContainer);
    }
});
```

## 🧪 Testing Strategy

### **Component Testing**
```javascript
// Test example for SecurityScoreGauge component
// tests/components/SecurityScoreGauge.test.js

import { test, expect } from '@playwright/test';

test.describe('SecurityScoreGauge', () => {
    test('renders score correctly', async ({ page }) => {
        await page.goto('/test-components/security-score-gauge');
        
        // Test score display
        const scoreText = await page.locator('.gauge-text').textContent();
        expect(scoreText).toBe('78%');
        
        // Test color based on score
        const progressCircle = page.locator('.gauge-progress');
        const strokeColor = await progressCircle.getAttribute('stroke');
        expect(strokeColor).toBe('#f59e0b'); // Orange for 78%
    });
    
    test('shows trend comparison', async ({ page }) => {
        await page.goto('/test-components/security-score-gauge?previous=65');
        
        const trendElement = page.locator('.trend');
        await expect(trendElement).toHaveClass(/up/);
        await expect(trendElement).toContainText('↗ 13%');
    });
    
    test('handles keyboard navigation', async ({ page }) => {
        await page.goto('/test-components/security-score-gauge');
        
        // Test keyboard focus
        await page.keyboard.press('Tab');
        await expect(page.locator('.security-gauge')).toBeFocused();
    });
});
```

## 📁 File Organization

```
src/
├── 🎨 COMPONENTS/
│   ├── base/                       # Basic UI components
│   │   ├── Button.astro
│   │   ├── Input.astro
│   │   └── Modal.astro
│   ├── charts/                     # Data visualization
│   │   ├── SecurityScoreGauge.astro
│   │   ├── RiskMatrix.astro
│   │   └── TrendChart.astro
│   ├── dashboard/                  # Dashboard widgets
│   │   ├── ActivityFeed.astro
│   │   ├── ComplianceCard.astro
│   │   └── MetricsGrid.astro
│   └── forms/                      # Form components
│       ├── AssessmentForm.astro
│       └── FilterForm.astro
├── 📄 PAGES/
│   ├── dashboards/                 # Dashboard pages
│   ├── assessments/                # Assessment workflows
│   ├── reports/                    # Report generation
│   └── api/                        # API endpoints
├── 🎯 LAYOUTS/
│   ├── Layout.astro               # Base layout
│   ├── DashboardLayout.astro      # Dashboard-specific
│   └── ReportLayout.astro         # Report-specific
├── 📊 STYLES/
│   ├── globals.css                # Global styles
│   ├── components.css             # Component styles
│   └── utilities.css              # Utility classes
└── 🔧 SCRIPTS/
    ├── chart-helpers.js           # Chart utilities
    ├── data-formatters.js         # Data formatting
    └── keyboard-navigation.js     # Accessibility helpers
```

---

**Last Updated**: July 2024  
**Framework**: Astro.js 4.0+  
**Design System**: Custom Enterprise Design System  
**Accessibility**: WCAG 2.1 AA Compliant
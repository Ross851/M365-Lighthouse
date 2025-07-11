import React, { useState } from 'react';
import Head from 'next/head';
import { Chart as ChartJS, ArcElement, Tooltip, Legend, CategoryScale, LinearScale, BarElement } from 'chart.js';
import { Doughnut, Bar } from 'react-chartjs-2';

ChartJS.register(ArcElement, Tooltip, Legend, CategoryScale, LinearScale, BarElement);

export default function PowerReviewDashboard() {
  const [activeTab, setActiveTab] = useState('overview');
  const [showDemo, setShowDemo] = useState(false);

  const securityScore = 72;
  const findings = {
    critical: 12,
    high: 47,
    medium: 123,
    low: 234
  };

  const scoreData = {
    labels: ['Secure', 'At Risk'],
    datasets: [{
      data: [securityScore, 100 - securityScore],
      backgroundColor: ['#10b981', '#ef4444'],
      borderWidth: 0
    }]
  };

  const findingsData = {
    labels: ['Critical', 'High', 'Medium', 'Low'],
    datasets: [{
      label: 'Findings by Severity',
      data: [findings.critical, findings.high, findings.medium, findings.low],
      backgroundColor: ['#dc2626', '#f97316', '#eab308', '#22c55e']
    }]
  };

  const services = [
    { name: 'Microsoft Purview', score: 65, status: 'Needs Improvement', color: '#f97316' },
    { name: 'SharePoint Online', score: 78, status: 'Fair', color: '#eab308' },
    { name: 'Microsoft Teams', score: 82, status: 'Good', color: '#22c55e' },
    { name: 'Power Platform', score: 45, status: 'Critical', color: '#dc2626' },
    { name: 'Azure Security', score: 71, status: 'Fair', color: '#eab308' }
  ];

  return (
    <>
      <Head>
        <title>PowerReview - M365 Security Assessment Dashboard</title>
        <meta name="description" content="Enterprise Microsoft 365 & Azure Security Assessment Framework" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet" />
      </Head>

      <div className="min-h-screen bg-gray-50">
        {/* Header */}
        <header className="bg-white shadow-sm border-b">
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div className="flex justify-between items-center py-4">
              <div className="flex items-center">
                <h1 className="text-2xl font-bold text-gray-900">🚀 PowerReview</h1>
                <span className="ml-4 text-sm text-gray-500">M365 Security Assessment Framework</span>
              </div>
              <nav className="flex space-x-4">
                <a href="https://github.com/Ross851/M365-Lighthouse" target="_blank" rel="noopener noreferrer" 
                   className="text-gray-600 hover:text-gray-900">GitHub</a>
                <button onClick={() => setShowDemo(!showDemo)} 
                        className="bg-blue-600 text-white px-4 py-2 rounded-md hover:bg-blue-700">
                  {showDemo ? 'Hide Demo' : 'Live Demo'}
                </button>
              </nav>
            </div>
          </div>
        </header>

        {/* Hero Section */}
        {!showDemo && (
          <section className="bg-gradient-to-r from-blue-600 to-indigo-700 text-white py-16">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <div className="text-center">
                <h2 className="text-4xl font-bold mb-4">Enterprise M365 Security Assessment</h2>
                <p className="text-xl mb-8">Comprehensive security analysis for Microsoft 365 and Azure environments</p>
                <div className="flex justify-center space-x-4">
                  <button onClick={() => setShowDemo(true)} 
                          className="bg-white text-blue-600 px-6 py-3 rounded-md font-semibold hover:bg-gray-100">
                    View Demo Dashboard
                  </button>
                  <a href="https://github.com/Ross851/M365-Lighthouse" 
                     className="bg-transparent border-2 border-white text-white px-6 py-3 rounded-md font-semibold hover:bg-white hover:text-blue-600">
                    Get Started
                  </a>
                </div>
              </div>
            </div>
          </section>
        )}

        {/* Demo Dashboard */}
        {showDemo && (
          <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            {/* Tabs */}
            <div className="border-b border-gray-200 mb-8">
              <nav className="-mb-px flex space-x-8">
                {['overview', 'findings', 'services', 'roadmap'].map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`py-2 px-1 border-b-2 font-medium text-sm ${
                      activeTab === tab
                        ? 'border-blue-500 text-blue-600'
                        : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                    }`}
                  >
                    {tab.charAt(0).toUpperCase() + tab.slice(1)}
                  </button>
                ))}
              </nav>
            </div>

            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Security Score */}
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-semibold mb-4">Overall Security Score</h3>
                  <div className="relative h-48">
                    <Doughnut data={scoreData} options={{ 
                      maintainAspectRatio: false,
                      plugins: { legend: { display: false } }
                    }} />
                    <div className="absolute inset-0 flex items-center justify-center">
                      <div className="text-center">
                        <div className="text-3xl font-bold">{securityScore}</div>
                        <div className="text-sm text-gray-500">out of 100</div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Findings Summary */}
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-semibold mb-4">Findings Summary</h3>
                  <div className="space-y-3">
                    <div className="flex justify-between items-center">
                      <span className="flex items-center">
                        <div className="w-3 h-3 bg-red-600 rounded-full mr-2"></div>
                        Critical
                      </span>
                      <span className="font-semibold">{findings.critical}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="flex items-center">
                        <div className="w-3 h-3 bg-orange-500 rounded-full mr-2"></div>
                        High
                      </span>
                      <span className="font-semibold">{findings.high}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="flex items-center">
                        <div className="w-3 h-3 bg-yellow-500 rounded-full mr-2"></div>
                        Medium
                      </span>
                      <span className="font-semibold">{findings.medium}</span>
                    </div>
                    <div className="flex justify-between items-center">
                      <span className="flex items-center">
                        <div className="w-3 h-3 bg-green-500 rounded-full mr-2"></div>
                        Low
                      </span>
                      <span className="font-semibold">{findings.low}</span>
                    </div>
                  </div>
                </div>

                {/* Quick Stats */}
                <div className="bg-white p-6 rounded-lg shadow">
                  <h3 className="text-lg font-semibold mb-4">Assessment Stats</h3>
                  <div className="space-y-3">
                    <div>
                      <div className="text-sm text-gray-500">Services Assessed</div>
                      <div className="text-2xl font-semibold">5</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-500">Policies Reviewed</div>
                      <div className="text-2xl font-semibold">247</div>
                    </div>
                    <div>
                      <div className="text-sm text-gray-500">Time to Complete</div>
                      <div className="text-2xl font-semibold">12m 34s</div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Findings Tab */}
            {activeTab === 'findings' && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold mb-4">Findings Distribution</h3>
                <div className="h-64">
                  <Bar data={findingsData} options={{ 
                    maintainAspectRatio: false,
                    scales: { y: { beginAtZero: true } }
                  }} />
                </div>
                <div className="mt-6 space-y-4">
                  <div className="border-l-4 border-red-600 bg-red-50 p-4">
                    <h4 className="font-semibold text-red-900">Critical: Unrestricted External Sharing</h4>
                    <p className="text-sm text-red-700 mt-1">45 SharePoint sites allow anonymous access without restrictions</p>
                  </div>
                  <div className="border-l-4 border-orange-500 bg-orange-50 p-4">
                    <h4 className="font-semibold text-orange-900">High: No DLP Policies Configured</h4>
                    <p className="text-sm text-orange-700 mt-1">Data Loss Prevention policies are not configured for sensitive information types</p>
                  </div>
                </div>
              </div>
            )}

            {/* Services Tab */}
            {activeTab === 'services' && (
              <div className="bg-white rounded-lg shadow">
                <div className="px-6 py-4 border-b">
                  <h3 className="text-lg font-semibold">Service Assessment Scores</h3>
                </div>
                <div className="divide-y">
                  {services.map((service) => (
                    <div key={service.name} className="px-6 py-4">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-medium">{service.name}</h4>
                        <span className={`px-3 py-1 rounded-full text-sm font-medium text-white`} 
                              style={{ backgroundColor: service.color }}>
                          {service.status}
                        </span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2">
                        <div className="h-2 rounded-full" 
                             style={{ width: `${service.score}%`, backgroundColor: service.color }}></div>
                      </div>
                      <div className="mt-1 text-sm text-gray-500">{service.score}/100</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Roadmap Tab */}
            {activeTab === 'roadmap' && (
              <div className="bg-white rounded-lg shadow p-6">
                <h3 className="text-lg font-semibold mb-4">Remediation Roadmap</h3>
                <div className="space-y-4">
                  {[
                    { phase: 'Immediate (0-30 days)', items: ['Enable MFA for all users', 'Block legacy authentication', 'Configure DLP policies'], effort: 'Low' },
                    { phase: 'Short-term (30-90 days)', items: ['Implement sensitivity labels', 'Configure retention policies', 'Enable audit logging'], effort: 'Medium' },
                    { phase: 'Long-term (90-180 days)', items: ['Implement Zero Trust architecture', 'Advanced threat protection', 'Compliance automation'], effort: 'High' }
                  ].map((phase) => (
                    <div key={phase.phase} className="border rounded-lg p-4">
                      <div className="flex justify-between items-center mb-2">
                        <h4 className="font-semibold">{phase.phase}</h4>
                        <span className={`text-sm px-2 py-1 rounded ${
                          phase.effort === 'Low' ? 'bg-green-100 text-green-800' :
                          phase.effort === 'Medium' ? 'bg-yellow-100 text-yellow-800' :
                          'bg-red-100 text-red-800'
                        }`}>
                          {phase.effort} Effort
                        </span>
                      </div>
                      <ul className="list-disc list-inside text-sm text-gray-600 space-y-1">
                        {phase.items.map((item) => (
                          <li key={item}>{item}</li>
                        ))}
                      </ul>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}

        {/* Features Section */}
        {!showDemo && (
          <section className="py-16">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
              <h2 className="text-3xl font-bold text-center mb-12">Key Features</h2>
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
                {[
                  { icon: '🔍', title: 'Comprehensive Assessment', desc: 'Multi-tenant support with deep analysis' },
                  { icon: '🎨', title: 'Professional UI', desc: 'Wizard interface with progress tracking' },
                  { icon: '🔐', title: 'Enterprise Security', desc: 'AES-256 encryption, RBAC, audit logging' },
                  { icon: '📊', title: 'Advanced Reporting', desc: 'Multiple formats with evidence backing' }
                ].map((feature) => (
                  <div key={feature.title} className="text-center">
                    <div className="text-4xl mb-4">{feature.icon}</div>
                    <h3 className="text-lg font-semibold mb-2">{feature.title}</h3>
                    <p className="text-gray-600">{feature.desc}</p>
                  </div>
                ))}
              </div>
            </div>
          </section>
        )}
      </div>

      <style jsx global>{`
        body {
          font-family: 'Inter', sans-serif;
        }
      `}</style>
    </>
  );
}
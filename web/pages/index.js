import React, { useState } from 'react';
import Head from 'next/head';

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
      </Head>

      <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5', fontFamily: 'Arial, sans-serif' }}>
        {/* Header */}
        <header style={{ backgroundColor: 'white', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', borderBottom: '1px solid #e5e5e5' }}>
          <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '1rem 2rem', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <h1 style={{ fontSize: '1.5rem', fontWeight: 'bold', margin: 0 }}>🚀 PowerReview</h1>
              <span style={{ fontSize: '0.875rem', color: '#666' }}>M365 Security Assessment Framework</span>
            </div>
            <nav style={{ display: 'flex', gap: '1rem', alignItems: 'center' }}>
              <a href="https://github.com/Ross851/M365-Lighthouse" target="_blank" rel="noopener noreferrer" 
                 style={{ color: '#666', textDecoration: 'none' }}>GitHub</a>
              <a href="/demo" 
                 style={{ color: '#666', textDecoration: 'none' }}>Full Demo</a>
              <button onClick={() => setShowDemo(!showDemo)} 
                      style={{ 
                        backgroundColor: '#2563eb', 
                        color: 'white', 
                        padding: '0.5rem 1rem', 
                        borderRadius: '0.375rem', 
                        border: 'none', 
                        cursor: 'pointer',
                        fontSize: '1rem'
                      }}>
                {showDemo ? 'Hide Demo' : 'Live Demo'}
              </button>
            </nav>
          </div>
        </header>

        {/* Hero Section */}
        {!showDemo && (
          <section style={{ background: 'linear-gradient(to right, #2563eb, #4f46e5)', color: 'white', padding: '4rem 2rem', textAlign: 'center' }}>
            <div style={{ maxWidth: '1280px', margin: '0 auto' }}>
              <h2 style={{ fontSize: '2.5rem', fontWeight: 'bold', marginBottom: '1rem' }}>Enterprise M365 Security Assessment</h2>
              <p style={{ fontSize: '1.25rem', marginBottom: '2rem', opacity: 0.9 }}>Comprehensive security analysis for Microsoft 365 and Azure environments</p>
              <div style={{ display: 'flex', justifyContent: 'center', gap: '1rem' }}>
                <button onClick={() => setShowDemo(true)} 
                        style={{ 
                          backgroundColor: 'white', 
                          color: '#2563eb', 
                          padding: '0.75rem 1.5rem', 
                          borderRadius: '0.375rem', 
                          fontWeight: '600',
                          border: 'none',
                          cursor: 'pointer',
                          fontSize: '1rem'
                        }}>
                  View Demo Dashboard
                </button>
                <a href="/demo" 
                   style={{ 
                     backgroundColor: 'transparent', 
                     color: 'white', 
                     padding: '0.75rem 1.5rem', 
                     borderRadius: '0.375rem', 
                     fontWeight: '600',
                     border: '2px solid white',
                     textDecoration: 'none',
                     display: 'inline-block'
                   }}>
                  Try Full Demo
                </a>
              </div>
            </div>
          </section>
        )}

        {/* Demo Dashboard */}
        {showDemo && (
          <div style={{ maxWidth: '1280px', margin: '0 auto', padding: '2rem' }}>
            {/* Tabs */}
            <div style={{ borderBottom: '1px solid #e5e5e5', marginBottom: '2rem', display: 'flex', gap: '2rem' }}>
              {['overview', 'findings', 'services', 'roadmap'].map((tab) => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  style={{
                    padding: '0.5rem 0',
                    borderBottom: activeTab === tab ? '2px solid #2563eb' : '2px solid transparent',
                    background: 'none',
                    border: 'none',
                    cursor: 'pointer',
                    fontSize: '0.875rem',
                    fontWeight: '500',
                    color: activeTab === tab ? '#2563eb' : '#666'
                  }}
                >
                  {tab.charAt(0).toUpperCase() + tab.slice(1)}
                </button>
              ))}
            </div>

            {/* Overview Tab */}
            {activeTab === 'overview' && (
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1.5rem' }}>
                {/* Security Score */}
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem' }}>Overall Security Score</h3>
                  <div style={{ textAlign: 'center', padding: '2rem 0' }}>
                    <div style={{ fontSize: '3rem', fontWeight: 'bold' }}>{securityScore}</div>
                    <div style={{ fontSize: '0.875rem', color: '#666' }}>out of 100</div>
                  </div>
                </div>

                {/* Findings Summary */}
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem' }}>Findings Summary</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '0.75rem' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '0.75rem', height: '0.75rem', backgroundColor: '#dc2626', borderRadius: '50%' }}></div>
                        Critical
                      </span>
                      <span style={{ fontWeight: '600' }}>{findings.critical}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '0.75rem', height: '0.75rem', backgroundColor: '#f97316', borderRadius: '50%' }}></div>
                        High
                      </span>
                      <span style={{ fontWeight: '600' }}>{findings.high}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '0.75rem', height: '0.75rem', backgroundColor: '#eab308', borderRadius: '50%' }}></div>
                        Medium
                      </span>
                      <span style={{ fontWeight: '600' }}>{findings.medium}</span>
                    </div>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <div style={{ width: '0.75rem', height: '0.75rem', backgroundColor: '#22c55e', borderRadius: '50%' }}></div>
                        Low
                      </span>
                      <span style={{ fontWeight: '600' }}>{findings.low}</span>
                    </div>
                  </div>
                </div>

                {/* Quick Stats */}
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem' }}>Assessment Stats</h3>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                    <div>
                      <div style={{ fontSize: '0.875rem', color: '#666' }}>Services Assessed</div>
                      <div style={{ fontSize: '2rem', fontWeight: '600' }}>5</div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.875rem', color: '#666' }}>Policies Reviewed</div>
                      <div style={{ fontSize: '2rem', fontWeight: '600' }}>247</div>
                    </div>
                    <div>
                      <div style={{ fontSize: '0.875rem', color: '#666' }}>Time to Complete</div>
                      <div style={{ fontSize: '2rem', fontWeight: '600' }}>12m 34s</div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {/* Services Tab */}
            {activeTab === 'services' && (
              <div style={{ background: 'white', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <div style={{ padding: '1rem 1.5rem', borderBottom: '1px solid #e5e5e5' }}>
                  <h3 style={{ fontSize: '1.125rem', fontWeight: '600', margin: 0 }}>Service Assessment Scores</h3>
                </div>
                <div>
                  {services.map((service, index) => (
                    <div key={service.name} style={{ 
                      padding: '1rem 1.5rem', 
                      borderBottom: index < services.length - 1 ? '1px solid #e5e5e5' : 'none' 
                    }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                        <h4 style={{ margin: 0, fontWeight: '500' }}>{service.name}</h4>
                        <span style={{ 
                          padding: '0.25rem 0.75rem', 
                          borderRadius: '9999px', 
                          fontSize: '0.875rem', 
                          fontWeight: '500', 
                          color: 'white',
                          backgroundColor: service.color 
                        }}>
                          {service.status}
                        </span>
                      </div>
                      <div style={{ width: '100%', height: '0.5rem', backgroundColor: '#e5e5e5', borderRadius: '9999px', overflow: 'hidden' }}>
                        <div style={{ 
                          height: '100%', 
                          width: `${service.score}%`, 
                          backgroundColor: service.color,
                          transition: 'width 0.3s ease'
                        }}></div>
                      </div>
                      <div style={{ marginTop: '0.25rem', fontSize: '0.875rem', color: '#666' }}>{service.score}/100</div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Other tabs content */}
            {activeTab === 'findings' && (
              <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem' }}>Security Findings</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  <div style={{ padding: '1rem', backgroundColor: '#fef2f2', borderLeft: '4px solid #dc2626' }}>
                    <h4 style={{ fontWeight: '600', color: '#991b1b', marginBottom: '0.25rem' }}>Critical: Unrestricted External Sharing</h4>
                    <p style={{ fontSize: '0.875rem', color: '#b91c1c' }}>45 SharePoint sites allow anonymous access without restrictions</p>
                  </div>
                  <div style={{ padding: '1rem', backgroundColor: '#fff7ed', borderLeft: '4px solid #f97316' }}>
                    <h4 style={{ fontWeight: '600', color: '#9a3412', marginBottom: '0.25rem' }}>High: No DLP Policies Configured</h4>
                    <p style={{ fontSize: '0.875rem', color: '#ea580c' }}>Data Loss Prevention policies are not configured for sensitive information types</p>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'roadmap' && (
              <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '1rem' }}>Remediation Roadmap</h3>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
                  {[
                    { phase: 'Immediate (0-30 days)', items: ['Enable MFA for all users', 'Block legacy authentication', 'Configure DLP policies'], effort: 'Low' },
                    { phase: 'Short-term (30-90 days)', items: ['Implement sensitivity labels', 'Configure retention policies', 'Enable audit logging'], effort: 'Medium' },
                    { phase: 'Long-term (90-180 days)', items: ['Implement Zero Trust architecture', 'Advanced threat protection', 'Compliance automation'], effort: 'High' }
                  ].map((phase) => (
                    <div key={phase.phase} style={{ border: '1px solid #e5e5e5', borderRadius: '0.5rem', padding: '1rem' }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
                        <h4 style={{ margin: 0, fontWeight: '600' }}>{phase.phase}</h4>
                        <span style={{ 
                          fontSize: '0.875rem', 
                          padding: '0.25rem 0.5rem', 
                          borderRadius: '0.25rem',
                          backgroundColor: phase.effort === 'Low' ? '#dcfce7' : phase.effort === 'Medium' ? '#fef9c3' : '#fee2e2',
                          color: phase.effort === 'Low' ? '#166534' : phase.effort === 'Medium' ? '#713f12' : '#991b1b'
                        }}>
                          {phase.effort} Effort
                        </span>
                      </div>
                      <ul style={{ margin: '0.5rem 0 0 1.5rem', padding: 0, fontSize: '0.875rem', color: '#666' }}>
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
          <section style={{ padding: '4rem 2rem' }}>
            <div style={{ maxWidth: '1280px', margin: '0 auto' }}>
              <h2 style={{ fontSize: '2rem', fontWeight: 'bold', textAlign: 'center', marginBottom: '3rem' }}>Key Features</h2>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', gap: '2rem' }}>
                {[
                  { icon: '🔍', title: 'Comprehensive Assessment', desc: 'Multi-tenant support with deep analysis' },
                  { icon: '🎨', title: 'Professional UI', desc: 'Wizard interface with progress tracking' },
                  { icon: '🔐', title: 'Enterprise Security', desc: 'AES-256 encryption, RBAC, audit logging' },
                  { icon: '📊', title: 'Advanced Reporting', desc: 'Multiple formats with evidence backing' }
                ].map((feature) => (
                  <div key={feature.title} style={{ textAlign: 'center' }}>
                    <div style={{ fontSize: '3rem', marginBottom: '1rem' }}>{feature.icon}</div>
                    <h3 style={{ fontSize: '1.125rem', fontWeight: '600', marginBottom: '0.5rem' }}>{feature.title}</h3>
                    <p style={{ color: '#666' }}>{feature.desc}</p>
                  </div>
                ))}
              </div>
            </div>
          </section>
        )}
      </div>
    </>
  );
}
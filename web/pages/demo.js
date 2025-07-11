import React, { useState } from 'react';
import Head from 'next/head';

export default function Demo() {
  const [authenticated, setAuthenticated] = useState(false);
  const [activeView, setActiveView] = useState('login');
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [assessmentRunning, setAssessmentRunning] = useState(false);
  const [progress, setProgress] = useState(0);

  const handleLogin = (e) => {
    e.preventDefault();
    if (username === 'admin' && password === 'PowerReview2024') {
      setAuthenticated(true);
      setActiveView('overview');
      setError('');
    } else {
      setError('Invalid credentials. Try admin / PowerReview2024');
    }
  };

  const startAssessment = () => {
    setAssessmentRunning(true);
    setProgress(0);
    
    const interval = setInterval(() => {
      setProgress(prev => {
        if (prev >= 100) {
          clearInterval(interval);
          setAssessmentRunning(false);
          alert('Assessment Complete! View results in Reports section.');
          return 100;
        }
        return prev + 10;
      });
    }, 1000);
  };

  if (!authenticated) {
    return (
      <>
        <Head>
          <title>PowerReview - Login</title>
        </Head>
        <div style={{ 
          minHeight: '100vh', 
          display: 'flex', 
          alignItems: 'center', 
          justifyContent: 'center',
          background: 'linear-gradient(to right, #1e3a8a, #7c3aed)',
          fontFamily: 'Arial, sans-serif'
        }}>
          <div style={{ 
            background: 'white', 
            padding: '2rem', 
            borderRadius: '0.5rem', 
            boxShadow: '0 10px 25px rgba(0,0,0,0.2)',
            width: '100%',
            maxWidth: '400px'
          }}>
            <div style={{ textAlign: 'center', marginBottom: '2rem' }}>
              <h1 style={{ fontSize: '2rem', marginBottom: '0.5rem' }}>🚀 PowerReview v2.0</h1>
              <p style={{ color: '#6b7280' }}>Microsoft 365 Security Assessment</p>
            </div>

            <form onSubmit={handleLogin}>
              <div style={{ marginBottom: '1rem' }}>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: '600' }}>
                  Username
                </label>
                <input 
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  placeholder="Enter username"
                  required
                  style={{ 
                    width: '100%', 
                    padding: '0.75rem', 
                    border: '1px solid #d1d5db',
                    borderRadius: '0.375rem',
                    fontSize: '1rem',
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{ display: 'block', marginBottom: '0.5rem', fontWeight: '600' }}>
                  Password
                </label>
                <input 
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Enter password"
                  required
                  style={{ 
                    width: '100%', 
                    padding: '0.75rem', 
                    border: '1px solid #d1d5db',
                    borderRadius: '0.375rem',
                    fontSize: '1rem',
                    boxSizing: 'border-box'
                  }}
                />
              </div>

              {error && (
                <div style={{ 
                  padding: '0.75rem', 
                  background: '#fee2e2', 
                  border: '1px solid #fecaca',
                  borderRadius: '0.375rem',
                  color: '#dc2626',
                  marginBottom: '1rem',
                  fontSize: '0.875rem'
                }}>
                  {error}
                </div>
              )}

              <button 
                type="submit"
                style={{ 
                  width: '100%',
                  padding: '0.75rem',
                  background: '#3b82f6',
                  color: 'white',
                  border: 'none',
                  borderRadius: '0.375rem',
                  fontSize: '1rem',
                  fontWeight: '600',
                  cursor: 'pointer'
                }}
              >
                Sign In
              </button>
            </form>

            <div style={{ marginTop: '2rem', textAlign: 'center', fontSize: '0.875rem', color: '#6b7280' }}>
              <p>Demo Credentials:</p>
              <p><strong>Username:</strong> admin</p>
              <p><strong>Password:</strong> PowerReview2024</p>
            </div>
          </div>
        </div>
      </>
    );
  }

  return (
    <>
      <Head>
        <title>PowerReview Dashboard</title>
      </Head>

      <div style={{ minHeight: '100vh', backgroundColor: '#f5f5f5', fontFamily: 'Arial, sans-serif' }}>
        {/* Header */}
        <header style={{ backgroundColor: '#1e293b', color: 'white', padding: '1rem' }}>
          <div style={{ maxWidth: '1400px', margin: '0 auto', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '2rem' }}>
              <h1 style={{ margin: 0, fontSize: '1.5rem' }}>🚀 PowerReview Pro v2.0</h1>
              <nav style={{ display: 'flex', gap: '1rem' }}>
                <button 
                  onClick={() => setActiveView('overview')}
                  style={{ 
                    background: activeView === 'overview' ? '#3b82f6' : 'transparent',
                    border: 'none',
                    color: 'white',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  Overview
                </button>
                <button 
                  onClick={() => setActiveView('assessment')}
                  style={{ 
                    background: activeView === 'assessment' ? '#3b82f6' : 'transparent',
                    border: 'none',
                    color: 'white',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  New Assessment
                </button>
                <button 
                  onClick={() => setActiveView('questionnaire')}
                  style={{ 
                    background: activeView === 'questionnaire' ? '#3b82f6' : 'transparent',
                    border: 'none',
                    color: 'white',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  Questionnaire
                </button>
                <button 
                  onClick={() => setActiveView('reports')}
                  style={{ 
                    background: activeView === 'reports' ? '#3b82f6' : 'transparent',
                    border: 'none',
                    color: 'white',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  Reports
                </button>
              </nav>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
              <span>👤 Admin User</span>
              <button 
                onClick={() => {
                  setAuthenticated(false);
                  setUsername('');
                  setPassword('');
                }}
                style={{ 
                  background: '#ef4444',
                  border: 'none',
                  color: 'white',
                  padding: '0.5rem 1rem',
                  borderRadius: '0.25rem',
                  cursor: 'pointer'
                }}
              >
                Logout
              </button>
            </div>
          </div>
        </header>

        <main style={{ maxWidth: '1400px', margin: '2rem auto', padding: '0 1rem' }}>
          {/* Overview View */}
          {activeView === 'overview' && (
            <div>
              <h2>Security Dashboard Overview</h2>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))', gap: '1rem', marginBottom: '2rem' }}>
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3>Latest Assessment</h3>
                  <div style={{ fontSize: '3rem', fontWeight: 'bold', color: '#3b82f6' }}>72</div>
                  <p>Security Score</p>
                  <button 
                    onClick={() => setActiveView('assessment')}
                    style={{ 
                      background: '#3b82f6',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer',
                      marginTop: '1rem'
                    }}
                  >
                    Run New Assessment
                  </button>
                </div>
                
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3>Critical Findings</h3>
                  <div style={{ fontSize: '3rem', fontWeight: 'bold', color: '#ef4444' }}>12</div>
                  <p>Require immediate attention</p>
                  <button 
                    onClick={() => setActiveView('reports')}
                    style={{ 
                      background: '#ef4444',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer',
                      marginTop: '1rem'
                    }}
                  >
                    View Details
                  </button>
                </div>
                
                <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                  <h3>Tenants Monitored</h3>
                  <div style={{ fontSize: '3rem', fontWeight: 'bold', color: '#10b981' }}>4</div>
                  <p>Active tenant connections</p>
                  <button 
                    style={{ 
                      background: '#10b981',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer',
                      marginTop: '1rem'
                    }}
                  >
                    Manage Tenants
                  </button>
                </div>
              </div>

              {/* Recent Activity */}
              <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <h3>Recent Activity</h3>
                <div style={{ marginTop: '1rem' }}>
                  <div style={{ padding: '0.75rem', borderBottom: '1px solid #e5e7eb' }}>
                    <strong>Assessment Completed</strong> - Contoso Tenant
                    <span style={{ float: 'right', color: '#6b7280' }}>2 hours ago</span>
                  </div>
                  <div style={{ padding: '0.75rem', borderBottom: '1px solid #e5e7eb' }}>
                    <strong>Report Generated</strong> - Executive Summary PDF
                    <span style={{ float: 'right', color: '#6b7280' }}>3 hours ago</span>
                  </div>
                  <div style={{ padding: '0.75rem', borderBottom: '1px solid #e5e7eb' }}>
                    <strong>Questionnaire Completed</strong> - Fabrikam Discovery
                    <span style={{ float: 'right', color: '#6b7280' }}>1 day ago</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* New Assessment View */}
          {activeView === 'assessment' && (
            <div style={{ background: 'white', padding: '2rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
              <h2>Run New Assessment</h2>
              
              {!assessmentRunning ? (
                <div>
                  <div style={{ marginBottom: '2rem' }}>
                    <h3>Select Tenant</h3>
                    <select style={{ width: '100%', padding: '0.5rem', borderRadius: '0.25rem', border: '1px solid #d1d5db' }}>
                      <option>Contoso (contoso.onmicrosoft.com)</option>
                      <option>Fabrikam (fabrikam.onmicrosoft.com)</option>
                      <option>Woodgrove (woodgrove.onmicrosoft.com)</option>
                      <option>Tailwind (tailwind.onmicrosoft.com)</option>
                    </select>
                  </div>

                  <div style={{ marginBottom: '2rem' }}>
                    <h3>Select Modules</h3>
                    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(2, 1fr)', gap: '1rem' }}>
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" defaultChecked /> Microsoft Purview
                      </label>
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" defaultChecked /> SharePoint & OneDrive
                      </label>
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" defaultChecked /> Microsoft Teams
                      </label>
                      <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                        <input type="checkbox" defaultChecked /> Power Platform
                      </label>
                    </div>
                  </div>

                  <button 
                    onClick={startAssessment}
                    style={{ 
                      background: '#3b82f6',
                      color: 'white',
                      border: 'none',
                      padding: '0.75rem 2rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer',
                      fontSize: '1.1rem'
                    }}
                  >
                    Start Assessment
                  </button>
                </div>
              ) : (
                <div>
                  <h3>Assessment Running...</h3>
                  <div style={{ marginTop: '2rem' }}>
                    <div style={{ background: '#e5e7eb', height: '2rem', borderRadius: '0.5rem', overflow: 'hidden' }}>
                      <div 
                        style={{ 
                          background: '#3b82f6', 
                          height: '100%', 
                          width: `${progress}%`,
                          transition: 'width 0.5s ease'
                        }}
                      ></div>
                    </div>
                    <p style={{ textAlign: 'center', marginTop: '1rem' }}>{progress}% Complete</p>
                  </div>
                  
                  <div style={{ marginTop: '2rem', padding: '1rem', background: '#f3f4f6', borderRadius: '0.25rem' }}>
                    <p>🔍 Currently scanning: Microsoft Purview DLP Policies...</p>
                    <p>✅ Completed: Authentication, Permissions Check</p>
                    <p>⏱️ Estimated time remaining: {10 - Math.floor(progress/10)} minutes</p>
                  </div>
                </div>
              )}
            </div>
          )}

          {/* Questionnaire View */}
          {activeView === 'questionnaire' && (
            <div style={{ background: 'white', padding: '2rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
              <h2>Discovery Questionnaire</h2>
              
              <div style={{ marginBottom: '2rem' }}>
                <h3>Select Template</h3>
                <select style={{ width: '100%', padding: '0.5rem', borderRadius: '0.25rem', border: '1px solid #d1d5db' }}>
                  <option>Electoral Commission Template (50+ questions)</option>
                  <option>General Discovery (15 questions)</option>
                  <option>Healthcare HIPAA Compliance</option>
                  <option>Financial Services SOX</option>
                </select>
              </div>

              <div style={{ marginBottom: '2rem' }}>
                <h3>Question 1 of 15</h3>
                <p style={{ fontSize: '1.1rem', marginBottom: '1rem' }}>
                  Does your organization currently have a data classification scheme in place?
                </p>
                <div style={{ display: 'flex', flexDirection: 'column', gap: '0.5rem' }}>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <input type="radio" name="q1" /> Yes, fully implemented
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <input type="radio" name="q1" /> Yes, partially implemented
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <input type="radio" name="q1" /> In development
                  </label>
                  <label style={{ display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
                    <input type="radio" name="q1" /> No
                  </label>
                </div>
                
                <div style={{ marginTop: '1rem', padding: '1rem', background: '#eff6ff', borderRadius: '0.25rem', border: '1px solid #3b82f6' }}>
                  <strong>💡 Best Practice:</strong> Organizations should have at least 3-5 classification levels 
                  (Public, Internal, Confidential, Highly Confidential) aligned with business requirements.
                </div>
              </div>

              <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: '2rem' }}>
                <button 
                  style={{ 
                    background: '#6b7280',
                    color: 'white',
                    border: 'none',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  Previous
                </button>
                <span>Progress: 1/15 (7%)</span>
                <button 
                  style={{ 
                    background: '#3b82f6',
                    color: 'white',
                    border: 'none',
                    padding: '0.5rem 1rem',
                    borderRadius: '0.25rem',
                    cursor: 'pointer'
                  }}
                >
                  Next
                </button>
              </div>
            </div>
          )}

          {/* Reports View */}
          {activeView === 'reports' && (
            <div>
              <h2>Assessment Reports</h2>
              
              <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)', marginBottom: '2rem' }}>
                <h3>Export Options</h3>
                <div style={{ display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
                  <button 
                    onClick={() => alert('PDF Export initiated! In production, this would generate a real PDF.')}
                    style={{ 
                      background: '#ef4444',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer'
                    }}
                  >
                    📄 Export PDF
                  </button>
                  <button 
                    onClick={() => alert('Excel Export initiated! In production, this would generate a real Excel file.')}
                    style={{ 
                      background: '#10b981',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer'
                    }}
                  >
                    📊 Export Excel
                  </button>
                  <button 
                    onClick={() => alert('PowerBI Export initiated! In production, this would connect to PowerBI.')}
                    style={{ 
                      background: '#f59e0b',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer'
                    }}
                  >
                    📈 Export to PowerBI
                  </button>
                  <button 
                    onClick={() => alert('Client Portal Generated! URL: https://portal.powerreview.com/abc123')}
                    style={{ 
                      background: '#8b5cf6',
                      color: 'white',
                      border: 'none',
                      padding: '0.5rem 1rem',
                      borderRadius: '0.25rem',
                      cursor: 'pointer'
                    }}
                  >
                    🌐 Generate Client Portal
                  </button>
                </div>
              </div>

              <div style={{ background: 'white', padding: '1.5rem', borderRadius: '0.5rem', boxShadow: '0 1px 3px rgba(0,0,0,0.1)' }}>
                <h3>Recent Reports</h3>
                <div style={{ overflowX: 'auto' }}>
                  <table style={{ width: '100%', borderCollapse: 'collapse', minWidth: '600px' }}>
                    <thead>
                      <tr style={{ borderBottom: '2px solid #e5e7eb' }}>
                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Date</th>
                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Tenant</th>
                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Score</th>
                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Findings</th>
                        <th style={{ padding: '0.75rem', textAlign: 'left' }}>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                        <td style={{ padding: '0.75rem' }}>2024-01-11</td>
                        <td style={{ padding: '0.75rem' }}>Contoso</td>
                        <td style={{ padding: '0.75rem' }}>72/100</td>
                        <td style={{ padding: '0.75rem' }}>
                          <span style={{ color: '#ef4444' }}>12 Critical</span>, 
                          <span style={{ color: '#f59e0b' }}> 47 High</span>
                        </td>
                        <td style={{ padding: '0.75rem' }}>
                          <button style={{ marginRight: '0.5rem', color: '#3b82f6', cursor: 'pointer', background: 'none', border: 'none' }}>View</button>
                          <button style={{ marginRight: '0.5rem', color: '#10b981', cursor: 'pointer', background: 'none', border: 'none' }}>Download</button>
                          <button style={{ color: '#8b5cf6', cursor: 'pointer', background: 'none', border: 'none' }}>Share</button>
                        </td>
                      </tr>
                      <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
                        <td style={{ padding: '0.75rem' }}>2024-01-10</td>
                        <td style={{ padding: '0.75rem' }}>Fabrikam</td>
                        <td style={{ padding: '0.75rem' }}>85/100</td>
                        <td style={{ padding: '0.75rem' }}>
                          <span style={{ color: '#ef4444' }}>3 Critical</span>, 
                          <span style={{ color: '#f59e0b' }}> 15 High</span>
                        </td>
                        <td style={{ padding: '0.75rem' }}>
                          <button style={{ marginRight: '0.5rem', color: '#3b82f6', cursor: 'pointer', background: 'none', border: 'none' }}>View</button>
                          <button style={{ marginRight: '0.5rem', color: '#10b981', cursor: 'pointer', background: 'none', border: 'none' }}>Download</button>
                          <button style={{ color: '#8b5cf6', cursor: 'pointer', background: 'none', border: 'none' }}>Share</button>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>
    </>
  );
}
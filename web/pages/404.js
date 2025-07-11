export default function Custom404() {
  return (
    <div style={{ 
      minHeight: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center',
      fontFamily: 'Arial, sans-serif',
      textAlign: 'center'
    }}>
      <div>
        <h1>404 - Page Not Found</h1>
        <p>Available pages:</p>
        <ul style={{ listStyle: 'none', padding: 0 }}>
          <li><a href="/">Home Page</a></li>
          <li><a href="/demo">Demo Dashboard (with login)</a></li>
          <li><a href="/test">Test Page</a></li>
        </ul>
        <p>Version: 2.0.0</p>
      </div>
    </div>
  )
}
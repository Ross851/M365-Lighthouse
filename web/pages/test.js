export default function Test() {
  return (
    <div style={{ padding: '2rem', fontFamily: 'Arial, sans-serif' }}>
      <h1>✅ PowerReview v2.0.0 - Test Page Working!</h1>
      <p>If you can see this, the deployment is successful.</p>
      <ul>
        <li><a href="/">Home Page</a></li>
        <li><a href="/demo">Full Demo Dashboard</a></li>
      </ul>
      <hr />
      <p>Version: 2.0.0</p>
      <p>Build Date: {new Date().toISOString()}</p>
    </div>
  );
}
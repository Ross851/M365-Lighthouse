// Simple authentication API
export default function handler(req, res) {
  if (req.method === 'POST') {
    const { username, password } = req.body;
    
    // Demo authentication (in production, use proper auth)
    if (username === 'admin' && password === 'PowerReview2024') {
      res.status(200).json({ 
        success: true, 
        token: 'demo-token-' + Date.now(),
        user: {
          name: 'Admin User',
          role: 'Global Administrator',
          permissions: ['read', 'write', 'execute', 'admin']
        }
      });
    } else {
      res.status(401).json({ success: false, message: 'Invalid credentials' });
    }
  } else {
    res.status(405).json({ message: 'Method not allowed' });
  }
}
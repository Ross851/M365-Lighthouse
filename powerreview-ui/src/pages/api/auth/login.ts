import type { APIRoute } from 'astro';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

export const prerender = false;

// In production, these would be in environment variables
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const USERS = {
  'developer@company.com': {
    password: '$2a$10$xQqKjKBXYLHqHWvqEpHOh.gVxVqLw5HCrP1V.QjQqVqD7YKHNqHNm', // 'SecurePassword123!'
    role: 'developer',
    name: 'Ross Developer'
  },
  'admin@powerreview.com': {
    password: '$2a$10$Qm7LJ2MVfKw5L2df1K0tLu9Cf2tz8wM4M9uFdCp.P0sue/0FXd0Ky', // 'PowerReview2024!'
    role: 'admin',
    name: 'Admin User'
  },
  'demo@powerreview.com': {
    password: 'demo', // Plain text for demo only
    role: 'admin',
    name: 'Demo User'
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    // Parse request body
    let email, password;
    try {
      const body = await request.json();
      email = body.email;
      password = body.password;
    } catch (parseError) {
      return new Response(JSON.stringify({ error: 'Invalid request format' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Validate inputs
    if (!email || !password) {
      return new Response(JSON.stringify({ error: 'Email and password are required' }), {
        status: 400,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Check if user exists
    const user = USERS[email];
    
    // For demo account, handle specially
    if (email === 'demo@powerreview.com' && password === 'demo') {
      const token = jwt.sign(
        { 
          email: 'demo@powerreview.com', 
          role: 'admin',
          name: 'Demo User' 
        },
        JWT_SECRET,
        { expiresIn: '24h' }
      );
      
      return new Response(JSON.stringify({ 
        success: true,
        token,
        user: {
          email: 'demo@powerreview.com',
          name: 'Demo User',
          role: 'admin'
        }
      }), {
        status: 200,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    if (!user) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Verify password
    const isValid = await bcrypt.compare(password, user.password);
    
    if (!isValid) {
      return new Response(JSON.stringify({ error: 'Invalid credentials' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' }
      });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { 
        email, 
        role: user.role,
        name: user.name 
      },
      JWT_SECRET,
      { expiresIn: '24h' }
    );
    
    return new Response(JSON.stringify({ 
      success: true,
      token,
      user: {
        email,
        name: user.name,
        role: user.role
      }
    }), {
      status: 200,
      headers: { 'Content-Type': 'application/json' }
    });
    
  } catch (error) {
    return new Response(JSON.stringify({ error: 'Server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
};
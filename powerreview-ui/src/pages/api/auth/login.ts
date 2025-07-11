import type { APIRoute } from 'astro';
import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';

// In production, these would be in environment variables
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-in-production';
const USERS = {
  'developer@company.com': {
    password: '$2a$10$xQqKjKBXYLHqHWvqEpHOh.gVxVqLw5HCrP1V.QjQqVqD7YKHNqHNm', // 'SecurePassword123!'
    role: 'developer',
    name: 'Ross Developer'
  }
};

export const POST: APIRoute = async ({ request }) => {
  try {
    const { email, password } = await request.json();
    
    // Check if user exists
    const user = USERS[email];
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
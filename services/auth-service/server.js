const express = require('express')
const bcrypt = require('bcryptjs')
const jwt = require('jsonwebtoken')
const mysql = require('mysql2/promise')
const cors = require('cors')
require('dotenv').config()

const app = express()
const PORT = process.env.PORT || 8001

// CI/CD Pipeline Full Test - January 2026 v1.0.0
// This service now includes automated builds and security scanning
// Testing multi-service deployment

// Enhanced CORS configuration
app.use(cors({
  credentials: true,
  origin: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}))
app.use(express.json())

// Logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`)
  next()
})

// Database connection pool
const pool = mysql.createPool({
  host: process.env.DB_HOST || 'mysql',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || 'password',
  database: process.env.DB_NAME || 'task_manager',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
})

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'auth-service' })
})

// Register endpoint
app.post('/api/auth/register', async (req, res) => {
  const { username, password } = req.body

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' })
  }

  try {
    const hashedPassword = await bcrypt.hash(password, 10)
    
    const [result] = await pool.execute(
      'INSERT INTO users (username, password) VALUES (?, ?)',
      [username, hashedPassword]
    )

    res.status(201).json({ message: 'User registered successfully', userId: result.insertId })
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({ error: 'Username already exists' })
    }
    console.error('Registration error:', error)
    res.status(500).json({ error: 'Registration failed' })
  }
})

// Login endpoint
app.post('/api/auth/login', async (req, res) => {
  const { username, password } = req.body

  if (!username || !password) {
    return res.status(400).json({ error: 'Username and password required' })
  }

  try {
    console.log(`Login attempt for user: ${username}`)
    const [users] = await pool.execute(
      'SELECT * FROM users WHERE username = ?',
      [username]
    )

    if (users.length === 0) {
      console.log(`Login failed: User not found - ${username}`)
      return res.status(401).json({ error: 'Invalid credentials' })
    }

    const user = users[0]
    const isValidPassword = await bcrypt.compare(password, user.password)

    if (!isValidPassword) {
      console.log(`Login failed: Invalid password for user - ${username}`)
      return res.status(401).json({ error: 'Invalid credentials' })
    }

    const token = jwt.sign(
      { userId: user.id, username: user.username },
      process.env.JWT_SECRET || 'your-secret-key',
      { expiresIn: '24h' }
    )

    console.log(`Login successful for user: ${username} (ID: ${user.id})`)
    res.json({ token, userId: user.id, username: user.username })
  } catch (error) {
    console.error('Login error:', error)
    res.status(500).json({ error: 'Login failed' })
  }
})

// Verify token endpoint
app.post('/api/auth/verify', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1]

  if (!token) {
    return res.status(401).json({ error: 'No token provided' })
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key')
    res.json({ valid: true, userId: decoded.userId, username: decoded.username })
  } catch (error) {
    console.error('Token verification error:', error.message)
    res.status(401).json({ error: 'Invalid token' })
  }
})

// Get user profile
app.get('/api/auth/profile', async (req, res) => {
  const token = req.headers.authorization?.split(' ')[1]

  if (!token) {
    return res.status(401).json({ error: 'No token provided' })
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key')
    
    const [users] = await pool.execute(
      'SELECT id, username, created_at FROM users WHERE id = ?',
      [decoded.userId]
    )

    if (users.length === 0) {
      return res.status(404).json({ error: 'User not found' })
    }

    res.json(users[0])
  } catch (error) {
    console.error('Profile fetch error:', error)
    res.status(500).json({ error: 'Failed to fetch profile' })
  }
})

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('Unhandled error:', err)
  res.status(500).json({ error: 'Internal server error' })
})

app.listen(PORT, () => {
  console.log(`Auth service running on port ${PORT}`)
  console.log(`Database: ${process.env.DB_HOST || 'mysql'}/${process.env.DB_NAME || 'task_manager'}`)
})

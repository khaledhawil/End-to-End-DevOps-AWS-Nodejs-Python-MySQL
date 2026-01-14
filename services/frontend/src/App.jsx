import { BrowserRouter as Router, Routes, Route, Navigate, useLocation } from 'react-router-dom'
import { useState, useEffect } from 'react'
import axios from 'axios'
import Login from './pages/Login'
import Register from './pages/Register'
import Dashboard from './pages/Dashboard'
import './App.css'

// CI/CD Pipeline Full Test - January 2026 v1.0.0
// Frontend with automated builds and deployments

// Loading component
const LoadingScreen = () => (
  <div className="loading-screen">
    <div className="spinner"></div>
    <h2>Loading...</h2>
  </div>
)

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [loading, setLoading] = useState(true)
  const [user, setUser] = useState(null)

  // Verify token and auto-login on page load
  useEffect(() => {
    const verifyToken = async () => {
      const token = localStorage.getItem('token')
      
      if (!token) {
        setLoading(false)
        setIsAuthenticated(false)
        return
      }

      try {
        // Verify token is still valid
        const response = await axios.post('/api/auth/verify', {}, {
          headers: { Authorization: `Bearer ${token}` }
        })

        if (response.data.valid) {
          setIsAuthenticated(true)
          setUser(response.data)
          console.log('Session restored:', response.data.username)
        } else {
          // Invalid token, clear it
          localStorage.removeItem('token')
          setIsAuthenticated(false)
        }
      } catch (error) {
        console.error('Token verification failed:', error)
        // Token expired or invalid, clear it
        localStorage.removeItem('token')
        setIsAuthenticated(false)
      } finally {
        setLoading(false)
      }
    }

    verifyToken()
  }, [])

  // Axios interceptor for automatic logout on 401
  useEffect(() => {
    const interceptor = axios.interceptors.response.use(
      response => response,
      error => {
        if (error.response?.status === 401) {
          console.log('Session expired, logging out...')
          localStorage.removeItem('token')
          setIsAuthenticated(false)
          setUser(null)
        }
        return Promise.reject(error)
      }
    )

    return () => axios.interceptors.response.eject(interceptor)
  }, [])

  const ProtectedRoute = ({ children }) => {
    if (loading) return <LoadingScreen />
    return isAuthenticated ? children : <Navigate to="/login" replace />
  }

  const PublicRoute = ({ children }) => {
    if (loading) return <LoadingScreen />
    // Don't redirect if already authenticated - let the component handle it
    return children
  }

  return (
    <Router>
      <Routes>
        <Route 
          path="/login" 
          element={<Login setAuth={setIsAuthenticated} setUser={setUser} />} 
        />
        <Route 
          path="/register" 
          element={<Register />} 
        />
        <Route
          path="/dashboard"
          element={
            <ProtectedRoute>
              <Dashboard setAuth={setIsAuthenticated} user={user} />
            </ProtectedRoute>
          }
        />
        <Route path="/" element={<Navigate to="/dashboard" replace />} />
        <Route path="*" element={<Navigate to="/dashboard" replace />} />
      </Routes>
    </Router>
  )
}

export default App

import { useState } from 'react'
import { useNavigate, Link } from 'react-router-dom'
import axios from 'axios'

function Register() {
  const [formData, setFormData] = useState({ username: '', password: '', confirmPassword: '' })
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [passwordStrength, setPasswordStrength] = useState({ score: 0, feedback: '' })
  const navigate = useNavigate()

  const validatePassword = (password) => {
    let score = 0
    let feedback = []

    if (password.length >= 12) score += 1
    else feedback.push('at least 12 characters')

    if (/[a-z]/.test(password)) score += 1
    else feedback.push('lowercase letter')

    if (/[A-Z]/.test(password)) score += 1
    else feedback.push('uppercase letter')

    if (/\d/.test(password)) score += 1
    else feedback.push('number')

    if (/[@$!%*?&#]/.test(password)) score += 1
    else feedback.push('special character (@$!%*?&#)')

    const strengthLabels = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong']
    return {
      score,
      label: strengthLabels[score] || 'Very Weak',
      feedback: feedback.length > 0 ? `Missing: ${feedback.join(', ')}` : 'Strong password!',
      isValid: score >= 5
    }
  }

  const handlePasswordChange = (e) => {
    const password = e.target.value
    setFormData({ ...formData, password })
    setPasswordStrength(validatePassword(password))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError('')
    setLoading(true)
    
    // Username validation
    if (formData.username.length < 3 || formData.username.length > 30) {
      setError('Username must be between 3 and 30 characters')
      setLoading(false)
      return
    }

    if (!/^[a-zA-Z0-9_-]+$/.test(formData.username)) {
      setError('Username can only contain letters, numbers, underscores, and hyphens')
      setLoading(false)
      return
    }

    if (formData.password !== formData.confirmPassword) {
      setError('Passwords do not match')
      setLoading(false)
      return
    }

    if (!passwordStrength.isValid) {
      setError('Password must be at least 12 characters and contain uppercase, lowercase, number, and special character')
      setLoading(false)
      return
    }
    
    try {
      await axios.post('/api/auth/register', {
        username: formData.username,
        password: formData.password
      })
      setSuccess(true)
      setTimeout(() => navigate('/login'), 2000)
    } catch (err) {
      setError(err.response?.data?.error || 'Registration failed')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="auth-container">
      <div className="auth-card">
        <h2>Create Account</h2>
        <p className="subtitle">Join us to manage your tasks efficiently</p>
        {error && <div className="error-message">{error}</div>}
        {success && <div className="success-message">Registration successful! Redirecting to login...</div>}
        <form onSubmit={handleSubmit}>
          <input
            type="text"
            placeholder="Username (3-30 characters)"
            value={formData.username}
            onChange={(e) => setFormData({ ...formData, username: e.target.value })}
            required
            disabled={loading || success}
            minLength={3}
            maxLength={30}
          />
          <input
            type="password"
            placeholder="Password (min 12 characters)"
            value={formData.password}
            onChange={handlePasswordChange}
            required
            disabled={loading || success}
            minLength={12}
          />
          {formData.password && (
            <div className={`password-strength strength-${passwordStrength.score}`}>
              <div className="strength-bar">
                <div 
                  className="strength-fill" 
                  style={{ width: `${(passwordStrength.score / 5) * 100}%` }}
                />
              </div>
              <span className="strength-label">{passwordStrength.label}</span>
              <span className="strength-feedback">{passwordStrength.feedback}</span>
            </div>
          )}
          <input
            type="password"
            placeholder="Confirm Password"
            value={formData.confirmPassword}
            onChange={(e) => setFormData({ ...formData, confirmPassword: e.target.value })}
            required
            disabled={loading || success}
          />
          <button type="submit" disabled={loading || success}>
            {loading ? 'Creating Account...' : success ? 'Success!' : 'Register'}
          </button>
        </form>
        <p>
          Already have an account? <Link to="/login">Login</Link>
        </p>
      </div>
    </div>
  )
}

export default Register

# Security Quick Reference & Deployment Checklist

## 🚀 Quick Start

### Before First Deployment

```bash
# 1. Generate production secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 24  # For DB_PASSWORD

# 2. Update k8s/overlays/production/secrets.yaml
# Replace ALL placeholder values with generated secrets

# 3. Install dependencies
cd services/auth-service && npm install
cd ../task-service && pip install -r requirements.txt

# 4. Set environment variables in deployment
# Add ALLOWED_ORIGINS and NODE_ENV=production

# 5. Build and push Docker images
docker build -t your-registry/auth:secure services/auth-service/
docker build -t your-registry/task:secure services/task-service/
docker build -t your-registry/frontend:secure services/frontend/

# 6. Deploy
kubectl apply -k k8s/overlays/production/
```

---

## 🔒 Security Features Enabled

### Authentication (auth-service)
- ✅ JWT tokens with 24h expiration
- ✅ bcrypt password hashing (cost factor 10)
- ✅ Strong password policy (12+ chars, complexity)
- ✅ Generic error messages (no username enumeration)
- ✅ Constant-time password comparison

### Rate Limiting
- ✅ Login: 5 attempts per 15 minutes
- ✅ Registration: 3 per hour per IP
- ✅ API endpoints: 100 per 15 minutes
- ✅ Task creation: 20 per minute
- ✅ Task updates: 30 per minute

### Input Validation
- ✅ Username: 3-30 chars, alphanumeric only
- ✅ Password: 12+ chars with complexity
- ✅ Task title: 1-200 chars
- ✅ Task description: 1-2000 chars
- ✅ Priority/Status: enum validation

### Security Headers (helmet)
- ✅ Content-Security-Policy
- ✅ Strict-Transport-Security (HSTS)
- ✅ X-Content-Type-Options: nosniff
- ✅ X-Frame-Options: DENY
- ✅ X-XSS-Protection: enabled

### Secrets Management
- ✅ JWT_SECRET in Kubernetes Secret
- ✅ Database credentials in Kubernetes Secrets
- ✅ No hardcoded secrets in code
- ✅ Validation ensures secrets are set

### CORS Protection
- ✅ Configurable allowed origins
- ✅ Credentials support enabled
- ✅ Specific methods allowed
- ✅ Production mode restricts origins

---

## ⚠️ Critical Configuration Points

### 1. Environment Variables Required

**Production Deployment:**
```yaml
env:
  - name: NODE_ENV
    value: "production"
  - name: ALLOWED_ORIGINS
    value: "https://yourdomain.com"
  - name: JWT_SECRET
    valueFrom:
      secretKeyRef:
        name: jwt-secret
        key: secret
```

### 2. Secrets to Change Before Production

```bash
# ⚠️ CHANGE THESE IMMEDIATELY ⚠️
k8s/overlays/production/secrets.yaml:
  - jwt-secret: "CHANGE-ME-GENERATE-WITH-openssl-rand-base64-32"
  - db-password: Generate strong password
```

### 3. Docker Images to Update

```yaml
k8s/base/auth-service-deployment.yaml:
  image: khaledhawil/task-manager-auth:latest  # Update to your registry

k8s/base/task-service-deployment.yaml:
  image: khaledhawil/task-manager-task:latest  # Update to your registry
```

---

## 📋 Pre-Deployment Checklist

### Security Configuration
- [ ] JWT_SECRET changed from default
- [ ] Database password changed from default/rootpassword
- [ ] ALLOWED_ORIGINS configured for your domain
- [ ] NODE_ENV=production set
- [ ] All secrets.yaml files updated (local/staging/production)

### Dependencies
- [ ] `npm install` completed in auth-service
- [ ] `pip install -r requirements.txt` completed in task-service
- [ ] All package.json and requirements.txt up to date

### Docker Images
- [ ] Auth service image built and pushed
- [ ] Task service image built and pushed
- [ ] Frontend image built and pushed
- [ ] Image tags updated in deployment manifests

### Testing
- [ ] Rate limiting tested (login attempts blocked)
- [ ] Password policy enforced (weak passwords rejected)
- [ ] Input validation working (invalid data rejected)
- [ ] CORS protection active (unauthorized origins blocked)
- [ ] Security headers present (verify with curl -I)

### Optional (Recommended)
- [ ] Sealed Secrets implemented (see k8s/SEALED_SECRETS_SETUP.md)
- [ ] TLS/HTTPS certificates configured
- [ ] Monitoring and alerting setup
- [ ] Backup strategy implemented

---

## 🧪 Quick Security Tests

### Test Rate Limiting
```bash
# Should block after 5 attempts
for i in {1..10}; do
  curl -X POST http://your-domain/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{"username":"test","password":"wrong"}'
done
```

### Test Password Policy
```bash
# Should fail - too weak
curl -X POST http://your-domain/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"short"}'

# Should succeed
curl -X POST http://your-domain/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","password":"MySecure123!Pass"}'
```

### Test Security Headers
```bash
curl -I http://your-domain/health | grep -E "(X-|Strict-Transport|Content-Security)"
```

### Test Input Validation
```bash
# Should fail - invalid username
curl -X POST http://your-domain/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"test@user!","password":"MySecure123!Pass"}'
```

---

## 🔧 Common Issues & Solutions

### Issue: "JWT_SECRET not set" error

**Solution:**
```bash
# Verify secret exists
kubectl get secret jwt-secret -n tms-app

# Check if properly referenced in deployment
kubectl describe deployment auth-service -n tms-app | grep JWT_SECRET

# Recreate secret if needed
kubectl delete secret jwt-secret -n tms-app
kubectl apply -f k8s/overlays/production/secrets.yaml
kubectl rollout restart deployment auth-service -n tms-app
```

### Issue: Rate limiting not working

**Solution:**
```bash
# Check if rate limiter is initialized
kubectl logs -n tms-app deployment/auth-service | grep "rate"

# Verify requests from same IP
curl -H "X-Forwarded-For: 1.2.3.4" http://your-domain/api/auth/login
```

### Issue: CORS errors in browser

**Solution:**
```bash
# Check ALLOWED_ORIGINS is set
kubectl get deployment auth-service -n tms-app -o yaml | grep ALLOWED_ORIGINS

# Update if missing
kubectl set env deployment/auth-service -n tms-app \
  ALLOWED_ORIGINS="https://yourdomain.com"
```

### Issue: Password validation too strict

**Solution:**
Edit [services/auth-service/server.js](services/auth-service/server.js#L104-L108):
```javascript
const validatePassword = body('password')
  .isLength({ min: 8 })  // Change from 12 to 8
  .withMessage('Password must be at least 8 characters')
  // Adjust regex if needed
```

---

## 📊 Security Monitoring

### Key Metrics to Watch

1. **Failed Login Attempts**
   ```bash
   kubectl logs -n tms-app deployment/auth-service | grep "Invalid credentials" | wc -l
   ```

2. **Rate Limit Hits**
   ```bash
   kubectl logs -n tms-app deployment/auth-service | grep "Rate limit exceeded" | wc -l
   ```

3. **Input Validation Failures**
   ```bash
   kubectl logs -n tms-app deployment/task-service | grep "ValidationError" | wc -l
   ```

4. **Pod Restarts** (potential security issue indicator)
   ```bash
   kubectl get pods -n tms-app -o wide
   ```

### Set Up Alerts (Recommended)

```yaml
# Example Prometheus alert
- alert: HighFailedLoginRate
  expr: rate(failed_logins_total[5m]) > 10
  annotations:
    summary: "High failed login rate detected"
```

---

## 🆘 Emergency Security Response

### If Credentials Compromised

1. **Immediately rotate secrets:**
   ```bash
   # Generate new JWT secret
   NEW_SECRET=$(openssl rand -base64 32)
   
   # Update secret
   kubectl create secret generic jwt-secret \
     --from-literal=secret=$NEW_SECRET \
     --dry-run=client -o yaml | kubectl apply -f -
   
   # Restart services
   kubectl rollout restart deployment auth-service -n tms-app
   kubectl rollout restart deployment task-service -n tms-app
   ```

2. **Force all users to re-login** (JWT invalidation)

3. **Review access logs:**
   ```bash
   kubectl logs -n tms-app deployment/auth-service --since=24h > auth-audit.log
   ```

4. **Check for unauthorized access:**
   ```bash
   kubectl logs -n tms-app deployment/task-service | grep "401\|403"
   ```

### If Vulnerability Discovered

1. **Isolate affected service:**
   ```bash
   kubectl scale deployment auth-service -n tms-app --replicas=0
   ```

2. **Apply security patch**

3. **Test in staging environment**

4. **Deploy fix:**
   ```bash
   kubectl apply -k k8s/overlays/production/
   ```

5. **Monitor for issues**

---

## 📚 Additional Resources

- [SECURITY_IMPLEMENTATION_SUMMARY.md](SECURITY_IMPLEMENTATION_SUMMARY.md) - Full implementation details
- [k8s/SEALED_SECRETS_SETUP.md](k8s/SEALED_SECRETS_SETUP.md) - Sealed secrets guide
- [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md) - Original security documentation

---

## 🔄 Regular Maintenance

### Weekly
- [ ] Review failed login attempts
- [ ] Check for unusual rate limit hits
- [ ] Monitor error logs for validation failures

### Monthly
- [ ] Update dependencies (npm audit, pip-audit)
- [ ] Review access logs
- [ ] Test disaster recovery procedures

### Quarterly (Every 90 Days)
- [ ] Rotate JWT secrets
- [ ] Rotate database passwords
- [ ] Security audit and penetration testing
- [ ] Review and update security policies
- [ ] Team security training

---

**Last Updated:** January 21, 2026  
**Version:** 2.0.0-secure  
**Maintained by:** DevOps Security Team

import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',  //for external access //
    port: 3000,
    proxy: {
      '/api/auth': {
        target: process.env.AUTH_SERVICE_URL || 'http://auth-service:8001',
        changeOrigin: true
      },
      '/api/tasks': {
        target: process.env.TASK_SERVICE_URL || 'http://task-service:8002',
        changeOrigin: true
      }
    }
  }
})

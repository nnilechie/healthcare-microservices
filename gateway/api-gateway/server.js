const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const cors = require('cors');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(cors());
app.use(express.json());

// Health check
app.get('/health', (req, res) => {
  res.json({ 
    status: 'UP', 
    timestamp: new Date().toISOString(),
    gateway: 'healthcare-api-gateway'
  });
});

// Simple routing
app.use('/api/v1/patients', createProxyMiddleware({
  target: process.env.PATIENT_SERVICE_URL || 'http://patient-service:8081',
  changeOrigin: true,
  pathRewrite: { '^/api/v1/patients': '/api/v1' }
}));

app.use('/api/v1/appointments', createProxyMiddleware({
  target: process.env.APPOINTMENT_SERVICE_URL || 'http://appointment-service:8082',
  changeOrigin: true,
  pathRewrite: { '^/api/v1/appointments': '/api/v1' }
}));

app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});

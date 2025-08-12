const express = require('express');
const { createProxyMiddleware } = require('http-proxy-middleware');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const redis = require('redis');
const winston = require('winston');
const swaggerUi = require('swagger-ui-express');
const YAML = require('yamljs');
const CircuitBreaker = require('circuit-breaker-js');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 8080;

// Redis client for caching and rate limiting
const redisClient = redis.createClient({
  url: `redis://${process.env.REDIS_HOST || 'localhost'}:${process.env.REDIS_PORT || 6379}`
});

// Logger configuration
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'gateway.log' })
  ]
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later.',
  standardHeaders: true,
  legacyHeaders: false,
  store: new (require('express-rate-limit').RedisStore)({
    client: redisClient,
    prefix: 'rl:'
  })
});

app.use(limiter);

// JWT Authentication middleware
const authenticateToken = async (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Access token required' });
  }

  try {
    // Check if token is blacklisted in Redis
    const isBlacklisted = await redisClient.get(`blacklist:${token}`);
    if (isBlacklisted) {
      return res.status(401).json({ error: 'Token is blacklisted' });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'your-secret-key');
    req.user = decoded;
    next();
  } catch (error) {
    logger.error('JWT verification failed:', error);
    return res.status(403).json({ error: 'Invalid token' });
  }
};

// Circuit breaker configuration
const circuitBreakerOptions = {
  windowDuration: 10000, // 10 seconds
  numBuckets: 10,
  timeoutDuration: 5000, // 5 seconds
  errorThreshold: 50, // 50% error rate
  volumeThreshold: 10 // minimum 10 requests
};

// Service URLs
const services = {
  patient: process.env.PATIENT_SERVICE_URL || 'http://localhost:8081',
  appointment: process.env.APPOINTMENT_SERVICE_URL || 'http://localhost:8082',
  medical_records: process.env.MEDICAL_RECORDS_SERVICE_URL || 'http://localhost:8083',
  billing: process.env.BILLING_SERVICE_URL || 'http://localhost:8084',
  telemedicine: process.env.TELEMEDICINE_SERVICE_URL || 'http://localhost:8085',
  inventory: process.env.INVENTORY_SERVICE_URL || 'http://localhost:8086',
  notification: process.env.NOTIFICATION_SERVICE_URL || 'http://localhost:8087',
  analytics: process.env.ANALYTICS_SERVICE_URL || 'http://localhost:8088'
};

// Create circuit breakers for each service
const circuitBreakers = {};
Object.keys(services).forEach(service => {
  circuitBreakers[service] = new CircuitBreaker(circuitBreakerOptions);
});

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = Date.now() - start;
    logger.info({
      method: req.method,
      url: req.url,
      status: res.statusCode,
      duration: `${duration}ms`,
      userAgent: req.get('User-Agent'),
      ip: req.ip
    });
  });
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'UP', 
    timestamp: new Date().toISOString(),
    services: Object.keys(services)
  });
});

// Swagger documentation
const swaggerDocument = YAML.load('./swagger.yaml');
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocument));

// Service proxy configurations
const createServiceProxy = (serviceName, targetUrl, requireAuth = true) => {
  const middleware = [];
  
  if (requireAuth) {
    middleware.push(authenticateToken);
  }

  middleware.push(createProxyMiddleware({
    target: targetUrl,
    changeOrigin: true,
    pathRewrite: {
      [`^/api/v1/${serviceName}`]: '/api/v1'
    },
    onProxyReq: (proxyReq, req, res) => {
      // Add correlation ID for tracing
      const correlationId = req.headers['x-correlation-id'] || 
                           require('crypto').randomUUID();
      proxyReq.setHeader('X-Correlation-ID', correlationId);
      proxyReq.setHeader('X-User-ID', req.user?.sub || 'anonymous');
    },
    onProxyRes: (proxyRes, req, res) => {
      // Add security headers
      proxyRes.headers['X-Content-Type-Options'] = 'nosniff';
      proxyRes.headers['X-Frame-Options'] = 'DENY';
    },
    onError: (err, req, res) => {
      logger.error(`Proxy error for ${serviceName}:`, err);
      circuitBreakers[serviceName].recordFailure();
      res.status(503).json({ 
        error: 'Service temporarily unavailable',
        service: serviceName 
      });
    }
  }));

  return middleware;
};

// Route definitions
app.use('/api/v1/patients', createServiceProxy('patients', services.patient));
app.use('/api/v1/appointments', createServiceProxy('appointments', services.appointment));
app.use('/api/v1/medical-records', createServiceProxy('medical-records', services.medical_records));
app.use('/api/v1/billing', createServiceProxy('billing', services.billing));
app.use('/api/v1/telemedicine', createServiceProxy('telemedicine', services.telemedicine));
app.use('/api/v1/inventory', createServiceProxy('inventory', services.inventory));
app.use('/api/v1/notifications', createServiceProxy('notifications', services.notification));
app.use('/api/v1/analytics', createServiceProxy('analytics', services.analytics));

// Authentication routes
app.post('/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    // Here you would validate credentials against your auth service
    // For demo purposes, using hardcoded validation
    if (username === 'admin' && password === 'password') {
      const token = jwt.sign(
        { 
          sub: username, 
          role: 'admin',
          permissions: ['read', 'write', 'delete']
        },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: '8h' }
      );
      
      res.json({ 
        token, 
        expiresIn: 28800, // 8 hours
        user: { username, role: 'admin' }
      });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  } catch (error) {
    logger.error('Login error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.post('/auth/logout', authenticateToken, async (req, res) => {
  try {
    const token = req.headers['authorization'].split(' ')[1];
    // Add token to blacklist
    await redisClient.setEx(`blacklist:${token}`, 28800, 'true'); // 8 hours TTL
    res.json({ message: 'Logged out successfully' });
  } catch (error) {
    logger.error('Logout error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Error handling middleware
app.use((error, req, res, next) => {
  logger.error('Unhandled error:', error);
  res.status(500).json({ 
    error: 'Internal server error',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({ 
    error: 'Endpoint not found',
    path: req.originalUrl
  });
});

// Start server
const startServer = async () => {
  try {
    await redisClient.connect();
    logger.info('Connected to Redis');
    
    app.listen(PORT, () => {
      logger.info(`API Gateway running on port ${PORT}`);
      logger.info(`Swagger documentation available at http://localhost:${PORT}/api-docs`);
    });
  } catch (error) {
    logger.error('Failed to start server:', error);
    process.exit(1);
  }
};

startServer();

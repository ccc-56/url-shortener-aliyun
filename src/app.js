
import express from 'express'
import urlRoutes from './routes/urlRoutes.js'
import { limiter } from './middleware/rateLimiter.js';
import path from 'path'
import { redirectUrl } from './controllers/urlController.js';




const app = express();
app.set('trust proxy', true);
app.use(express.json());
// app.use(express.static(path.resolve('public')));
app.use('/api', urlRoutes);

// Redirect
app.get('/r/:code', redirectUrl);

export default app

// src/routes/auth.js
const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { validateRegister, validateLogin } = require('../middleware/validation');
const { authenticateToken } = require('../middleware/auth');

// Kullanıcı kaydı
router.post('/register', validateRegister, authController.register);

// Kullanıcı girişi
router.post('/login', validateLogin, authController.login);

// Token yenileme
router.post('/refresh-token', authController.refreshToken);

// Kullanıcı profili (korumalı route)
router.get('/profile', authenticateToken, authController.getProfile);

module.exports = router;
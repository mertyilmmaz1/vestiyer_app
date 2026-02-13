const express = require('express');
const router = express.Router();
const combinationController = require('../controllers/combinationController');
const { authenticateToken } = require('../middleware/auth');

// Tüm combination routes korumalı
router.use(authenticateToken);

// Mobil için: Kombin önerileri oluştur (POST /api/combinations/generate)
router.post('/generate', combinationController.generateCombinationsSimple);

// Kullanıcının mevcut kombinlerini getir (GET /api/combinations/user/:userId)
router.get('/user/:userId', combinationController.getUserCombinations);

// Kombin kıyafetlerinin detaylarını getir (POST /api/combinations/clothing-details)
router.post('/clothing-details', combinationController.getCombinationClothingDetails);

module.exports = router; 
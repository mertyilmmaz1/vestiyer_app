const express = require('express');
const router = express.Router();
const clothingController = require('../controllers/clothingController');
const fileService = require('../services/fileService');
const { authenticateToken } = require('../middleware/auth');

// Mobil için: Multipart Form Data ile fotoğraf upload ve analiz
router.post('/analyze-and-add', fileService.getUploadMiddleware(), clothingController.analyzeAndAddClothingMultipart);

// Mevsim bazlı endpoint'ler
router.get('/:userId', clothingController.getAllClothing); // Query params ile filtreleme
router.get('/:userId/season', clothingController.getClothingBySeason); // ?season=spring
router.get('/:userId/current-season', clothingController.getCurrentSeasonClothing);
router.get('/:userId/statistics', clothingController.getSeasonStatistics);

module.exports = router; 
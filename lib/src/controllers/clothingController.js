const Clothing = require('../models/Clothing');
const fileService = require('../services/fileService');
const aiService = require('../services/aiService');
const path = require('path');
const fs = require('fs');

// Helper functions - defined outside class for better context handling
const mapMainGroupToCategory = (mainGroup) => {
  const mapping = {
    'üst giyim': 'top',
    'alt giyim': 'bottom',
    'dış giyim': 'outerwear',
    'ayakkabı': 'shoes',
    'aksesuar': 'accessory'
  };
  return mapping[mainGroup] || 'top';
};



class ClothingController {

  // Mobil için: Multipart Form Data ile fotoğraf upload ve analiz
  async analyzeAndAddClothingMultipart(req, res) {
    try {
      console.log('Request body:', req.body);
      console.log('Request file:', req.file);
      console.log('Request headers:', req.headers);
      
      // UserId'yi body'den veya auth token'dan al
      const userId = req.body?.userId || req.user?.id;
      const imageFile = req.file;
      
      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur. Body\'de userId gönderin veya auth token\'da user bilgisi bulunmalı.',
          receivedBody: req.body,
          receivedUser: req.user
        });
      }

      if (!imageFile || !imageFile.buffer) {
        return res.status(400).json({
          success: false,
          message: 'Image dosyası zorunludur.',
          receivedFile: imageFile ? {
            fieldname: imageFile.fieldname,
            originalname: imageFile.originalname,
            mimetype: imageFile.mimetype,
            size: imageFile.size,
            hasBuffer: !!imageFile.buffer
          } : null
        });
      }

      // 1. Dosyayı kaydet
      const saveResult = fileService.saveImageFile(
        imageFile.buffer, 
        userId, 
        imageFile.originalname
      );
      
      if (!saveResult.success) {
        return res.status(500).json({
          success: false,
          message: 'Dosya kaydedilemedi',
          error: saveResult.error
        });
      }

      // 2. Base64'e çevir (AI analiz için)
      const base64Image = imageFile.buffer.toString('base64');
      
      // 3. OpenAI ile analiz et
      const aiResult = await aiService.analyzeClothingAdvanced(base64Image);
      console.log('AI Result:', JSON.stringify(aiResult, null, 2));
      
      if (!aiResult.success) {
        return res.status(500).json({
          success: false,
          message: 'AI analiz başarısız',
          error: aiResult.error || 'Bilinmeyen hata'
        });
      }

      // 4. AI analiz sonuçlarını işle ve normalize et
      const mainGroup = aiResult.parsedAnalysis?.mainGroup || 'üst giyim';
      const category = aiResult.parsedAnalysis?.category || 'Genel';
      const season = aiResult.parsedAnalysis?.season || 'all-season';
      
      // Renk bilgisini normalize et (Flutter için uyumlu hale getir)
      const colorInfo = aiResult.parsedAnalysis?.color || 'Belirsiz';
      const colors = colorInfo.includes(',') ? 
        colorInfo.split(',').map(c => c.trim()) : 
        [colorInfo];

      // 5. Kıyafet objesini oluştur ve kaydet
      const clothing = new Clothing({
        userId,
        title: category || 'AI Analiz Edilen Kıyafet',
        category: mapMainGroupToCategory(mainGroup),
        imageUrl: saveResult.url,
        imagePath: saveResult.filepath,
        colors: colors, // Flutter için renk array'i
        tags: [], // Boş array olarak başlat
        isFavorite: false,
        advancedAnalysis: {
          mainGroup: mainGroup,
          category: category,
          color: colorInfo, // Orijinal renk bilgisi
          material: aiResult.parsedAnalysis?.material || 'Belirsiz',
          style: aiResult.parsedAnalysis?.style || 'Genel',
          season: season,
          details: aiResult.parsedAnalysis?.details || 'AI analizi tamamlanamadı',
          rawAnalysis: aiResult.rawAnalysis,
          confidence: 0.85
        },
        apiUsage: {
          promptTokens: aiResult.usage.prompt_tokens,
          completionTokens: aiResult.usage.completion_tokens,
          totalCost: aiResult.usage.total_cost,
          model: 'gpt-4o',
          analyzedAt: new Date()
        }
      });
      await clothing.save();

      res.status(201).json({
        success: true,
        message: 'Kıyafet başarıyla analiz edildi ve kaydedildi',
        data: clothing,
        analysis: aiResult.rawAnalysis,
        formatted_analysis: aiResult.formattedAnalysis,
        season: season,
        usage: aiResult.usage
      });
    } catch (error) {
      console.error('analyzeAndAddClothingSimple error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Belirli mevsime göre kıyafetleri getir
  async getClothingBySeason(req, res) {
    try {
      const { userId } = req.params;
      const { season } = req.query;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur'
        });
      }

      if (!season || !['spring', 'summer', 'autumn', 'winter', 'all-season'].includes(season)) {
        return res.status(400).json({
          success: false,
          message: 'Geçerli bir mevsim belirtilmelidir (spring, summer, autumn, winter, all-season)'
        });
      }

      const clothing = await Clothing.findBySeason(userId, season)
        .sort({ createdAt: -1 })
        .select('-apiUsage'); // API kullanım bilgilerini gizle

      res.status(200).json({
        success: true,
        message: `${season} mevsimi için kıyafetler getirildi`,
        season: season,
        count: clothing.length,
        data: clothing
      });
    } catch (error) {
      console.error('getClothingBySeason error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Mevcut mevsime göre kıyafetleri getir
  async getCurrentSeasonClothing(req, res) {
    try {
      const { userId } = req.params;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur'
        });
      }

      const currentSeason = Clothing.getCurrentSeason();
      const clothing = await Clothing.findBySeason(userId, currentSeason)
        .sort({ createdAt: -1 })
        .select('-apiUsage');

      res.status(200).json({
        success: true,
        message: `Mevcut mevsim (${currentSeason}) için kıyafetler getirildi`,
        currentSeason: currentSeason,
        count: clothing.length,
        data: clothing
      });
    } catch (error) {
      console.error('getCurrentSeasonClothing error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Tüm kıyafetleri getir (mevsim filtreleme seçeneği ile)
  async getAllClothing(req, res) {
    try {
      const { userId } = req.params;
      const { season, category, style } = req.query;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur'
        });
      }

      let query = { userId };

      // Mevsim filtresi
      if (season && season !== 'all') {
        if (['spring', 'summer', 'autumn', 'winter', 'all-season'].includes(season)) {
          query.$or = [
            { 'advancedAnalysis.season': season },
            { 'advancedAnalysis.season': 'all-season' }
          ];
        }
      }

      // Kategori filtresi
      if (category && category !== 'all') {
        query.category = category;
      }

      // Stil filtresi
      if (style && style !== 'all') {
        query['advancedAnalysis.style'] = new RegExp(style, 'i');
      }

      const clothing = await Clothing.find(query)
        .sort({ createdAt: -1 })
        .select('-apiUsage');

      res.status(200).json({
        success: true,
        message: 'Kıyafetler getirildi',
        filters: { season, category, style },
        count: clothing.length,
        data: clothing
      });
    } catch (error) {
      console.error('getAllClothing error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Mevsim istatistikleri
  async getSeasonStatistics(req, res) {
    try {
      const { userId } = req.params;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur'
        });
      }

      const stats = await Clothing.aggregate([
        { $match: { userId: require('mongoose').Types.ObjectId(userId) } },
        {
          $group: {
            _id: '$advancedAnalysis.season',
            count: { $sum: 1 },
            categories: { $addToSet: '$category' }
          }
        },
        { $sort: { count: -1 } }
      ]);

      const currentSeason = Clothing.getCurrentSeason();

      res.status(200).json({
        success: true,
        message: 'Mevsim istatistikleri getirildi',
        currentSeason: currentSeason,
        statistics: stats
      });
    } catch (error) {
      console.error('getSeasonStatistics error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }
}

module.exports = new ClothingController(); 
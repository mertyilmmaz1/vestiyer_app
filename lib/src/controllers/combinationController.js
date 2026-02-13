const Clothing = require('../models/Clothing');
const Combination = require('../models/Combination');
const aiService = require('../services/aiService');

class CombinationController {
  // Helper function to select diverse clothing items
  async selectDiverseClothing(userId, clothingItems, forceGenerate = false) {
    try {
      // Get recent combinations to avoid repetition
      const recentCombinations = await Combination.find({ userId })
        .sort({ createdAt: -1 })
        .limit(10);

      // Select diverse items from different categories
      const diversityConstraints = {
        minItemsPerCategory: 1,
        maxItemsPerCategory: 3,
        preferredStyles: ['casual', 'formal', 'sport'],
        preferredSeasons: ['spring', 'summer', 'autumn', 'winter', 'all-season']
      };

      return {
        selectedItems: clothingItems,
        diversityConstraints,
        recentCombinations: recentCombinations || []
      };
    } catch (error) {
      console.error('selectDiverseClothing error:', error);
      return {
        selectedItems: clothingItems,
        diversityConstraints: {},
        recentCombinations: []
      };
    }
  }

  // Helper function to save combinations
  async saveCombinations(userId, combinations) {
    try {
      const savedCombinations = [];
      for (const combo of combinations) {
        const combination = new Combination({
          userId,
          items: combo.items || [],
          description: combo.description || 'AI Oluşturulan Kombin',
          occasion: combo.occasion || 'Günlük',
          season: combo.season || 'all-season',
          aiGenerated: true,
          confidence: combo.confidence || 0.8
        });
        
        const saved = await combination.save();
        savedCombinations.push(saved);
      }
      
      return savedCombinations;
    } catch (error) {
      console.error('saveCombinations error:', error);
      return [];
    }
  }

  // Mobil için: Kullanıcının kıyafetlerinden çeşitli kombin önerileri oluştur
  async generateCombinationsSimple(req, res) {
    try {
      const { userId, forceGenerate = false } = req.body;
      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur.'
        });
      }

      // 1. Kullanıcının kıyafetlerini getir
      const clothingItems = await Clothing.find({ userId }).sort({ createdAt: -1 });

      if (!clothingItems || clothingItems.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz.'
        });
      }

      // 2. Çeşitlilik için akıllı kıyafet seçimi
      const diverseClothingSelection = await this.selectDiverseClothing(userId, clothingItems, forceGenerate);

      // 3. OpenAI ile kombin önerileri oluştur
      const combinationResult = await aiService.generateCombinations(
        diverseClothingSelection.selectedItems
      );

      if (!combinationResult.success) {
        return res.status(500).json({
          success: false,
          message: 'Kombin önerileri oluşturulurken hata oluştu',
          error: combinationResult.error || 'Bilinmeyen hata'
        });
      }

      // 4. Oluşturulan kombinleri veritabanına kaydet
      const savedCombinations = await this.saveCombinations(userId, combinationResult.combinations);

      res.status(200).json({
        success: true,
        message: 'Çeşitli kombin önerileri başarıyla oluşturuldu',
        data: {
          savedCombinations: savedCombinations, // Flutter için ana kombinler
          combinations: combinationResult.combinations, // AI'dan gelen ham kombinler
          totalItems: clothingItems.length,
          usedItems: diverseClothingSelection.selectedItems.length,
          diversityScore: diverseClothingSelection.diversityScore,
          suggestions: combinationResult.rawResponse,
          parsed_outfits: combinationResult.parsed_outfits
        },
        usage: combinationResult.usage
      });

    } catch (error) {
      console.error('generateCombinationsSimple error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Çeşitlilik için akıllı kıyafet seçimi
  async selectDiverseClothing(userId, allClothingItems, forceGenerate = false) {
    try {
      // Geçmiş kombinleri al (son 30 gün)
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const recentCombinations = await Combination.find({
        userId: userId,
        createdAt: { $gte: thirtyDaysAgo }
      }).populate('clothingItems.clothingId');

      // Son kombinlerde kullanılan kıyafetleri say
      const usageCount = {};
      const recentlyUsedItems = new Set();

      recentCombinations.forEach(combination => {
        combination.clothingItems.forEach(item => {
          if (item.clothingId) {
            const itemId = item.clothingId._id.toString();
            usageCount[itemId] = (usageCount[itemId] || 0) + 1;
            recentlyUsedItems.add(itemId);
          }
        });
      });

      // Kıyafetleri kategorilere ayır
      const categorizedItems = {
        top: [],
        bottom: [],
        outerwear: [],
        shoes: [],
        accessory: []
      };

      allClothingItems.forEach(item => {
        if (categorizedItems[item.category]) {
          const itemId = item._id.toString();
          const usageFrequency = usageCount[itemId] || 0;
          const wasRecentlyUsed = recentlyUsedItems.has(itemId);
          
          categorizedItems[item.category].push({
            ...item.toObject(),
            usageFrequency,
            wasRecentlyUsed,
            diversityScore: this.calculateDiversityScore(item, usageFrequency, wasRecentlyUsed)
          });
        }
      });

      // Her kategoriden çeşitli kıyafetler seç
      const selectedItems = [];
      const diversityConstraints = [];

      // Öncelik sırası: az kullanılan kıyafetler
      Object.keys(categorizedItems).forEach(category => {
        const items = categorizedItems[category];
        
        if (items.length > 0) {
          // Çeşitlilik skoruna göre sırala
          items.sort((a, b) => b.diversityScore - a.diversityScore);
          
          // Her kategoriden en fazla 6 kıyafet seç (çeşitlilik için)
          const maxItemsPerCategory = Math.min(6, items.length);
          const selectedFromCategory = items.slice(0, maxItemsPerCategory);
          
          selectedItems.push(...selectedFromCategory);
          
          // Az kullanılan kıyafetler varsa onları öncelikle kullan
          const underusedItems = selectedFromCategory.filter(item => item.usageFrequency <= 1);
          if (underusedItems.length > 0) {
            diversityConstraints.push({
              type: 'prioritize_underused',
              category: category,
              items: underusedItems.map(item => item._id.toString())
            });
          }
        }
      });

      // Çeşitlilik skoru hesapla
      const totalItems = allClothingItems.length;
      const uniqueRecentItems = recentlyUsedItems.size;
      const diversityScore = totalItems > 0 ? 
        Math.round(((totalItems - uniqueRecentItems) / totalItems) * 100) : 100;

      return {
        selectedItems: selectedItems,
        diversityConstraints: diversityConstraints,
        recentCombinations: recentCombinations.slice(0, 5), // Son 5 kombin
        diversityScore: diversityScore,
        stats: {
          totalItems: totalItems,
          recentlyUsedItems: uniqueRecentItems,
          categoryCounts: Object.keys(categorizedItems).map(cat => ({
            category: cat,
            total: categorizedItems[cat].length,
            selected: categorizedItems[cat].slice(0, Math.min(6, categorizedItems[cat].length)).length
          }))
        }
      };

    } catch (error) {
      console.error('selectDiverseClothing error:', error);
      throw new Error('Çeşitli kıyafet seçimi hatası: ' + error.message);
    }
  }

  // Çeşitlilik skoru hesaplama
  calculateDiversityScore(item, usageFrequency, wasRecentlyUsed) {
    let score = 100; // Başlangıç skoru

    // Kullanım sıklığına göre puan azalt
    score -= (usageFrequency * 15); // Her kullanım için -15 puan

    // Son zamanlarda kullanıldıysa puan azalt
    if (wasRecentlyUsed) {
      score -= 25;
    }

    // Renk çeşitliliği için bonus (farklı renkler daha yüksek skor)
    if (item.colors && item.colors.length > 1) {
      score += 10;
    }

    // Stil çeşitliliği için bonus
    if (item.advancedAnalysis?.style && 
        !['basic', 'casual', 'günlük'].includes(item.advancedAnalysis.style.toLowerCase())) {
      score += 5;
    }

    return Math.max(0, score); // Minimum 0 puan
  }

  // Kombinleri veritabanına kaydet
  async saveCombinations(userId, combinations) {
    try {
      const savedCombinations = [];

      for (const combination of combinations) {
        // Kıyafet ID'lerini doğrula
        const validClothingItems = [];
        
        for (const itemId of combination.items) {
          const clothing = await Clothing.findOne({ _id: itemId, userId: userId });
          if (clothing) {
            validClothingItems.push({
              clothingId: itemId,
              category: clothing.category,
              isRequired: true
            });
          }
        }

        if (validClothingItems.length >= 2) { // En az 2 kıyafet gerekli
          const newCombination = new Combination({
            userId: userId,
            name: combination.name,
            description: combination.description,
            occasion: combination.occasion,
            season: this.mapSeasonToEnum(combination.season),
            clothingItems: validClothingItems,
            isAIGenerated: true,
            aiGeneration: {
              prompt: 'diversity_optimized_generation',
              model: 'gpt-4o-mini',
              generatedAt: new Date(),
              confidence: 0.8
            },
            tags: this.extractTagsFromDescription(combination.description)
          });

          const savedCombination = await newCombination.save();
          savedCombinations.push(savedCombination);
        }
      }

      return savedCombinations;

    } catch (error) {
      console.error('saveCombinations error:', error);
      throw new Error('Kombin kaydetme hatası: ' + error.message);
    }
  }

  // Sezon adını enum'a çevir
  mapSeasonToEnum(seasonText) {
    if (!seasonText) return 'all-season';
    
    const season = seasonText.toLowerCase();
    if (season.includes('yaz') || season.includes('summer')) return 'summer';
    if (season.includes('kış') || season.includes('winter')) return 'winter';
    if (season.includes('ilkbahar') || season.includes('spring')) return 'spring';
    if (season.includes('sonbahar') || season.includes('autumn') || season.includes('fall')) return 'autumn';
    
    return 'all-season';
  }

  // Açıklamadan etiket çıkar
  extractTagsFromDescription(description) {
    if (!description) return [];
    
    const tags = [];
    const text = description.toLowerCase();
    
    // Stil etiketleri
    if (text.includes('casual') || text.includes('günlük')) tags.push('casual');
    if (text.includes('formal') || text.includes('resmi')) tags.push('formal');
    if (text.includes('spor') || text.includes('sport')) tags.push('sport');
    if (text.includes('şık') || text.includes('elegant')) tags.push('elegant');
    if (text.includes('rahat') || text.includes('comfortable')) tags.push('comfortable');
    
    return tags;
  }

  // Kullanıcının mevcut kombinlerini getir
  async getUserCombinations(req, res) {
    try {
      const { userId } = req.params;
      const { page = 1, limit = 10, occasion, isFavorite } = req.query;

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur.'
        });
      }

      // Filtre oluştur
      const filter = { userId };
      if (occasion) filter.occasion = occasion;
      if (isFavorite !== undefined) filter.isFavorite = isFavorite === 'true';

      // Sayfalama
      const skip = (page - 1) * limit;

      const combinations = await Combination.find(filter)
        .populate('clothingItems.clothingId')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));

      const totalCombinations = await Combination.countDocuments(filter);

      res.status(200).json({
        success: true,
        message: 'Kombinler başarıyla getirildi',
        data: {
          combinations: combinations,
          totalCombinations: totalCombinations,
          currentPage: parseInt(page),
          totalPages: Math.ceil(totalCombinations / limit),
          hasNextPage: skip + combinations.length < totalCombinations
        }
      });

    } catch (error) {
      console.error('getUserCombinations error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }

  // Kombin için seçilen kıyafetlerin detaylarını getir
  async getCombinationClothingDetails(req, res) {
    try {
      const { clothingIds, userId } = req.body;

      // Validation
      if (!clothingIds || !Array.isArray(clothingIds) || clothingIds.length === 0) {
        return res.status(400).json({
          success: false,
          message: 'clothingIds array zorunludur ve en az bir ID içermelidir.'
        });
      }

      if (!userId) {
        return res.status(400).json({
          success: false,
          message: 'userId zorunludur.'
        });
      }

      // Kıyafetleri getir - userId ile güvenlik kontrolü yapıyoruz
      const clothingItems = await Clothing.find({
        _id: { $in: clothingIds },
        userId: userId
      }).select('-__v'); // __v field'ını hariç tut

      // Bulunamayan ID'leri kontrol et
      const foundIds = clothingItems.map(item => item._id.toString());
      const notFoundIds = clothingIds.filter(id => !foundIds.includes(id));

      res.status(200).json({
        success: true,
        message: 'Kıyafet detayları başarıyla getirildi',
        data: {
          clothingItems: clothingItems,
          totalFound: clothingItems.length,
          totalRequested: clothingIds.length,
          notFoundIds: notFoundIds.length > 0 ? notFoundIds : undefined
        }
      });

    } catch (error) {
      console.error('getCombinationClothingDetails error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası',
        error: error.message
      });
    }
  }
}

module.exports = new CombinationController(); 
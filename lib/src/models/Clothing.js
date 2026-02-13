const mongoose = require('mongoose');

const clothingSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  title: { 
    type: String, 
    required: true,
    trim: true
  },
  category: { 
    type: String, 
    required: true,
    enum: ['top', 'bottom', 'shoes', 'accessory', 'outerwear']
  },
  imageUrl: { 
    type: String, 
    required: true 
  },
  imagePath: {
    type: String,
    required: true
  },
  // Gelişmiş AI analiz sonuçları (AI'dan gelen değişken değerler için esnek)
  advancedAnalysis: {
    mainGroup: String, // AI'dan gelen ana grup (enum kaldırıldı)
    category: String, // AI'ın belirlediği detaylı kategori
    color: String, // AI renk analizi
    material: String, // Kumaş/malzeme türü
    style: String, // Stil (casual, formal, vb.)
    season: String, // AI'dan gelen mevsim bilgisi (enum kaldırıldı)
    details: String, // Detaylı açıklama - ana odak bu
    rawAnalysis: String, // AI'ın ham yanıtı
    confidence: {
      type: Number,
      min: 0,
      max: 1
    }
  },
  // Basit AI analizi (backward compatibility - enum kısıtlamaları kaldırıldı)
  aiAnalysis: {
    description: String,
    style: String, // AI'dan gelen stil bilgisi
    season: [String], // AI'dan gelen mevsim bilgileri
    occasion: [String], // AI'dan gelen kullanım alanları
    confidence: {
      type: Number,
      min: 0,
      max: 1
    }
  },
  // API kullanım maliyeti tracking
  apiUsage: {
    promptTokens: Number,
    completionTokens: Number,
    totalCost: Number,
    model: {
      type: String,
      default: 'gpt-4-vision-preview'
    },
    analyzedAt: Date
  },
  tags: [String],
  isFavorite: {
    type: Boolean,
    default: false
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Update the updatedAt field before saving
clothingSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for faster queries - mevsim bazlı sorgular için optimize edildi
clothingSchema.index({ userId: 1 });
clothingSchema.index({ category: 1 });
clothingSchema.index({ 'aiAnalysis.style': 1 });
clothingSchema.index({ 'advancedAnalysis.mainGroup': 1 });
clothingSchema.index({ 'advancedAnalysis.style': 1 });
clothingSchema.index({ 'advancedAnalysis.season': 1 }); // Mevsim bazlı sorgular için yeni index

// Method to get AI analysis summary
clothingSchema.methods.getAnalysisSummary = function() {
  if (this.advancedAnalysis && this.advancedAnalysis.mainGroup) {
    return {
      type: 'advanced',
      data: this.advancedAnalysis
    };
  } else if (this.aiAnalysis && this.aiAnalysis.description) {
    return {
      type: 'basic',
      data: this.aiAnalysis
    };
  }
  return null;
};

// Mevsim bazlı filtreleme için static method
clothingSchema.statics.findBySeason = function(userId, season) {
  return this.find({
    userId: userId,
    $or: [
      { 'advancedAnalysis.season': season },
      { 'advancedAnalysis.season': 'all-season' }
    ]
  });
};

// Mevcut mevsimi otomatik belirlemek için helper method
clothingSchema.statics.getCurrentSeason = function() {
  const month = new Date().getMonth() + 1; // 1-12
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
};

module.exports = mongoose.model('Clothing', clothingSchema); 
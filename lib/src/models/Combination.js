const mongoose = require('mongoose');

const combinationSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  name: { 
    type: String, 
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  occasion: {
    type: String,
    enum: ['daily', 'work', 'party', 'formal', 'casual', 'sport', 'date', 'travel'],
    default: 'casual'
  },
  season: {
    type: String,
    enum: ['spring', 'summer', 'autumn', 'winter', 'all-season'],
    default: 'all-season'
  },
  clothingItems: [{
    clothingId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Clothing',
      required: true
    },
    category: {
      type: String,
      enum: ['top', 'bottom', 'shoes', 'accessory', 'outerwear']
    },
    isRequired: {
      type: Boolean,
      default: true
    }
  }],
  // AI tarafından üretildi mi?
  isAIGenerated: {
    type: Boolean,
    default: false
  },
  // AI generation bilgileri
  aiGeneration: {
    prompt: String,
    model: String,
    generatedAt: Date,
    confidence: Number
  },
  // Kullanıcı etkileşimleri
  isFavorite: {
    type: Boolean,
    default: false
  },
  rating: {
    type: Number,
    min: 1,
    max: 5
  },
  timesWorn: {
    type: Number,
    default: 0
  },
  lastWorn: Date,
  tags: [String],
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
combinationSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

// Index for faster queries
combinationSchema.index({ userId: 1 });
combinationSchema.index({ occasion: 1 });
combinationSchema.index({ season: 1 });
combinationSchema.index({ isFavorite: 1 });
combinationSchema.index({ isAIGenerated: 1 });

// Method to get combination summary
combinationSchema.methods.getSummary = function() {
  return {
    id: this._id,
    name: this.name,
    occasion: this.occasion,
    season: this.season,
    itemsCount: this.clothingItems.length,
    isFavorite: this.isFavorite,
    rating: this.rating,
    timesWorn: this.timesWorn
  };
};

// Method to check if combination is complete
combinationSchema.methods.isComplete = function() {
  const requiredCategories = ['top', 'bottom'];
  const presentCategories = this.clothingItems.map(item => item.category);
  
  return requiredCategories.every(category => 
    presentCategories.includes(category)
  );
};

module.exports = mongoose.model('Combination', combinationSchema); 
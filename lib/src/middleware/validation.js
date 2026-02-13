const validateRegister = (req, res, next) => {
  const { email, password, firstName, lastName } = req.body;

  // Email kontrolü
  if (!email || !email.includes('@')) {
    return res.status(400).json({
      success: false,
      message: 'Geçerli bir email adresi girin'
    });
  }

  // Şifre kontrolü
  if (!password || password.length < 6) {
    return res.status(400).json({
      success: false,
      message: 'Şifre en az 6 karakter olmalı'
    });
  }

  // İsim kontrolü
  if (!firstName || firstName.trim().length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Geçerli bir isim girin'
    });
  }

  if (!lastName || lastName.trim().length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Geçerli bir soyisim girin'
    });
  }

  next();
};

const validateLogin = (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email ve şifre gerekli'
    });
  }

  next();
};

const validateClothingUpload = (req, res, next) => {
  const { title, category } = req.body;

  if (!title || title.trim().length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Kıyafet başlığı en az 2 karakter olmalı'
    });
  }

  const validCategories = ['top', 'bottom', 'shoes', 'accessory', 'outerwear'];
  if (!category || !validCategories.includes(category)) {
    return res.status(400).json({
      success: false,
      message: `Kategori şunlardan biri olmalı: ${validCategories.join(', ')}`
    });
  }

  next();
};

const validateClothingUpdate = (req, res, next) => {
  const { title, category } = req.body;

  if (title && title.trim().length < 2) {
    return res.status(400).json({
      success: false,
      message: 'Kıyafet başlığı en az 2 karakter olmalı'
    });
  }

  const validCategories = ['top', 'bottom', 'shoes', 'accessory', 'outerwear'];
  if (category && !validCategories.includes(category)) {
    return res.status(400).json({
      success: false,
      message: `Kategori şunlardan biri olmalı: ${validCategories.join(', ')}`
    });
  }

  next();
};

const validateAIAnalysis = (req, res, next) => {
  const { base64Image } = req.body;

  if (!base64Image) {
    return res.status(400).json({
      success: false,
      message: 'Base64 image gerekli'
    });
  }

  // Base64 formatını kontrol et
  const base64Regex = /^[A-Za-z0-9+/]*={0,2}$/;
  if (!base64Regex.test(base64Image)) {
    return res.status(400).json({
      success: false,
      message: 'Geçersiz base64 format'
    });
  }

  // Boyut kontrolü (yaklaşık 5MB limit)
  if (base64Image.length > 7000000) { // ~5MB in base64
    return res.status(400).json({
      success: false,
      message: 'Image çok büyük, maksimum 5MB'
    });
  }

  next();
};

module.exports = {
  validateRegister,
  validateLogin,
  validateClothingUpload,
  validateClothingUpdate,
  validateAIAnalysis
}; 
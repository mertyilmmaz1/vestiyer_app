const jwtService = require('../services/jwtService');
const User = require('../models/User');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token gerekli'
      });
    }

    // Token'ın süresini kontrol et
    if (jwtService.isTokenExpired(token)) {
      return res.status(401).json({
        success: false,
        message: 'Access token süresi dolmuş',
        code: 'TOKEN_EXPIRED'
      });
    }

    const decoded = jwtService.verifyAccessToken(token);
    const user = await User.findById(decoded.userId);

    if (!user || user.isActive === false) {
      return res.status(401).json({
        success: false,
        message: 'Gecersiz token veya kullanici'
      });
    }

    req.user = user;
    next();
  } catch (error) {
    return res.status(403).json({
      success: false,
      message: 'Token dogrulanamadi'
    });
  }
};

module.exports = { authenticateToken }; 
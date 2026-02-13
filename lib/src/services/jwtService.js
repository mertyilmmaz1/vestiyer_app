const jwt = require('jsonwebtoken');

class JWTService {
  // Access Token oluştur (uzun süreli - 1 yıl)
  generateAccessToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: '365d' // 1 yıl
    });
  }

  // Refresh Token oluştur (çok uzun süreli - 2 yıl)
  generateRefreshToken(payload) {
    return jwt.sign(payload, process.env.JWT_SECRET, {
      expiresIn: '730d' // 2 yıl
    });
  }

  // Eski token oluştur (geriye uyumluluk için)
  generateToken(payload) {
    return this.generateAccessToken(payload);
  }

  // Access Token doğrula
  verifyAccessToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Access token expired or invalid');
    }
  }

  // Refresh Token doğrula
  verifyRefreshToken(token) {
    try {
      return jwt.verify(token, process.env.JWT_SECRET);
    } catch (error) {
      throw new Error('Refresh token expired or invalid');
    }
  }

  // Token doğrula (geriye uyumluluk için)
  verifyToken(token) {
    return this.verifyAccessToken(token);
  }

  // Token'dan user ID al
  getUserIdFromToken(token) {
    try {
      const decoded = this.verifyToken(token);
      return decoded.userId;
    } catch (error) {
      return null;
    }
  }

  // Refresh Token'dan user ID al
  getUserIdFromRefreshToken(token) {
    try {
      const decoded = this.verifyRefreshToken(token);
      return decoded.userId;
    } catch (error) {
      return null;
    }
  }

  // Token süresini kontrol et
  isTokenExpired(token) {
    try {
      const decoded = jwt.decode(token);
      if (!decoded || !decoded.exp) return true;
      
      const currentTime = Math.floor(Date.now() / 1000);
      return decoded.exp < currentTime;
    } catch (error) {
      return true;
    }
  }

  // Token yenileme
  async refreshAccessToken(refreshToken) {
    try {
      const decoded = this.verifyRefreshToken(refreshToken);
      
      // Yeni access token oluştur
      const newAccessToken = this.generateAccessToken({
        userId: decoded.userId,
        email: decoded.email
      });

      return {
        success: true,
        accessToken: newAccessToken,
        refreshToken: refreshToken, // Aynı refresh token'ı kullan
        expiresIn: '365d'
      };
    } catch (error) {
      return {
        success: false,
        error: error.message
      };
    }
  }
}

module.exports = new JWTService(); 
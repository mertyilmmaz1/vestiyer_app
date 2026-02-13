const User = require('../models/User');
const jwtService = require('../services/jwtService');

class AuthController {
  // Kullanıcı kaydı
  async register(req, res) {
    try {
      const { email, password, firstName, lastName } = req.body;

      // Email zaten kullanılıyor mu?
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Bu email adresi zaten kullanılıyor'
        });
      }

      // Yeni kullanıcı oluştur
      const user = new User({
        email,
        password,
        firstName,
        lastName
      });

      await user.save();

      // Access ve Refresh Token oluştur
      const accessToken = jwtService.generateAccessToken({ 
        userId: user._id, 
        email: user.email 
      });
      const refreshToken = jwtService.generateRefreshToken({ 
        userId: user._id, 
        email: user.email 
      });

      res.status(201).json({
        success: true,
        message: 'Kullanıcı başarıyla oluşturuldu',
        data: {
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: '365d'
        }
      });

    } catch (error) {
      console.error('Register error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası'
      });
    }
  }

  // Kullanıcı girişi
  async login(req, res) {
    try {
      const { email, password } = req.body;

      // Kullanıcıyı bul
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(400).json({
          success: false,
          message: 'Email veya şifre hatalı'
        });
      }

      // Şifre kontrolü
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        return res.status(400).json({
          success: false,
          message: 'Email veya şifre hatalı'
        });
      }

      // Son giriş tarihini güncelle
      user.lastLogin = new Date();
      await user.save();

      // Access ve Refresh Token oluştur
      const accessToken = jwtService.generateAccessToken({ 
        userId: user._id, 
        email: user.email 
      });
      const refreshToken = jwtService.generateRefreshToken({ 
        userId: user._id, 
        email: user.email 
      });

      res.json({
        success: true,
        message: 'Giriş başarılı',
        data: {
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresIn: '365d'
        }
      });

    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası'
      });
    }
  }

  // Token yenileme
  async refreshToken(req, res) {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        return res.status(400).json({
          success: false,
          message: 'Refresh token gerekli'
        });
      }

      // Refresh token'ı doğrula ve yeni access token oluştur
      const result = await jwtService.refreshAccessToken(refreshToken);

      if (!result.success) {
        return res.status(401).json({
          success: false,
          message: 'Geçersiz refresh token',
          error: result.error
        });
      }

      res.json({
        success: true,
        message: 'Token başarıyla yenilendi',
        data: {
          accessToken: result.accessToken,
          refreshToken: result.refreshToken,
          expiresIn: result.expiresIn
        }
      });

    } catch (error) {
      console.error('Refresh token error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası'
      });
    }
  }

  // Kullanıcı profili
  async getProfile(req, res) {
    try {
      // req.user auth middleware'den geliyor
      res.json({
        success: true,
        data: {
          user: req.user
        }
      });
    } catch (error) {
      console.error('Profile error:', error);
      res.status(500).json({
        success: false,
        message: 'Sunucu hatası'
      });
    }
  }
}

module.exports = new AuthController(); 
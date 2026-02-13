const multer = require('multer');
const path = require('path');
const fs = require('fs');

class FileService {
  constructor() {
    // Uploads klasörünü oluştur
    this.uploadsDir = path.join(process.cwd(), 'uploads');
    this.clothingDir = path.join(this.uploadsDir, 'clothing');
    
    this.createDirectories();
  }

  createDirectories() {
    if (!fs.existsSync(this.uploadsDir)) {
      fs.mkdirSync(this.uploadsDir, { recursive: true });
    }
    if (!fs.existsSync(this.clothingDir)) {
      fs.mkdirSync(this.clothingDir, { recursive: true });
    }
  }

  // Basit multer middleware - memory storage
  getUploadMiddleware() {
    const upload = multer({
      storage: multer.memoryStorage(),
      limits: {
        fileSize: 10 * 1024 * 1024 // 10MB limit
      },
      fileFilter: (req, file, cb) => {
        // Tüm dosya tiplerini kabul et
        cb(null, true);
      }
    });
    
    return upload.single('image');
  }

  // Dosya kaydetme fonksiyonu
  saveImageFile(buffer, userId, originalName = 'upload.jpg') {
    try {
      const timestamp = Date.now();
      const filename = `${timestamp}-${userId}-${originalName}`;
      const filepath = path.join(this.clothingDir, filename);
      
      // Buffer'ı dosyaya yaz
      fs.writeFileSync(filepath, buffer);
      
      return {
        success: true,
        filename: filename,
        filepath: filepath,
        url: this.getFileUrl(filename)
      };
    } catch (error) {
      console.error('File save error:', error);
      return {
        success: false,
        error: error.message
      };
    }
  }

  // Dosya URL'i oluştur (tam URL)
  getFileUrl(filename) {
    const baseUrl = process.env.BASE_URL || 'https://vestiyerapp.com';
    return `${baseUrl}/uploads/clothing/${filename}`;
  }

  // Dosya yolunu al
  getFilePath(filename) {
    return path.join(this.clothingDir, filename);
  }

  // Dosyayı sil
  deleteFile(filename) {
    try {
      const filePath = this.getFilePath(filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
        return true;
      }
      return false;
    } catch (error) {
      console.error('File delete error:', error);
      return false;
    }
  }

  // Dosya var mı kontrol et
  fileExists(filename) {
    const filePath = this.getFilePath(filename);
    return fs.existsSync(filePath);
  }

  // Legacy functions for backward compatibility
  uploadSingle() {
    return this.getUploadMiddleware();
  }

  uploadMultiple(maxCount = 5) {
    const upload = multer({
      storage: multer.memoryStorage(),
      limits: {
        fileSize: 10 * 1024 * 1024 // 10MB limit
      }
    });
    return upload.array('images', maxCount);
  }
}

module.exports = new FileService();
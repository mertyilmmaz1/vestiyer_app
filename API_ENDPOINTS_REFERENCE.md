# 🔌 Vestiyer Backend - API Endpoints Reference

Bu doküman tüm API endpoint'lerini, request/response formatlarını ve status kodlarını içerir.

## 🌐 Base Information

- **Base URL**: `http://localhost:3000` (Development)
- **API Version**: `v1.0.0`
- **Content-Type**: `application/json`
- **Authentication**: Bearer Token (JWT)

---

## 🔐 Authentication Endpoints

### 1. User Registration
```http
POST /api/auth/register
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "123456",
  "firstName": "John",
  "lastName": "Doe"
}
```

**Success Response (201):**
```json
{
  "success": true,
  "message": "Kullanıcı başarıyla oluşturuldu",
  "data": {
    "user": {
      "_id": "64f8b2c123456789",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "profileImage": null,
      "createdAt": "2024-01-15T10:30:00.000Z",
      "lastLogin": null,
      "isActive": true,
      "isPremium": false
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Bu email adresi zaten kullanılıyor"
}
```

---

### 2. User Login
```http
POST /api/auth/login
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "123456"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Giriş başarılı",
  "data": {
    "user": {
      "_id": "64f8b2c123456789",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "lastLogin": "2024-01-15T10:35:00.000Z"
    },
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Email veya şifre hatalı"
}
```

---

### 3. Get Profile
```http
GET /api/auth/profile
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Profil bilgileri getirildi",
  "data": {
    "user": {
      "_id": "64f8b2c123456789",
      "email": "user@example.com",
      "firstName": "John",
      "lastName": "Doe",
      "profileImage": null,
      "createdAt": "2024-01-15T10:30:00.000Z",
      "lastLogin": "2024-01-15T10:35:00.000Z",
      "isActive": true,
      "isPremium": false
    }
  }
}
```

**Error Response (401):**
```json
{
  "success": false,
  "message": "Token geçersiz"
}
```

---

## 👔 Clothing Endpoints

### 1. Analyze and Add Clothing
```http
POST /api/clothing/analyze-and-add
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "base64Image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEA...",
  "title": "Beyaz Gömlek"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kıyafet başarıyla analiz edildi ve eklendi",
  "data": {
    "clothing": {
      "_id": "64f8b3d123456789",
      "userId": "64f8b2c123456789",
      "title": "Beyaz Gömlek",
      "category": "top",
      "imageUrl": "/uploads/clothing/1704450600000-clothing.jpg",
      "imagePath": "uploads/clothing/1704450600000-clothing.jpg",
      "advancedAnalysis": {
        "mainGroup": "üst giyim",
        "category": "gömlek",
        "color": "beyaz",
        "material": "pamuk",
        "style": "formal",
        "season": "all-season",
        "details": "Beyaz renkte, formal tarzda bir gömlek. Ofis ortamı için ideal.",
        "confidence": 0.95
      },
      "tags": ["formal", "office"],
      "isFavorite": false,
      "createdAt": "2024-01-15T11:30:00.000Z",
      "updatedAt": "2024-01-15T11:30:00.000Z"
    }
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "base64Image zorunludur"
}
```

---

### 2. Get All Clothing
```http
GET /api/clothing/{userId}?season={season}&category={category}&style={style}
Authorization: Bearer {token}
```

**Query Parameters:**
- `season` (optional): spring, summer, autumn, winter, all-season
- `category` (optional): top, bottom, shoes, accessory, outerwear
- `style` (optional): casual, formal, sporty

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kıyafetler getirildi",
  "filters": {
    "season": "summer",
    "category": "top",
    "style": null
  },
  "count": 5,
  "data": [
    {
      "_id": "64f8b3d123456789",
      "userId": "64f8b2c123456789",
      "title": "Yaz Tişörtü",
      "category": "top",
      "imageUrl": "/uploads/clothing/1704450600000-tshirt.jpg",
      "imagePath": "uploads/clothing/1704450600000-tshirt.jpg",
      "advancedAnalysis": {
        "mainGroup": "üst giyim",
        "category": "tişört",
        "color": "mavi",
        "material": "pamuk",
        "style": "casual",
        "season": "summer",
        "details": "Rahat günlük kullanım için mavi tişört"
      },
      "tags": ["casual", "summer"],
      "isFavorite": true,
      "createdAt": "2024-01-15T11:30:00.000Z",
      "updatedAt": "2024-01-15T11:30:00.000Z"
    }
  ]
}
```

---

### 3. Get Clothing by Season
```http
GET /api/clothing/{userId}/season?season={season}
Authorization: Bearer {token}
```

**Query Parameters:**
- `season` (required): spring, summer, autumn, winter, all-season

**Success Response (200):**
```json
{
  "success": true,
  "message": "Mevsim bazlı kıyafetler getirildi",
  "season": "summer",
  "count": 12,
  "data": [
    {
      "_id": "64f8b3d123456789",
      "title": "Yaz Elbisesi",
      "category": "top",
      "imageUrl": "/uploads/clothing/summer-dress.jpg",
      "advancedAnalysis": {
        "season": "summer",
        "style": "casual",
        "color": "sarı"
      }
    }
  ]
}
```

---

### 4. Get Current Season Clothing
```http
GET /api/clothing/{userId}/current-season
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Mevcut mevsim kıyafetleri getirildi",
  "currentSeason": "winter",
  "count": 8,
  "data": [
    {
      "_id": "64f8b3d123456789",
      "title": "Kış Montu",
      "category": "outerwear",
      "imageUrl": "/uploads/clothing/winter-coat.jpg",
      "advancedAnalysis": {
        "season": "winter",
        "style": "casual",
        "material": "yün"
      }
    }
  ]
}
```

---

### 5. Get Season Statistics
```http
GET /api/clothing/{userId}/statistics
Authorization: Bearer {token}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Mevsim istatistikleri getirildi",
  "data": {
    "totalItems": 45,
    "currentSeason": "winter",
    "categoryCounts": {
      "top": 15,
      "bottom": 12,
      "shoes": 8,
      "outerwear": 6,
      "accessory": 4
    },
    "seasonCounts": {
      "spring": 12,
      "summer": 15,
      "autumn": 10,
      "winter": 8,
      "all-season": 20
    },
    "currentSeasonItems": 28,
    "styleDistribution": {
      "casual": 25,
      "formal": 12,
      "sporty": 8
    }
  }
}
```

---

## 👗 Combination Endpoints

### 1. Generate AI Combinations
```http
POST /api/combinations/generate
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "userId": "64f8b2c123456789",
  "forceGenerate": false
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Çeşitli kombin önerileri başarıyla oluşturuldu",
  "data": {
    "combinations": [
      {
        "name": "Günlük Rahat Kombin",
        "description": "Rahatlık ve şıklığı bir arada sunan günlük kombin",
        "occasion": "daily",
        "season": "all-season",
        "items": ["64f8b3d123456789", "64f8b3d123456790", "64f8b3d123456791"]
      },
      {
        "name": "İş Kombini",
        "description": "Profesyonel görünüm için ideal",
        "occasion": "work",
        "season": "all-season",
        "items": ["64f8b3d123456792", "64f8b3d123456793", "64f8b3d123456794"]
      }
    ],
    "savedCombinations": [
      {
        "_id": "64f8b4e123456789",
        "userId": "64f8b2c123456789",
        "name": "Günlük Rahat Kombin",
        "description": "Rahatlık ve şıklığı bir arada sunan günlük kombin",
        "occasion": "daily",
        "season": "all-season",
        "clothingItems": [
          {
            "clothingId": "64f8b3d123456789",
            "category": "top",
            "isRequired": true
          },
          {
            "clothingId": "64f8b3d123456790",
            "category": "bottom",
            "isRequired": true
          }
        ],
        "isAIGenerated": true,
        "aiGeneration": {
          "prompt": "diversity_optimized_generation",
          "model": "gpt-4o-mini",
          "generatedAt": "2024-01-15T12:00:00.000Z",
          "confidence": 0.8
        },
        "isFavorite": false,
        "timesWorn": 0,
        "tags": ["casual"],
        "createdAt": "2024-01-15T12:00:00.000Z",
        "updatedAt": "2024-01-15T12:00:00.000Z"
      }
    ],
    "totalItems": 25,
    "usedItems": 18,
    "diversityScore": 85
  },
  "usage": {
    "promptTokens": 1245,
    "completionTokens": 456,
    "totalCost": 0.023
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "Dolabınızda henüz kıyafet bulunmuyor. Önce kıyafet eklemelisiniz."
}
```

---

### 2. Get User Combinations
```http
GET /api/combinations/user/{userId}?page={page}&limit={limit}&occasion={occasion}&isFavorite={isFavorite}
Authorization: Bearer {token}
```

**Query Parameters:**
- `page` (optional): Page number (default: 1)
- `limit` (optional): Items per page (default: 10)
- `occasion` (optional): daily, work, party, formal, casual, sport, date, travel
- `isFavorite` (optional): true, false

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kombinler başarıyla getirildi",
  "data": {
    "combinations": [
      {
        "_id": "64f8b4e123456789",
        "userId": "64f8b2c123456789",
        "name": "Parti Kombini",
        "description": "Özel günler için şık kombin",
        "occasion": "party",
        "season": "all-season",
        "clothingItems": [
          {
            "clothingId": {
              "_id": "64f8b3d123456789",
              "title": "Siyah Elbise",
              "category": "top",
              "imageUrl": "/uploads/clothing/black-dress.jpg"
            },
            "category": "top",
            "isRequired": true
          }
        ],
        "isAIGenerated": true,
        "isFavorite": true,
        "rating": 5,
        "timesWorn": 2,
        "lastWorn": "2024-01-10T19:00:00.000Z",
        "tags": ["elegant", "party"],
        "createdAt": "2024-01-15T12:00:00.000Z",
        "updatedAt": "2024-01-15T12:05:00.000Z"
      }
    ],
    "totalCombinations": 15,
    "currentPage": 1,
    "totalPages": 2,
    "hasNextPage": true
  }
}
```

---

### 3. Get Combination Clothing Details
```http
POST /api/combinations/clothing-details
Authorization: Bearer {token}
Content-Type: application/json
```

**Request Body:**
```json
{
  "clothingIds": ["64f8b3d123456789", "64f8b3d123456790", "64f8b3d123456791"],
  "userId": "64f8b2c123456789"
}
```

**Success Response (200):**
```json
{
  "success": true,
  "message": "Kıyafet detayları başarıyla getirildi",
  "data": {
    "clothingItems": [
      {
        "_id": "64f8b3d123456789",
        "userId": "64f8b2c123456789",
        "title": "Beyaz Gömlek",
        "category": "top",
        "imageUrl": "/uploads/clothing/white-shirt.jpg",
        "imagePath": "uploads/clothing/white-shirt.jpg",
        "advancedAnalysis": {
          "mainGroup": "üst giyim",
          "category": "gömlek",
          "color": "beyaz",
          "material": "pamuk",
          "style": "formal",
          "season": "all-season",
          "details": "Klasik beyaz gömlek, iş ve günlük kullanım için ideal"
        },
        "tags": ["formal", "classic"],
        "isFavorite": false,
        "createdAt": "2024-01-15T11:30:00.000Z",
        "updatedAt": "2024-01-15T11:30:00.000Z"
      },
      {
        "_id": "64f8b3d123456790",
        "userId": "64f8b2c123456789",
        "title": "Siyah Pantolon",
        "category": "bottom",
        "imageUrl": "/uploads/clothing/black-pants.jpg",
        "imagePath": "uploads/clothing/black-pants.jpg",
        "advancedAnalysis": {
          "mainGroup": "alt giyim",
          "category": "pantolon",
          "color": "siyah",
          "material": "pamuk",
          "style": "formal",
          "season": "all-season",
          "details": "Klasik siyah pantolon, resmi ortamlar için uygun"
        },
        "tags": ["formal", "classic"],
        "isFavorite": true,
        "createdAt": "2024-01-15T11:45:00.000Z",
        "updatedAt": "2024-01-15T11:45:00.000Z"
      }
    ],
    "totalFound": 2,
    "totalRequested": 3,
    "notFoundIds": ["64f8b3d123456791"]
  }
}
```

**Error Response (400):**
```json
{
  "success": false,
  "message": "clothingIds array zorunludur ve en az bir ID içermelidir."
}
```

---

## 📊 Status Codes

### Success Codes
- **200 OK**: Request successful
- **201 Created**: Resource created successfully

### Client Error Codes
- **400 Bad Request**: Invalid request parameters
- **401 Unauthorized**: Invalid or missing authentication token
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource not found
- **422 Unprocessable Entity**: Validation errors

### Server Error Codes
- **500 Internal Server Error**: Server error
- **503 Service Unavailable**: Service temporarily unavailable

---

## 🔧 Error Response Format

All error responses follow this format:

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (optional)",
  "code": "ERROR_CODE (optional)"
}
```

**Common Error Messages:**
- `"Token geçersiz"` - Invalid authentication token
- `"userId zorunludur"` - Missing required userId parameter
- `"Sunucu hatası"` - Internal server error
- `"Dosya yüklenemedi"` - File upload failed
- `"AI analizi başarısız"` - AI analysis failed

---

## 🚀 Rate Limits

Currently no rate limiting is implemented, but recommended limits for production:

- **Authentication**: 5 requests per minute per IP
- **File Upload**: 10 requests per hour per user
- **AI Analysis**: 20 requests per hour per user
- **General API**: 100 requests per minute per user

---

## 🔒 Security Headers

Required headers for authenticated requests:

```http
Authorization: Bearer {jwt_token}
Content-Type: application/json
Accept: application/json
```

---

## 🖼️ Image Handling

### Image Upload Format
- **Supported formats**: JPEG, PNG, GIF
- **Max file size**: 5MB
- **Base64 format**: `data:image/{format};base64,{data}`

### Image URL Format
- **Static URL**: `{baseUrl}/uploads/clothing/{filename}`
- **Example**: `http://localhost:3000/uploads/clothing/1704450600000-clothing.jpg`

---

## 🧪 Testing Endpoints

### Using cURL

```bash
# Register
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456","firstName":"Test","lastName":"User"}'

# Login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"123456"}'

# Get Profile (with token)
curl -X GET http://localhost:3000/api/auth/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Get Clothing
curl -X GET "http://localhost:3000/api/clothing/USER_ID?category=top&season=summer" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# Generate Combinations
curl -X POST http://localhost:3000/api/combinations/generate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"userId":"USER_ID","forceGenerate":false}'
```

### Using Postman

1. Import the base URL: `http://localhost:3000`
2. Set up environment variables:
   - `baseUrl`: `http://localhost:3000`
   - `token`: `{{auth_token}}`
3. Use pre-request scripts for automatic token management

---

## 📈 Data Models

### User Model
```json
{
  "_id": "string",
  "email": "string",
  "firstName": "string",
  "lastName": "string",
  "profileImage": "string|null",
  "createdAt": "ISO 8601 date",
  "lastLogin": "ISO 8601 date|null",
  "isActive": "boolean",
  "isPremium": "boolean"
}
```

### Clothing Model
```json
{
  "_id": "string",
  "userId": "string",
  "title": "string",
  "category": "top|bottom|shoes|accessory|outerwear",
  "imageUrl": "string",
  "imagePath": "string",
  "advancedAnalysis": {
    "mainGroup": "string",
    "category": "string",
    "color": "string",
    "material": "string",
    "style": "string",
    "season": "spring|summer|autumn|winter|all-season",
    "details": "string",
    "confidence": "number"
  },
  "tags": ["string"],
  "isFavorite": "boolean",
  "createdAt": "ISO 8601 date",
  "updatedAt": "ISO 8601 date"
}
```

### Combination Model
```json
{
  "_id": "string",
  "userId": "string",
  "name": "string",
  "description": "string",
  "occasion": "daily|work|party|formal|casual|sport|date|travel",
  "season": "spring|summer|autumn|winter|all-season",
  "clothingItems": [
    {
      "clothingId": "string",
      "category": "string",
      "isRequired": "boolean"
    }
  ],
  "isAIGenerated": "boolean",
  "isFavorite": "boolean",
  "rating": "number|null",
  "timesWorn": "number",
  "lastWorn": "ISO 8601 date|null",
  "tags": ["string"],
  "createdAt": "ISO 8601 date",
  "updatedAt": "ISO 8601 date"
}
``` 
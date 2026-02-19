# Vestiyer VPS Segment Service

Arka plan kaldırma servisi – rembg (U2Net) + FastAPI. Kıyafet fotoğraflarından arka planı temizleyip crop/normalize eder.

## VPS Kurulumu

```bash
cd ~
mkdir -p segment-service
cd segment-service

# Python venv
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Bağımlılıklar
pip install -r requirements.txt

# API key (opsiyonel, güvenlik için önerilir)
export SEGMENT_API_KEY="your-secret-key"

# Çalıştır
uvicorn main:app --host 0.0.0.0 --port 8000
```

## systemd Servisi (Sürekli Çalışma)

`/etc/systemd/system/segment-service.service`:

```ini
[Unit]
Description=Vestiyer Segment Service
After=network.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/segment-service
Environment="PATH=/home/ubuntu/segment-service/venv/bin"
Environment="SEGMENT_API_KEY=your-secret-key"
ExecStart=/home/ubuntu/segment-service/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable segment-service
sudo systemctl start segment-service
```

## API

- `GET /health` – Sağlık kontrolü (API key gerekmez). Response: `{ "status": "ok" }`
- `POST /segment` – Body: `{ "imageUrl": "https://..." }` Header: `X-API-Key`

Response: `image/png` (binary PNG bytes)

## VPS sağlık kontrolü

- **Doğrudan (VPS’e erişiminiz varsa):**  
  `curl -s https://your-vps-domain.com/health`
- **Cloud Functions üzerinden (giriş yapmış kullanıcı):**  
  Uygulama içinde `CloudFunctionsService.checkSegmentServiceHealth()` çağrılır; sonuçta `ok`, `configured`, `latencyMs`, `error` döner.
- **Terminal (Firebase projesiyle aynı URL):**  
  `cd functions && SEGMENT_SERVICE_URL=https://your-vps.com npm run check-vps-health`

## Firebase Cloud Functions Entegrasyonu

VPS hazır olduğunda Firebase config ile ayarla:

```bash
firebase functions:config:set segment_service.url="https://your-vps-domain.com" segment_service.api_key="your-api-key"
```

Veya Firebase Secrets kullan (runWith secrets listesine SEGMENT_SERVICE_URL, SEGMENT_SERVICE_API_KEY eklenmeli).

Config/secrets boşsa segment atlanır; ham görsel ile analiz devam eder (fallback).

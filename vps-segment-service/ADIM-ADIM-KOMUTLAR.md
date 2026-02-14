# VPS Segment Servisi – Adım adım komutlar

Terminalde sırayla çalıştır. Her bloktan sonra Enter’a bas (tek blokta birden fazla satır varsa hepsini yapıştırıp sonra Enter).

---

## Yol A: Script’i Mac’ten atıp VPS’te çalıştırmak (en kısa)

### 1) Mac’te – yeni terminal aç, proje klasörüne gir, script’i at

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app
scp vps-segment-service/setup-vps.sh root@31.97.45.46:/tmp/
```

Şifre sorarsa VPS şifreni gir.

---

### 2) VPS’te – SSH ile bağlı olduğun terminalde kurulumu çalıştır

```bash
bash /tmp/setup-vps.sh
```

Birkaç dakika sürebilir (rembg indiriliyor).

---

### 3) VPS’te – Port 8000’i aç (güvenlik duvarı varsa)

```bash
ufw allow 8000/tcp
ufw reload
```

`ufw: command not found` dersen bu adımı atla veya sunucu panelinden 8000’i aç.

---

### 4) VPS’te – Test

```bash
curl http://127.0.0.1:8000/health
```

Çıktı: `{"status":"ok"}` olmalı.

---

## Yol B: Sadece VPS terminali kullanmak (script’i VPS’te oluştur)

SSH ile bağlısın, Mac’te ikinci terminal açmak istemiyorsan: aşağıdaki **tek blok**u VPS’te yapıştırıp Enter’a bas. Script oluşur ve kurulum başlar.

```bash
cat > /tmp/setup-vps.sh << 'ENDOFSCRIPT'
#!/bin/bash
set -e
SERVICE_DIR="/opt/segment-service"
SERVICE_USER="root"

echo "[1/6] Sistem paketleri güncelleniyor..."
apt-get update -qq
apt-get install -y -qq python3 python3-pip python3-venv

echo "[2/6] Dizin ve dosyalar oluşturuluyor: $SERVICE_DIR"
mkdir -p "$SERVICE_DIR"
cd "$SERVICE_DIR"

cat > requirements.txt << 'REQ'
fastapi>=0.104.0
uvicorn[standard]>=0.24.0
rembg[cpu]>=2.0.50
pillow>=10.0.0
httpx>=0.25.0
python-multipart>=0.0.6
REQ

cat > main.py << 'MAIN'
"""
VPS Segment Service – Vestiyer garment background removal.
"""
import base64
import io
import os
from typing import Optional
import httpx
from fastapi import FastAPI, Header, HTTPException, Request
from PIL import Image
from rembg import remove, new_session

app = FastAPI(title="Vestiyer Segment Service")
API_KEY = os.environ.get("SEGMENT_API_KEY", "")
REMBG_MODEL = os.environ.get("REMBG_MODEL", "u2net")
_rembg_session = new_session(REMBG_MODEL)
MAX_IMAGE_SIZE = 1024
OUTPUT_SIZE = 512

def verify_api_key(x_api_key: Optional[str] = Header(None)) -> None:
    if API_KEY and x_api_key != API_KEY:
        raise HTTPException(status_code=401, detail="Invalid API key")

def download_image(url: str) -> bytes:
    with httpx.Client(timeout=30.0) as client:
        resp = client.get(url)
        resp.raise_for_status()
        return resp.content

def remove_background_and_crop(image_bytes: bytes) -> bytes:
    input_img = Image.open(io.BytesIO(image_bytes)).convert("RGBA")
    input_img.thumbnail((MAX_IMAGE_SIZE, MAX_IMAGE_SIZE), Image.Resampling.LANCZOS)
    output_img = remove(input_img, session=_rembg_session)
    white_bg = Image.new("RGBA", output_img.size, (255, 255, 255, 255))
    white_bg.paste(output_img, mask=output_img.split()[3])
    result = white_bg.convert("RGB")
    pixels = result.load()
    w, h = result.size
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    for x in range(w):
        for y in range(h):
            r, g, b = pixels[x, y]
            if r < 250 or g < 250 or b < 250:
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    if max_x <= min_x or max_y <= min_y:
        cropped = result
    else:
        padding = 10
        min_x = max(0, min_x - padding)
        min_y = max(0, min_y - padding)
        max_x = min(w, max_x + padding)
        max_y = min(h, max_y + padding)
        cropped = result.crop((min_x, min_y, max_x, max_y))
    cw, ch = cropped.size
    side = min(max(cw, ch), OUTPUT_SIZE)
    new_img = Image.new("RGB", (side, side), (255, 255, 255))
    cropped.thumbnail((side, side), Image.Resampling.LANCZOS)
    ncw, nch = cropped.size
    x_off = (side - ncw) // 2
    y_off = (side - nch) // 2
    new_img.paste(cropped, (x_off, y_off))
    buf = io.BytesIO()
    new_img.save(buf, format="PNG", optimize=True)
    return buf.getvalue()

@app.get("/health")
async def health():
    return {"status": "ok"}

@app.post("/segment")
async def segment(request: Request, x_api_key: Optional[str] = Header(None)):
    verify_api_key(x_api_key)
    body = await request.json()
    image_url = body.get("imageUrl")
    if not image_url or not isinstance(image_url, str):
        raise HTTPException(status_code=400, detail="imageUrl required")
    try:
        image_bytes = download_image(image_url)
    except Exception as e:
        raise HTTPException(status_code=400, detail=f"Failed to fetch image: {e}")
    try:
        result_png = remove_background_and_crop(image_bytes)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Background removal failed: {e}")
    b64 = base64.b64encode(result_png).decode("utf-8")
    return {"success": True, "imageBase64": f"data:image/png;base64,{b64}"}
MAIN

echo "[3/6] Python venv ve bağımlılıklar (birkaç dakika sürebilir)..."
python3 -m venv venv
./venv/bin/pip install -q --upgrade pip
./venv/bin/pip install -q -r requirements.txt

echo "[4/6] API anahtarı..."
API_KEY="${SEGMENT_API_KEY:-vestiyer-segment-key-degistirin}"
mkdir -p /etc/segment-service
echo "SEGMENT_API_KEY=$API_KEY" > /etc/segment-service/api_key.env
chmod 600 /etc/segment-service/api_key.env

echo "[5/6] systemd servisi..."
cat > /etc/systemd/system/segment-service.service << SVC
[Unit]
Description=Vestiyer Segment Service
After=network.target

[Service]
Type=simple
User=$SERVICE_USER
WorkingDirectory=$SERVICE_DIR
Environment="PATH=$SERVICE_DIR/venv/bin"
EnvironmentFile=/etc/segment-service/api_key.env
ExecStart=$SERVICE_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVC

echo "[6/6] Servis başlatılıyor..."
systemctl daemon-reload
systemctl enable segment-service
systemctl start segment-service
echo "Kurulum tamamlandı. Test: curl http://127.0.0.1:8000/health"
ENDOFSCRIPT
chmod +x /tmp/setup-vps.sh
bash /tmp/setup-vps.sh
```

Bittikten sonra port ve test için (VPS’te):

```bash
ufw allow 8000/tcp
ufw reload
curl http://127.0.0.1:8000/health
```

---

## Yararlı komutlar (kurulumdan sonra)

| Ne yapmak istiyorsun | Komut |
|----------------------|--------|
| Servis durumu        | `systemctl status segment-service` |
| Logları izle         | `journalctl -u segment-service -f` |
| Servisi yeniden başlat | `systemctl restart segment-service` |
| Health kontrolü      | `curl http://127.0.0.1:8000/health` |
| API anahtarını değiştir | `echo 'SEGMENT_API_KEY=yeni-anahtar' > /etc/segment-service/api_key.env` sonra `systemctl restart segment-service` |

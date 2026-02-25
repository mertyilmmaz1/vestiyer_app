# VPS Segment Servisi – Yayınlama (Deploy)

Arka plan kaldırma kodunda yaptığın değişiklikleri VPS’e atıp servisi yeniden başlatma.

---

## VPS bilgileri (proje dosyalarından)

| Bilgi | Değer |
|-------|--------|
| VPS adresi | `31.97.45.46` |
| Kullanıcı | `root` |
| Servis dizini | `/opt/segment-service` |
| Servis adı | `segment-service` |

---

## Yol 1: Tek komutla (deploy script)

Proje kökünden:

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app
bash vps-segment-service/deploy.sh
```

Şifre sorarsa VPS root şifreni gir. Script: güncel `main.py`, `requirements.txt` ve `static/` dosyalarını atar, gerekirse bağımlılıkları günceller, servisi yeniden başlatır.

---

## Yol 2: Adım adım manuel

### 1) Dosyaları VPS’e kopyala

Mac’te (proje kökünde):

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app

scp vps-segment-service/main.py vps-segment-service/requirements.txt root@31.97.45.46:/opt/segment-service/

scp -r vps-segment-service/static root@31.97.45.46:/opt/segment-service/
```

### 2) VPS’e bağlan

```bash
ssh root@31.97.45.46
```

### 3) Bağımlılıkları güncelle (requirements değiştiyse)

```bash
cd /opt/segment-service
./venv/bin/pip install -r requirements.txt
```

### 4) Servisi yeniden başlat

```bash
systemctl restart segment-service
```

### 5) Kontrol

```bash
systemctl status segment-service
curl -s http://127.0.0.1:8000/health
```

Çıktı: `{"status":"ok", ...}` olmalı.

---

## Sorun giderme

| Komut | Ne işe yarar |
|-------|-------------------------------|
| `systemctl status segment-service` | Servis çalışıyor mu |
| `journalctl -u segment-service -n 50` | Son 50 log satırı |
| `journalctl -u segment-service -f` | Canlı log takibi |

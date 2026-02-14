# VPS Kurulum – 31.97.45.46

## 1. Scripti sunucuya atın (Mac’te yeni bir terminal açın, SSH’den çıkın)

```bash
cd /Users/mertyilmaz/Documents/GitHub/vestiyer_app/vestiyer_app
scp vps-segment-service/setup-vps.sh root@31.97.45.46:/tmp/
```

## 2. SSH ile bağlanıp scripti çalıştırın

```bash
ssh root@31.97.45.46
bash /tmp/setup-vps.sh
```

İlk kurulumda rembg indirileceği için 2–5 dakika sürebilir.

## 3. Port 8000’i açın (sunucuda)

```bash
# UFW kullanıyorsanız
ufw allow 8000/tcp
ufw reload

# veya iptables
iptables -I INPUT -p tcp --dport 8000 -j ACCEPT
```

## 4. Test

- Sunucuda: `curl http://127.0.0.1:8000/health`
- Kendi bilgisayarınızdan: `curl http://31.97.45.46:8000/health`

## 5. Firebase tarafı

Firebase Secrets’a ekleyin:

- `SEGMENT_SERVICE_URL` = `http://31.97.45.46:8000` (HTTPS için ileride nginx + Let’s Encrypt)
- `SEGMENT_SERVICE_API_KEY` = `/etc/segment-service/api_key.env` içindeki anahtar (veya kurulumda verdiğiniz)

API anahtarını değiştirmek için sunucuda:

```bash
echo 'SEGMENT_API_KEY=yeni-gizli-anahtar' > /etc/segment-service/api_key.env
systemctl restart segment-service
```

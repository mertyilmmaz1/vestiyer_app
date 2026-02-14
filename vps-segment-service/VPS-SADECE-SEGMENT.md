# VPS’i Sadece Segment Servisi İçin Kullanmak

Bu sunucuda sadece **segment-service** (arka plan kaldırma API’si) çalışsın; başka uygulama/servis kalmasın.

---

## Senin sunucuda çalışanlar (özet)

| Servis | Ne? | Segment için gerekli? |
|--------|-----|------------------------|
| **segment-service** | Vestiyer arka plan kaldırma API | ✅ Evet – bunu kullanıyorsun |
| **ssh** | SSH ile bağlanma | ✅ Evet – bırak |
| **fail2ban** | SSH brute-force koruması | ✅ Bırakman iyi olur |
| **nginx** | Web sunucusu | ❌ Kapatılabilir (segment uvicorn ile 8000’de) |
| **mongod** | MongoDB | ❌ Kapatılabilir (segment kullanmıyor) |
| **pm2-root** | PM2 (Node.js process manager) | ❌ Kapatılabilir (segment Python) |
| **monarx-agent** | Hosting firma güvenlik tarayıcısı | ⚠️ İsteğe bağlı (firma araçlarına dokunmak istemeyebilirsin) |
| **cron, dbus, rsyslog, systemd-*, getty, polkit, qemu-guest-agent, udisks2, multipathd, unattended-upgrades, ModemManager** | Sistem / güvenlik / güncelleme | Genelde dokunma |

---

## 1. Şu an ne çalışıyor? (Kontrol)

VPS’e SSH ile bağlanıp sırayla çalıştır:

```bash
# Aktif systemd servisleri (sadece enabled + running)
systemctl list-units --type=service --state=running --no-pager

# Dinleyen portlar (hangi uygulama hangi portu kullanıyor)
ss -tlnp
```

Beklenen: **8000** portunda sadece segment-service (uvicorn). 22 = SSH (açık kalmalı).

---

## 2. Sadece segment + SSH kalsın (Temizlik)

### Sadece segment kalsın – senin sunucuda kapatılacaklar

**nginx, mongod, pm2-root** segment için gerekmez. Aşağıdakileri VPS’te çalıştır (tek blok kopyala-yapıştır):

```bash
# Nginx (web sunucusu) – segment uvicorn kullanıyor, nginx gerekmez
systemctl stop nginx
systemctl disable nginx

# MongoDB – segment kullanmıyor
systemctl stop mongod
systemctl disable mongod

# PM2 (Node.js süreç yöneticisi) – segment Python, PM2 gerekmez
systemctl stop pm2-root
systemctl disable pm2-root
```

**Bırakman gerekenler:** `ssh`, `segment-service`, `fail2ban`, `cron`, `rsyslog`, `systemd-*`, `unattended-upgrades` ve diğer sistem birimleri.  
**İsteğe bağlı:** `monarx-agent` hosting firmanın güvenlik aracıdır; kapatmak istersen `systemctl stop monarx-agent && systemctl disable monarx-agent` (firma panelinden de kapatılabiliyor olabilir).

### Cron (zamanlanmış iş)

```bash
crontab -l
```
Çıktı varsa ve segment ile ilgili değilse: `crontab -r` ile silebilirsin (root’un cron’unu kaldırır).

---

## 3. Kurulumda ne ekledik? (Sadece bunlar kalsın)

Bu VPS’te **senin kurduğun** şeyler:

| Bileşen | Konum | Amaç |
|--------|--------|------|
| segment-service (systemd) | `/opt/segment-service/` | Tek uygulama: POST /segment, port 8000 |
| API key | `/etc/segment-service/api_key.env` | X-API-Key ile koruma |
| Python venv | `/opt/segment-service/venv/` | rembg, FastAPI, uvicorn |

Başka bir uygulama veya site kurmadık. Varsayılan olarak birçok VPS’te **nginx/apache, mysql, docker** gibi şeyler kapalı gelir; açıksa yukarıdaki komutlarla kapatırsın.

---

## 4. Özet komutlar (kopyala-yapıştır)

VPS’te tek seferlik:

```bash
# Çalışan servisleri listele (kontrol)
systemctl list-units --type=service --state=running --no-pager

# Portları listele (8000 = segment, 22 = SSH olmalı)
ss -tlnp

# İstemediğin servisleri kapat (örnekler; sunucunda yoksa hata verir, önemsiz)
for s in nginx apache2 mysql mariadb docker; do systemctl stop $s 2>/dev/null; systemctl disable $s 2>/dev/null; done

# Segment servisinin açık ve enabled olduğundan emin ol
systemctl enable segment-service
systemctl start segment-service
systemctl status segment-service
```

Bunlardan sonra sunucuda **sadece**:
- SSH (port 22),
- segment-service (port 8000),
- sistem servisleri (log, network, vb.)

kalır. Başka bir şey çalıştırmıyorsan VPS fiilen sadece segment için kullanılıyor demektir.

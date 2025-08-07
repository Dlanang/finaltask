# 📦 All-in-One Monitoring App (Nginx + PHP + SQLite + Streamlit + Suricata)

Proyek ini adalah solusi *all-in-one* yang ringan dan portabel untuk menyajikan:

- ✅ Landing page & sistem login berbasis PHP + SQLite
- ✅ Dasbor Streamlit untuk visualisasi pemantauan jaringan *real-time* (didukung oleh Suricata)
- ✅ Disajikan melalui satu kontainer Docker
- ✅ Dukungan HTTPS dengan sertifikat *self-signed* (lokal) atau Let's Encrypt (produksi)

---

## 🛠 Tumpukan Teknologi

| Komponen  | Fungsi                                  |
|-----------|-----------------------------------------|
| Ubuntu    | Citra dasar (22.04)                     |
| Nginx     | *Web server* & *Reverse Proxy*          |
| PHP-FPM   | *PHP interpreter*                       |
| SQLite3   | Basis data ringan untuk sistem login    |
| Streamlit | Dasbor visualisasi data                 |
| Suricata  | Sistem Deteksi Intrusi (IDS) / IPS      |
| Certbot   | Otomatisasi sertifikat SSL/TLS          |
| Logrotate | Manajemen rotasi log                    |
| Bash      | Skrip *auto-setup* & *deployment*       |

---

## 📂 Struktur Direktori

```bash
monitoring_app/
├── build.sh                # Skrip untuk membangun & menjalankan kontainer
├── Dockerfile              # Definisi citra Docker
├── .env.example            # Contoh konfigurasi variabel lingkungan
├── .env                    # Konfigurasi variabel lingkungan (tidak di-commit)
├── certbot/                # Direktori untuk konfigurasi Certbot & sertifikat SSL
│   ├── conf/               # Konfigurasi Certbot
│   └── www/                # Direktori webroot untuk tantangan Certbot
├── db/                     # Direktori untuk basis data SQLite
│   └── app.db
├── docker/                 # File konfigurasi & aplikasi Docker
│   ├── nginx/              # Konfigurasi Nginx
│   │   └── default.conf
│   ├── php/                # File PHP (landing, login, dasbor)
│   │   ├── dashboard.php
│   │   ├── index.php
│   │   └── login.php
│   ├── streamlit/          # Aplikasi Streamlit
│   │   └── app.py
│   ├── supervisor/         # Konfigurasi Supervisor
│   │   └── supervisord.conf
│   └── logrotate/          # Konfigurasi Logrotate
│       └── suricata
├── html/                   # File HTML (jika ada)
├── init_db.py              # Skrip inisialisasi basis data
├── LICENSE
├── README.md
└── suricata_logs/          # Direktori untuk log Suricata (eve.json)
```

---

## 🚀 Cara Instalasi & Konfigurasi

### 1. Kloning Repositori

```bash
git clone <URL_REPOSITORI_ANDA>
cd monitoring_app
```

### 2. Konfigurasi Lingkungan

Buat file `.env` dari `.env.example` dan sesuaikan nilainya:

```bash
cp .env.example .env
```

Edit file `.env` dan isi variabel berikut:

```ini
DOMAIN=yourdomain.com                  # Ganti dengan domain Anda
CERTBOT_EMAIL=youremail@example.com    # Ganti dengan email Anda
ENABLE_CERTBOT=false                   # Atur 'true' untuk produksi dengan Certbot, 'false' untuk lokal/self-signed
```

**Penting:**
- Jika `ENABLE_CERTBOT=true`, pastikan domain Anda sudah mengarah ke IP publik server dan port 80/443 terbuka di firewall Anda.
- Jika `ENABLE_CERTBOT=false`, aplikasi akan menggunakan sertifikat *self-signed* dan Anda akan melihat peringatan keamanan di browser.

### 3. Jalankan Aplikasi

Berikan izin eksekusi pada skrip `build.sh` dan jalankan:

```bash
chmod +x build.sh
./build.sh
```

Skrip ini akan secara otomatis:
- Menghentikan dan menghapus kontainer lama (jika ada).
- Membuat sertifikat SSL (Certbot atau *self-signed*).
- Membangun citra Docker.
- Menjalankan kontainer dengan mode jaringan yang adaptif (`host` atau `bridge`).
- Mengkonfigurasi Nginx dan memulai semua layanan (Nginx, PHP-FPM, Suricata, Streamlit).

### 4. Akses Aplikasi Web

Setelah skrip selesai, Anda akan melihat instruksi akses di terminal. Contoh:

**Akses Lokal (dengan `ENABLE_CERTBOT=false`):**
- **Nginx/PHP**: `http://localhost:80` (akan dialihkan ke HTTPS)
- **Dasbor Streamlit**: `https://localhost:443` (terima peringatan sertifikat *self-signed*)

**Akses Produksi (dengan `ENABLE_CERTBOT=true`):**
- **Nginx/PHP**: `http://yourdomain.com:80` (akan dialihkan ke HTTPS)
- **Dasbor Streamlit**: `https://yourdomain.com`

---

## 🔐 Kredensial Default (SQLite)

* **Nama Pengguna**: `admin`
* **Kata Sandi**: `admin`

Kredensial disimpan dalam basis data `db/app.db`. Skrip `init_db.py` akan membuat pengguna ini saat pertama kali dijalankan.

---

## 🔧 Konfigurasi Tambahan

- **Rotasi Log Suricata**: File `eve.json` Suricata akan dirotasi setiap hari oleh `logrotate` untuk menghemat sumber daya dan menjaga kinerja dasbor Streamlit.
- **Mode Jaringan Adaptif**: Skrip `build.sh` akan mencoba menggunakan `network_mode: "host"` untuk Suricata. Jika tidak didukung, ia akan secara otomatis beralih ke `network_mode: "bridge"`.

---

## 🧪 Pengembangan Selanjutnya

- Integrasi aturan Suricata kustom.
- Enkripsi kata sandi (bcrypt) untuk sistem login PHP.
- Implementasi token sesi yang aman untuk dasbor PHP.
- Integrasi dengan alat pemantauan lain seperti Prometheus atau Loki.

---

## 🪪 Lisensi

MIT License © 2025

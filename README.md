# 📦 Monitoring App (Nginx + Streamlit)

Proyek ini adalah solusi ringan dan portabel untuk menyajikan dasbor pemantauan jaringan *real-time* yang didukung oleh Suricata, disajikan melalui satu kontainer Docker.

---

## 🛠 Tumpukan Teknologi

| Komponen  | Fungsi                                  |
|-----------|-----------------------------------------|
| Ubuntu    | Citra dasar (22.04)                     |
| Nginx     | *Web server* & *Reverse Proxy*          |
| Python    | Bahasa pemrograman utama                |
| Streamlit | Dasbor visualisasi data                 |
| SQLite3   | Basis data ringan (untuk konfigurasi internal) |
| Certbot   | Otomatisasi sertifikat SSL/TLS          |
| Supervisor| Manajemen proses dalam kontainer        |

---

## 📂 Struktur Direktori

```bash
monitoring_app/
├── build.sh                # Skrip untuk membangun & menjalankan kontainer
├── docker-compose.yaml     # Definisi layanan Docker Compose
├── Dockerfile              # Definisi citra Docker
├── .env.example            # Contoh konfigurasi variabel lingkungan
├── .env                    # Konfigurasi variabel lingkungan (tidak di-commit)
├── certbot/                # Direktori untuk konfigurasi Certbot & sertifikat SSL
│   ├── conf/               # Konfigurasi Certbot
│   └── www/                # Direktori webroot untuk tantangan Certbot
├── db/                     # Direktori untuk basis data SQLite (digunakan oleh Streamlit)
│   └── app.db
├── docker/                 # File konfigurasi & aplikasi Docker
│   ├── nginx/              # Konfigurasi Nginx
│   │   └── default.conf
│   ├── streamlit/          # Aplikasi Streamlit
│   │   └── app.py
│   └── supervisor/         # Konfigurasi Supervisor
│       └── supervisord.conf
├── init_db.py              # Skrip inisialisasi basis data (untuk Streamlit)
├── LICENSE
├── README.md
└── suricata_logs/          # Direktori untuk log Suricata (eve.json) dari host
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

### 3. Jalankan Aplikasi Docker dengan Docker Compose

Berikan izin eksekusi pada skrip `build.sh` dan jalankan:

```bash
chmod +x build.sh
./build.sh
```

Skrip ini akan secara otomatis:
- Menghentikan dan menghapus layanan Docker Compose lama (jika ada).
- Membuat sertifikat SSL (Certbot atau *self-signed*).
- Membangun citra Docker untuk layanan `app`.
- Menjalankan layanan `app` menggunakan Docker Compose dengan port yang dipetakan.

**Penting:** Pastikan Suricata sudah berjalan di *host system* Anda dan menghasilkan `eve.json` di direktori yang benar (`suricata_logs/`) agar dasbor Streamlit dapat menampilkan data.

### 4. Akses Aplikasi Web

Setelah skrip `build.sh` selesai, aplikasi akan berjalan dan dapat diakses melalui *browser* Anda.

**Akses Lokal (dengan `ENABLE_CERTBOT=false` di `.env`):**
- **Dasbor Streamlit**: Akses `https://localhost` atau `https://127.0.0.1`. Anda mungkin perlu menerima peringatan sertifikat *self-signed* di *browser* Anda.

**Akses Produksi/Server (dengan `ENABLE_CERTBOT=true` di `.env`):**
- **Dasbor Streamlit**: Akses `https://yourdomain.com` (ganti `yourdomain.com` dengan `DOMAIN` yang Anda atur di `.env`).

**Catatan tentang Akses Streamlit:**
Aplikasi ini dirancang untuk langsung menyajikan dasbor Streamlit sebagai halaman utama. Tidak ada halaman *login* atau halaman arahan terpisah sebelum dasbor. Ini berarti ketika Anda mengakses domain atau `localhost`, Anda akan langsung melihat dasbor pemantauan jaringan.

---

## ⚙️ Konfigurasi Suricata (Host System)

**Penting:** Suricata harus diinstal dan dikonfigurasi secara terpisah di *host system* Anda. Aplikasi Docker ini akan membaca log `eve.json` yang dihasilkan oleh Suricata di host Anda melalui *volume mounting*.

Skrip `build.sh` sekarang akan secara otomatis membuat dua file di direktori proyek Anda (`start_suricata.sh` dan `suricata.service`) yang akan membantu Anda menyiapkan Suricata di *host system* Anda.

### Langkah-langkah Manual di Host System Anda:

1.  **Instal Suricata:**
    *   **Untuk Ubuntu/Debian:**
        ```bash
        sudo add-apt-repository ppa:oisf/suricata-stable
        sudo apt-get update
        sudo apt-get install suricata suricata-update
        ```
    *   **Untuk Arch Linux:**
        ```bash
        sudo pacman -S suricata
        ```

2.  **Konfigurasi Sumber Aturan (Rules):**
    ```bash
    sudo suricata-update add-source et/open
    sudo suricata-update add-source oisf/trafficid
    ```

3.  **Perbarui Aturan:**
    ```bash
    sudo suricata-update
    ```

4.  **Konfigurasi `suricata.yaml` (Host System):**
    Edit file `/etc/suricata/suricata.yaml` di host Anda. Pastikan:
    *   `HOME_NET` dan `EXTERNAL_NET` dikonfigurasi dengan benar sesuai jaringan Anda.
    *   `default-log-dir` mengarah ke direktori yang akan di-*mount* ke kontainer Docker (yaitu, `/home/whoami/Downloads/monitoring_app/suricata_logs`).
    *   `outputs` -> `eve-log` diaktifkan (`enabled: yes`) dan mengarah ke `eve.json`.
    *   `pcap` -> `interface` diatur ke antarmuka jaringan *host* Anda (misalnya, `eth0`, `enp0s3`, `wlan0`).

5.  **Siapkan dan Jalankan Layanan Suricata (Menggunakan File yang Dihasilkan `build.sh`):**
    Setelah Anda menjalankan `./build.sh`, dua file akan dibuat di direktori proyek Anda:
    *   `start_suricata.sh`: Skrip pembantu untuk memulai Suricata dengan deteksi antarmuka otomatis.
    *   `suricata.service`: Berkas unit systemd untuk mengelola Suricata.

    Jalankan perintah berikut di terminal *host* Anda:
    ```bash
    sudo cp $(pwd)/start_suricata.sh /usr/local/bin/
    sudo chmod +x /usr/local/bin/start_suricata.sh
    sudo cp $(pwd)/suricata.service /etc/systemd/system/
    sudo systemctl daemon-reload
    sudo systemctl enable suricata
    sudo systemctl start suricata
    sudo systemctl status suricata
    ```

6.  **Verifikasi Log:**
    Pastikan `eve.json` sedang dibuat di direktori log yang benar (yaitu, `/home/whoami/Downloads/monitoring_app/suricata_logs`) dan berisi data. Anda bisa melihat isinya dengan `cat /home/whoami/Downloads/monitoring_app/suricata_logs/eve.json`.

---

## 🔧 Konfigurasi Tambahan

- **Rotasi Log Suricata**: Pastikan Anda mengkonfigurasi rotasi log untuk `eve.json` di *host system* Anda (misalnya, menggunakan `logrotate`) untuk menghemat sumber daya dan menjaga kinerja dasbor Streamlit.

---

## 🪪 Lisensi

MIT License © 2025
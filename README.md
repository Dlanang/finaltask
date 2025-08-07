Berikut isi `README.md` untuk project **All-in-One Monitoring Container** berbasis Docker:

---

````markdown
# 📦 All-in-One Monitoring App (Nginx + PHP + SQLite + Streamlit)

Project ini adalah solusi all-in-one yang ringan dan portable untuk menyajikan:

- ✅ Landing page & login system berbasis PHP + SQLite
- ✅ Streamlit dashboard untuk visualisasi monitoring/anomali
- ✅ Disajikan melalui satu container Docker

---

## 🛠 Tech Stack

| Komponen  | Fungsi                      |
|-----------|-----------------------------|
| Ubuntu    | Base image (22.04)          |
| Nginx     | Web server                  |
| PHP-FPM   | PHP interpreter             |
| SQLite3   | Lightweight DB for login    |
| Streamlit | Dashboard visualisasi data  |
| Bash      | Auto-setup & script         |

---

## 📂 Struktur Direktori

```bash
monitoring_app/
├── build.sh                # Script untuk build & run container
├── Dockerfile              # Image builder
├── default.conf            # Nginx config
├── entrypoint.sh           # Entrypoint untuk auto-start service
├── html/                   # PHP files (landing, login, dashboard)
│   ├── index.php
│   ├── login.php
│   ├── dashboard.php
│   └── db/
│       └── users.db        # SQLite DB (auto-create on first run)
├── app/                    # Streamlit app
│   └── dashboard.py
````

---

## 🚀 Cara Install & Run

### 1. Clone atau extract folder

```bash
git clone <repo>
# atau
unzip monitoring_app.zip && cd monitoring_app
```

### 2. Jalankan setup

```bash
chmod +x build.sh
./build.sh
```

### 3. Akses Web App

| Layanan      | URL                         |
| ------------ | --------------------------- |
| Landing Page | http\://<your-ip>/          |
| Login Page   | http\://<your-ip>/login.php |
| Streamlit    | http\://<your-ip>:8501      |

---

## 🔐 Default Credential (SQLite)

* **Username**: `admin`
* **Password**: `password`

Disimpan dalam database `html/db/users.db`. Bisa dimodifikasi manual via SQLite CLI.

---

## 🔧 Konfigurasi Tambahan

* **Nginx listen port**: 80 (public)
* **Streamlit listen port**: 8501 (bisa di-proxy via Nginx)
* **SQLite3**: ringan, tidak butuh daemon
* **Log**: belum terintegrasi Suricata – dapat di-mount via volume eksternal

---

## 📌 Catatan

* Dirancang untuk low-RAM VPS (RAM 1GB cukup)
* Semua service berjalan dalam 1 container
* Disarankan aktifkan HTTPS dengan reverse proxy (optional)
* Bisa dikembangkan dengan: Suricata, Grafana, Loki, dsb

---

## 🧪 Pengembangan Selanjutnya

* Integrasi Suricata log parser ke Streamlit
* Enkripsi password (bcrypt)
* Session token login (secure dashboard.php)
* Integrasi monitoring menggunakan Prometheus atau Loki

---

## 🧤 Developer Mode

Untuk rebuild image manual:

```bash
docker build -t all-in-one-monitoring .
docker run -d -p 80:80 -p 8501:8501 all-in-one-monitoring
```

---

## 🪪 Lisensi

MIT License © 2025

```

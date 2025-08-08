# Base image
FROM ubuntu:22.04

# Hindari prompt interaktif saat instalasi
ENV DEBIAN_FRONTEND=noninteractive

# Install dependensi dasar, Nginx, PHP, Python, Supervisor, dan Suricata
RUN apt-get update && apt-get install -y \
    software-properties-common \
    nginx \
    sqlite3 \
    python3-pip \
    python3-venv \
    supervisor \
    logrotate \
    cron \
    && apt-get update \
    && apt-get install -y certbot python3-certbot-nginx

# Install Streamlit & Pandas untuk analisis data
RUN pip install streamlit pandas bcrypt

# Buat direktori log untuk Suricata
RUN mkdir -p /var/log/suricata

# Salin file aplikasi dan konfigurasi
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY docker/streamlit/ /opt/app/
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
# Tambahkan cron job untuk logrotate
RUN echo "0 0 * * * /usr/sbin/logrotate /etc/logrotate.conf" >> /etc/crontab

# Expose port (meskipun network_mode: host, ini untuk dokumentasi)
EXPOSE 80 8501

# Jalankan Supervisor untuk mengelola semua proses
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

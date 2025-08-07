FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
  nginx php-fpm php-sqlite3 php-cli curl sqlite3 \
  python3 python3-pip \
  supervisor suricata

RUN pip3 install streamlit

RUN mkdir -p /var/www/html /var/log/supervisor /opt/app

COPY php/ /var/www/html/
COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY streamlit/app.py /opt/app/app.py
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80 8501 3000

CMD ["/usr/bin/supervisord", "-n"]

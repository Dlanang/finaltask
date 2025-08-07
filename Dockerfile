
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    nginx php php-fpm php-sqlite3 sqlite3 python3-pip python3-venv supervisor

# Install streamlit
RUN pip install streamlit

# Create user for streamlit
RUN useradd -m streamuser

# Setup directories
COPY html/ /var/www/html/
COPY php/ /var/www/html/
COPY db/ /var/www/db/
COPY streamlit/ /home/streamuser/app/

# Supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Nginx config
COPY nginx/default.conf /etc/nginx/sites-enabled/default

# Permissions
RUN chown -R www-data:www-data /var/www/html /var/www/db

EXPOSE 80 8501

CMD ["/usr/bin/supervisord"]

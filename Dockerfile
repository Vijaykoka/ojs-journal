# =============================================================================
# OJS 3.4+ Docker Image for Render Deployment
# Base: Ubuntu 22.04 + Nginx + PHP 8.1 + OJS
# =============================================================================

FROM ubuntu:22.04

LABEL description="Open Journal Systems 3.4 - Render-ready Docker image"
LABEL maintainer="Your Journal Team"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV OJS_VERSION=3.4.0-5

# ---------------------------------------------------------------------------
# Install system dependencies
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.1 \
    php8.1-fpm \
    php8.1-cli \
    php8.1-mysql \
    php8.1-pgsql \
    php8.1-xml \
    php8.1-mbstring \
    php8.1-gd \
    php8.1-curl \
    php8.1-zip \
    php8.1-intl \
    php8.1-soap \
    php8.1-bcmath \
    php8.1-gmp \
    php8.1-imagick \
    php8.1-opcache \
    php8.1-readline \
    php8.1-common \
    curl \
    wget \
    unzip \
    supervisor \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Configure PHP
# ---------------------------------------------------------------------------
RUN sed -i "s/memory_limit = .*/memory_limit = 256M/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/upload_max_filesize = .*/upload_max_filesize = 100M/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/post_max_size = .*/post_max_size = 100M/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/max_execution_time = .*/max_execution_time = 300/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/max_input_time = .*/max_input_time = 300/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/;max_input_vars = .*/max_input_vars = 6000/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/display_errors = On/display_errors = Off/" /etc/php/8.1/fpm/php.ini && \
    sed -i "s/listen = .*/listen = 0.0.0.0:9000/" /etc/php/8.1/fpm/pool.d/www.conf && \
    sed -i "s/;catch_workers_output = .*/catch_workers_output = yes/" /etc/php/8.1/fpm/pool.d/www.conf

# ---------------------------------------------------------------------------
# Download and install OJS
# ---------------------------------------------------------------------------
RUN mkdir -p /var/www && \
    cd /tmp && \
    wget -q "https://pkp.sfu.ca/ojs/download/ojs-${OJS_VERSION}.tar.gz" -O ojs.tar.gz && \
    tar -xzf ojs.tar.gz && \
    rm ojs.tar.gz && \
    mv "ojs-${OJS_VERSION}" /var/www/ojs

# Create required directories
RUN mkdir -p /var/www/ojs/files && \
    mkdir -p /var/www/ojs/cache && \
    mkdir -p /var/www/ojs/public

# ---------------------------------------------------------------------------
# Configure Nginx
# ---------------------------------------------------------------------------
RUN rm -f /etc/nginx/sites-enabled/default

COPY nginx.conf /etc/nginx/sites-available/ojs

RUN ln -sf /etc/nginx/sites-available/ojs /etc/nginx/sites-enabled/ojs && \
    rm -f /etc/nginx/sites-enabled/default && \
    sed -i "s/user www-data;/user www-data;\nworker_processes auto;/" /etc/nginx/nginx.conf && \
    sed -i "s/worker_connections 768;/worker_connections 1024;/" /etc/nginx/nginx.conf

# ---------------------------------------------------------------------------
# Configure Supervisor (runs both Nginx and PHP-FPM)
# ---------------------------------------------------------------------------
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# ---------------------------------------------------------------------------
# Entrypoint script (handles config setup at runtime)
# ---------------------------------------------------------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# ---------------------------------------------------------------------------
# Set permissions
# ---------------------------------------------------------------------------
RUN chown -R www-data:www-data /var/www/ojs && \
    chmod -R 755 /var/www/ojs && \
    chmod -R 775 /var/www/ojs/files && \
    chmod -R 775 /var/www/ojs/cache && \
    chmod -R 775 /var/www/ojs/public

# ---------------------------------------------------------------------------
# Expose ports
# ---------------------------------------------------------------------------
EXPOSE 8080

WORKDIR /var/www/ojs

ENTRYPOINT ["/entrypoint.sh"]

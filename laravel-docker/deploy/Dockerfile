ARG PHP_VERSION=7.1
FROM php:${PHP_VERSION}-fpm

# Arguments for User Permissions
ARG PUID=1000
ARG PGID=1000

# Fix for archived Debian versions (PHP 7.1 uses Debian Buster/Stretch)
RUN echo "deb http://archive.debian.org/debian buster main" > /etc/apt/sources.list && \
    echo "deb http://archive.debian.org/debian-security buster/updates main" >> /etc/apt/sources.list && \
    echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99no-check-valid-until

# Create 'work' user avoiding id conflicts
RUN groupadd -g ${PGID} work || groupmod -n work $(getent group ${PGID} | cut -d: -f1) \
    && useradd -u ${PUID} -g ${PGID} -m work || usermod -l work -g ${PGID} -u ${PUID} $(getent passwd ${PUID} | cut -d: -f1) \
    && mkdir -p /home/work/.composer \
    && chown -R work:work /home/work

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    supervisor \
    nginx \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd zip opcache

# Install Redis extension (Version 5.3.7 is compatible with PHP 7.1)
RUN pecl install -o -f redis-5.3.7 \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis

# Install Composer (Use 1.x for legacy Laravel 5.5/PHP 7.1 support)
COPY --from=composer:1 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Create log directory for Supervisor
RUN mkdir -p /var/log/supervisor

# Clean up apt cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

EXPOSE 80

# Start Supervisor (which manages Nginx and PHP-FPM)
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

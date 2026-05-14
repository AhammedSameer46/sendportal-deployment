FROM php:8.2-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    nginx \
    git \
    curl \
    unzip \
    zip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    exif \
    pcntl \
    bcmath \
    gd \
    zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# Copy files
COPY . .

# Install composer packages
RUN composer install --no-dev --optimize-autoloader

# Publish assets
RUN php artisan vendor:publish --tag=public --force || true

# Create fake mix manifest
RUN mkdir -p public/vendor/sendportal \
    && echo '{"/app.css":"/app.css","/app.js":"/app.js"}' > public/vendor/sendportal/mix-manifest.json

# Permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Laravel optimization
RUN php artisan config:clear || true
RUN php artisan cache:clear || true
RUN php artisan view:clear || true

# Create nginx config
RUN echo 'server { \
    listen 8080; \
    index index.php index.html; \
    server_name _; \
    root /var/www/public; \
    location / { \
        try_files $uri $uri/ /index.php?$query_string; \
    } \
    location ~ \.php$ { \
        fastcgi_pass 127.0.0.1:9000; \
        fastcgi_index index.php; \
        include fastcgi_params; \
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name; \
    } \
}' > /etc/nginx/sites-available/default

EXPOSE 8080

CMD service nginx start && php-fpm
FROM php:8.2-fpm

# Install system dependencies + Node.js
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    zip \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    npm

# Install Node.js 18
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs

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

# Set working directory
WORKDIR /var/www

# Copy project files
COPY . .

# Install frontend dependencies
RUN npm install

# Build frontend assets
RUN npm run prod

# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader

# Publish SendPortal assets
RUN php artisan vendor:publish --tag=public --force

# Set Laravel permissions
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

# Expose Railway port
EXPOSE 8080

# Start Laravel server
CMD php artisan serve --host=0.0.0.0 --port=8080
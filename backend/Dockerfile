FROM php:8.2-cli

# 安裝系統依賴
RUN apt-get update && apt-get install -y \
    git \
    curl \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    && docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd \
    && apt-get clean

# 安裝 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www

# 複製應用程式碼（vendor/ 已在 .dockerignore 排除）
COPY . .

# Build 階段安裝 PHP 依賴
RUN composer install --no-interaction --optimize-autoloader

# 設定 storage/cache 權限
RUN chmod -R 775 storage bootstrap/cache

RUN chmod +x /var/www/entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/var/www/entrypoint.sh"]

#!/bin/bash
set -e

echo "=== 啟動 Laravel 後端 ==="

# 如果 Laravel 尚未安裝，建立新專案
if [ ! -f "artisan" ]; then
    echo ">>> 安裝 Laravel（先裝到 /tmp 再移過來）..."
    composer create-project laravel/laravel /tmp/laravel-install --prefer-dist --no-interaction

    # 把 Laravel 檔案複製到 /var/www（不覆蓋已存在的檔案如 app_custom/）
    cp -rn /tmp/laravel-install/. /var/www/
    rm -rf /tmp/laravel-install

    echo ">>> 安裝 Laravel Sanctum（Token 認證）..."
    composer require laravel/sanctum --no-interaction

    echo ">>> 複製自訂認證程式碼..."
    cp /var/www/app_custom/AuthController.php /var/www/app/Http/Controllers/AuthController.php
    cp /var/www/app_custom/User.php /var/www/app/Models/User.php
    cp /var/www/app_custom/api.php /var/www/routes/api.php
fi

# 複製 .env（若不存在）
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
fi

# 設定資料庫連線（從環境變數覆蓋）
sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
sed -i "s/DB_PORT=.*/DB_PORT=${DB_PORT}/" .env
sed -i "s/DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env

# 安裝依賴（若 vendor 不存在）
if [ ! -d "vendor" ]; then
    composer install --no-interaction
fi

# 執行資料庫遷移（含 sanctum 的 personal_access_tokens 表）
echo ">>> 執行資料庫遷移..."
php artisan migrate --force

# 設定檔案權限
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

echo "=== 啟動開發伺服器 (port 8000) ==="
php artisan serve --host=0.0.0.0 --port=8000

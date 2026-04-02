#!/bin/bash
set -e

echo "=== 啟動 Laravel 後端 ==="

# 安裝依賴（docker-compose volume mount 時 host 可能沒有 vendor）
if [ ! -d "vendor" ]; then
    echo ">>> 安裝 PHP 依賴..."
    composer install --no-interaction --optimize-autoloader
fi

# 複製 .env（若不存在）
if [ ! -f ".env" ]; then
    cp .env.example .env
    php artisan key:generate
fi

# 設定資料庫連線（從容器環境變數覆蓋 .env）
sed -i "s/^DB_CONNECTION=.*/DB_CONNECTION=mysql/" .env
sed -i "s/^#*\s*DB_HOST=.*/DB_HOST=${DB_HOST}/" .env
sed -i "s/^#*\s*DB_PORT=.*/DB_PORT=${DB_PORT}/" .env
sed -i "s/^#*\s*DB_DATABASE=.*/DB_DATABASE=${DB_DATABASE}/" .env
sed -i "s/^#*\s*DB_USERNAME=.*/DB_USERNAME=${DB_USERNAME}/" .env
sed -i "s/^#*\s*DB_PASSWORD=.*/DB_PASSWORD=${DB_PASSWORD}/" .env

# 執行資料庫遷移
echo ">>> 執行資料庫遷移..."
php artisan migrate --force

chmod -R 775 storage bootstrap/cache 2>/dev/null || true

echo "=== 啟動開發伺服器 (port 8000) ==="
php artisan serve --host=0.0.0.0 --port=8000

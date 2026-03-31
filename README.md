# Auth Project — 全端登入系統練習

使用 **Laravel 12 + Vue 3** 實作的完整使用者認證系統，以 Docker Compose 一鍵啟動。

## 技術棧

| 層級 | 技術 |
|------|------|
| 後端 API | Laravel 12 + Laravel Sanctum |
| 前端 | Vue 3 + Vue Router + Axios |
| 資料庫 | MySQL 8.0 |
| 容器化 | Docker + Docker Compose |

## 功能

- 使用者註冊（姓名、Email、密碼）
- 使用者登入 / 登出
- Token 認證（Bearer Token，使用 Laravel Sanctum）
- 受保護的儀表板頁面（未登入自動跳轉）
- 前端路由守衛

## 專案結構

```
auth-project/
├── docker-compose.yml
├── backend/                    # Laravel API
│   ├── Dockerfile
│   ├── entrypoint.sh           # 容器啟動腳本
│   ├── app_custom/             # 自訂程式碼（啟動時覆蓋 Laravel 預設）
│   │   ├── AuthController.php  # 認證邏輯（register / login / logout / me）
│   │   ├── User.php            # User Model（含 HasApiTokens）
│   │   └── api.php             # API 路由定義
│   └── ...                     # Laravel 框架檔案（自動產生）
└── frontend/                   # Vue 3 前端
    ├── vite.config.js
    └── src/
        ├── api/auth.js         # 封裝 Axios API 呼叫
        ├── router/index.js     # 路由與守衛
        └── views/
            ├── LoginView.vue
            ├── RegisterView.vue
            └── DashboardView.vue
```

## 快速開始

### 前置需求

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) 已安裝並啟動

### 啟動

```bash
docker-compose up --build
```

第一次啟動約需 3-5 分鐘（需下載映像並安裝依賴）。

看到以下訊息表示啟動成功：

```
auth_app      | INFO  Server running on [http://0.0.0.0:8000].
auth_frontend | VITE v5.x.x  ready in xxxx ms
```

### 首次啟動後（僅需執行一次）

切換資料庫連線並執行 Migration：

```bash
docker exec auth_app sed -i "s/DB_CONNECTION=.*/DB_CONNECTION=mysql/" /var/www/.env
docker exec auth_app php artisan migrate --force
```

### 開啟瀏覽器

| 服務 | 網址 |
|------|------|
| 前端（Vue） | http://localhost:5173 |
| 後端 API | http://localhost:8000/api |

### 停止

```bash
docker-compose down
```

## API 端點

| 方法 | 路徑 | 說明 | 需要 Token |
|------|------|------|-----------|
| POST | `/api/register` | 註冊新帳號 | 否 |
| POST | `/api/login` | 登入取得 Token | 否 |
| POST | `/api/logout` | 登出並刪除 Token | 是 |
| GET | `/api/me` | 取得目前登入使用者 | 是 |

### 請求範例

**註冊**
```json
POST /api/register
{
  "name": "王小明",
  "email": "test@example.com",
  "password": "password123",
  "password_confirmation": "password123"
}
```

**登入**
```json
POST /api/login
{
  "email": "test@example.com",
  "password": "password123"
}
```

**回應（登入 / 註冊成功）**
```json
{
  "user": { "id": 1, "name": "王小明", "email": "test@example.com" },
  "token": "1|xxxxxxxxxxxxxxxx"
}
```

## 學習重點

- **Laravel Sanctum**：輕量 Token 認證，適合 SPA 與行動應用
- **Vue Router 守衛**：`beforeEnter` 保護需要登入的頁面
- **Axios 攔截器**：自動將 Token 附加到每個請求的 Header
- **Docker Compose**：多容器協作（PHP + MySQL + Node）

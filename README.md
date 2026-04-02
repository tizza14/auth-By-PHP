# Auth Project — 全端登入系統練習

使用 **Laravel 12 + Vue 3** 實作的完整使用者認證系統，以 Docker Compose 一鍵啟動，並附 Kubernetes 本地部署設定。

## 技術棧

| 層級 | 技術 |
|------|------|
| 後端 API | Laravel 12 + Laravel Sanctum |
| 前端 | Vue 3 + Vue Router + Pinia + Axios |
| 資料庫 | MySQL 8.0 |
| 快取 | Redis |
| 容器化 | Docker + Docker Compose |
| 容器編排 | Kubernetes（本地 Docker Desktop K8s） |

## 功能

- 使用者註冊（姓名、Email、密碼）
- 使用者登入 / 登出
- Token 認證（Bearer Token，使用 Laravel Sanctum）
- 受保護的儀表板頁面（未登入自動跳轉）
- 全域路由守衛（global beforeEach）
- 401 自動攔截並跳轉登入頁
- 防重複送出（loading guard）
- Pinia Store 快取使用者資料（避免重複呼叫 /me）
- Redis 快取 / Session 加速

## 專案結構

```
auth-By-PHP/
├── docker-compose.yml
├── docs/
│   └── laravel-learning-map.md   # 學習地圖文件
├── k8s/                          # Kubernetes 部署設定
│   ├── namespace.yaml
│   ├── secret.yaml
│   ├── configmap.yaml
│   ├── mysql/
│   │   ├── pvc.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── redis/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── app/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── frontend/
│       ├── deployment.yaml
│       └── service.yaml
├── backend/                      # Laravel API
│   ├── Dockerfile
│   ├── entrypoint.sh             # 容器啟動腳本
│   ├── app_custom/               # 自訂程式碼（啟動時覆蓋 Laravel 預設）
│   │   ├── AuthController.php    # 認證邏輯（register / login / logout / me）
│   │   ├── User.php              # User Model（含 HasApiTokens）
│   │   └── api.php               # API 路由定義
│   └── ...                       # Laravel 框架檔案（自動產生）
└── frontend/                     # Vue 3 前端
    ├── vite.config.js
    └── src/
        ├── api/auth.js           # Axios 封裝 + 401 攔截器
        ├── stores/auth.js        # Pinia Store（快取 /me）
        ├── router/index.js       # 全域路由守衛
        └── views/
            ├── LoginView.vue
            ├── RegisterView.vue
            └── DashboardView.vue
```

## 快速開始（Docker Compose）

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

> `entrypoint.sh` 會自動處理：安裝依賴、設定 DB 連線、執行 Migration，無需手動操作。

### 開啟瀏覽器

| 服務 | 網址 |
|------|------|
| 前端（Vue） | http://localhost:5173 |
| 後端 API | http://localhost:8000/api |

### 停止

```bash
docker-compose down
```

## 快速開始（Kubernetes 本地）

### 前置需求

1. Docker Desktop 已啟用 Kubernetes（Settings → Kubernetes → Enable Kubernetes）
2. 已在本地 build app 映像：
   ```bash
   docker build -t auth-by-php-app:latest ./backend
   ```

### 套用所有設定

**必須先建立 namespace**，再套用其餘資源（避免字母順序導致的 NotFound 錯誤）：

```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -R -f k8s/
```

### 開啟瀏覽器（K8s NodePort）

| 服務 | 網址 |
|------|------|
| 前端（Vue） | http://localhost:30173 |
| 後端 API | http://localhost:30800/api |

### 常用指令

```bash
# 查看所有 Pod 狀態
kubectl get pods -n auth-app

# 查看 Pod 日誌
kubectl logs -n auth-app <pod-name>

# 刪除所有資源
kubectl delete namespace auth-app
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
- **Redis**：作為快取與 Session 儲存，加速後端回應
- **Vue Router 全域守衛**：`router.beforeEach` 統一保護需要登入的頁面
- **Axios 攔截器**：自動附加 Token Header，自動處理 401 跳轉
- **Pinia Store**：快取 `/me` 結果，避免重複 API 呼叫
- **防重複送出**：loading 狀態早返回，防止按鈕連點
- **Docker Compose**：多容器協作（PHP + MySQL + Redis + Node）
- **Kubernetes**：Namespace / Secret / ConfigMap / Deployment / Service / PVC 本地實作

## 學習地圖

詳細學習路線請參考 [docs/laravel-learning-map.md](docs/laravel-learning-map.md)

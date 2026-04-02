# Laravel 後端學習地圖

> 以 `auth-By-PHP` 專案為範例，從零開始理解 Laravel 後端架構。

---

## 目錄

1. [整體資料流](#整體資料流)
2. [第一階段：Migration（建立資料表）](#第一階段migrationcreate-users-tablemigration建立資料表)
3. [第二階段：Model（對應資料表）](#第二階段model對應資料表)
4. [第三階段：Route（定義 API 路由）](#第三階段route定義-api-路由)
5. [第四階段：Controller（處理邏輯）](#第四階段controller處理邏輯)
6. [第五階段：Factory（產生測試資料）](#第五階段factory產生測試資料)
7. [第六階段：Redis（快取與加速）](#第六階段redis快取與加速)
8. [第七階段：Kubernetes（容器編排）](#第七階段kubernetes容器編排)
9. [常用 Artisan 指令](#常用-artisan-指令)
10. [學習順序建議](#學習順序建議)

---

## 整體資料流

```
HTTP 請求 (POST /api/register)
    ↓
routes/api.php              → 決定誰來處理這個請求
    ↓
AuthController.php          → 驗證輸入、執行業務邏輯
    ↓
User.php (Model)            → 對應 users 資料表的操作
    ↓
MySQL                       → 透過 Migration 建立的實際資料表
```

---

## 第一階段：Migration（建立資料表）

**檔案位置：** `backend/database/migrations/0001_01_01_000000_create_users_table.php`

Migration 的作用是用 PHP 程式碼定義資料表結構，取代手動在 MySQL 建表。

### 程式碼說明

```php
Schema::create('users', function (Blueprint $table) {
    $table->id();                                       // 自動遞增主鍵（id）
    $table->string('name');                             // VARCHAR 欄位
    $table->string('email')->unique();                  // VARCHAR，且不能重複
    $table->timestamp('email_verified_at')->nullable(); // 時間欄位，允許 null
    $table->string('password');                         // 儲存 hash 過的密碼
    $table->rememberToken();                            // 記住我功能的 token
    $table->timestamps();                               // 自動產生 created_at + updated_at
});
```

### up() vs down()

| 方法 | 執行時機 | 作用 |
|---|---|---|
| `up()` | `php artisan migrate` | 建立資料表 |
| `down()` | `php artisan migrate:rollback` | 刪除資料表（還原） |

### 常用欄位類型

| 方法 | MySQL 類型 | 說明 |
|---|---|---|
| `$table->id()` | BIGINT UNSIGNED | 自動遞增主鍵 |
| `$table->string('name')` | VARCHAR(255) | 字串 |
| `$table->text('bio')` | TEXT | 長文字 |
| `$table->integer('age')` | INT | 整數 |
| `$table->boolean('active')` | TINYINT | 布林值 |
| `$table->timestamp('verified_at')` | TIMESTAMP | 時間戳 |
| `$table->timestamps()` | — | 自動加上 created_at + updated_at |

### 常用修飾符

| 修飾符 | 說明 |
|---|---|
| `->nullable()` | 允許欄位值為 null |
| `->unique()` | 欄位值不能重複 |
| `->default('value')` | 設定預設值 |
| `->unsigned()` | 不允許負數 |

---

## 第二階段：Model（對應資料表）

**檔案位置：** `backend/app/Models/User.php`

Model 是 Laravel 中代表一張資料表的 PHP 類別，一個 Model 對應一張表。

### 程式碼說明

```php
class User extends Authenticatable
{
    use HasApiTokens;   // 讓這個 Model 可以產生 Sanctum Token
    use HasFactory;     // 讓這個 Model 可以使用 Factory 產生假資料
    use Notifiable;     // 讓這個 Model 可以發送通知（email 等）

    // 允許被批量寫入的欄位
    // 沒有列在這裡的欄位，User::create() 時會被自動忽略（防止惡意注入）
    protected $fillable = [
        'name',
        'email',
        'password',
    ];

    // 回傳 JSON 時自動隱藏這些欄位，不會洩漏給前端
    protected $hidden = [
        'password',
        'remember_token',
    ];

    // 欄位的型別轉換
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime', // 自動轉成 Carbon 時間物件
            'password' => 'hashed',            // 存入時自動 hash
        ];
    }
}
```

### $fillable 的重要性

`$fillable` 是 Laravel 的**大量賦值保護（Mass Assignment Protection）**。

```php
// 有設定 $fillable = ['name', 'email', 'password']
// 這樣寫是安全的
User::create($request->all());

// 如果惡意使用者傳入 is_admin=1，因為 is_admin 不在 $fillable 裡，會被自動忽略
```

---

## 第三階段：Route（定義 API 路由）

**檔案位置：** `backend/routes/api.php`

Route 決定「哪個 URL」交給「哪個 Controller 的哪個方法」處理。

### 程式碼說明

```php
// 公開路由：任何人都可以打，不需要登入
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

// 受保護路由：需要在 Header 帶上 Bearer Token 才能打
// Authorization: Bearer <token>
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me',      [AuthController::class, 'me']);
});
```

### 對應的 HTTP 方法

| Route 方法 | HTTP 方法 | 常見用途 |
|---|---|---|
| `Route::get()` | GET | 查詢資料 |
| `Route::post()` | POST | 新增資料 |
| `Route::put()` | PUT | 完整更新 |
| `Route::patch()` | PATCH | 部分更新 |
| `Route::delete()` | DELETE | 刪除資料 |

### Middleware

Middleware 是請求的「過濾層」，在進入 Controller 之前執行檢查。

```
HTTP 請求 → Middleware 檢查 → Controller（通過才能進入）
```

`auth:sanctum` 會檢查 Header 是否有有效的 Token，沒有則回傳 `401 Unauthorized`。

---

## 第四階段：Controller（處理邏輯）

**檔案位置：** `backend/app/Http/Controllers/AuthController.php`

Controller 是實際處理請求邏輯的地方。

### Register 流程

```php
public function register(Request $request)
{
    // Step 1：驗證輸入
    // 驗證失敗時，Laravel 自動回傳 422 錯誤，不會繼續執行
    $validated = $request->validate([
        'name'     => 'required|string|max:255',
        'email'    => 'required|string|email|max:255|unique:users', // email 不能重複
        'password' => 'required|string|min:8|confirmed',            // 需要 password_confirmation 欄位
    ]);

    // Step 2：寫入資料庫
    $user = User::create([
        'name'     => $validated['name'],
        'email'    => $validated['email'],
        'password' => Hash::make($validated['password']), // 密碼加密後再存
    ]);

    // Step 3：產生 Token 並回傳
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'user'  => $user,   // password 欄位因為 $hidden 設定，不會出現在回應中
        'token' => $token,
    ], 201); // 201 = Created
}
```

### 常用驗證規則

| 規則 | 說明 |
|---|---|
| `required` | 必填 |
| `string` | 必須是字串 |
| `email` | 必須是合法 email 格式 |
| `min:8` | 最少 8 個字元 |
| `max:255` | 最多 255 個字元 |
| `unique:users` | 在 users 表中不能重複 |
| `confirmed` | 需要同名加上 `_confirmation` 的欄位，且值相同 |
| `nullable` | 允許為空 |

### HTTP 狀態碼

| 狀態碼 | 意義 |
|---|---|
| 200 | 成功 |
| 201 | 新增成功 |
| 401 | 未授權（沒有 Token） |
| 422 | 驗證失敗（輸入格式錯誤） |
| 500 | 伺服器錯誤 |

---

## 第五階段：Factory（產生測試資料）

**檔案位置：** `backend/database/factories/UserFactory.php`

Factory 用來快速產生假資料，主要用於測試或開發時填充 DB。

### 程式碼說明

```php
class UserFactory extends Factory
{
    public function definition(): array
    {
        return [
            'name'              => fake()->name(),               // 產生假名字，如 "John Doe"
            'email'             => fake()->unique()->safeEmail(), // 產生不重複的假 email
            'email_verified_at' => now(),                        // 設定為已驗證
            'password'          => Hash::make('password'),       // 所有假帳號密碼都是 "password"
            'remember_token'    => Str::random(10),              // 隨機 10 碼字串
        ];
    }

    // 狀態方法：產生未驗證 email 的使用者
    public function unverified(): static
    {
        return $this->state(fn (array $attributes) => [
            'email_verified_at' => null, // 覆蓋預設值
        ]);
    }
}
```

### 使用方式

```bash
# 進入 Laravel 互動環境
php artisan tinker

# 建立 1 筆假資料並寫入 DB
User::factory()->create();

# 建立 10 筆假資料
User::factory(10)->create();

# 建立未驗證 email 的使用者
User::factory()->unverified()->create();

# 只產生假資料但不寫入 DB（用於測試）
User::factory()->make();
```

---

## 第六階段：Redis（快取與加速）

Redis 是獨立的**記憶體資料庫**，資料存在 RAM，速度遠快於 MySQL。

### 與 MySQL 的差異

| | MySQL | Redis |
|---|---|---|
| 儲存位置 | 硬碟 | 記憶體（RAM） |
| 速度 | 較慢 | 極快 |
| 資料結構 | 表格 | Key-Value |
| 資料持久性 | 永久保存 | 預設重啟會消失 |
| 適合用途 | 主要資料儲存 | 暫存、快取、Queue |

### 這個專案的設定

**docker-compose.yml** — 新增 Redis container
```yaml
redis:
  image: redis:alpine
  container_name: auth_redis
  ports:
    - "6379:6379"
```

**composer.json** — 安裝 PHP 連線套件
```bash
composer require predis/predis
```

**.env** — 指向 Docker 內的 Redis container
```env
REDIS_CLIENT=predis
REDIS_HOST=redis      # container 名稱，不是 127.0.0.1
REDIS_PORT=6379
```

> `REDIS_HOST=redis` 而不是 `127.0.0.1`，因為在 Docker 網路中要用 container 名稱互相溝通。

### 常見用途

**1. Cache（快取）**
```php
// 第一次從 DB 撈，之後從 Redis 取（快 10 倍以上）
$users = Cache::remember('all_users', 60, function () {
    return User::all();
});
```

**2. Session**
```env
SESSION_DRIVER=redis   # 把 session 存在 Redis，比存 DB 快
```

**3. Queue（排隊背景任務）**
```env
QUEUE_CONNECTION=redis  # 發 email、處理圖片等耗時工作排隊執行
```

**4. Rate Limiting（限流）**
```php
// 同一個 IP 每分鐘最多打 60 次 API
RateLimiter::for('api', function (Request $request) {
    return Limit::perMinute(60)->by($request->ip());
});
```

### 類比

```
MySQL  = 主倉庫（放所有重要資料）
Redis  = 旁邊的小抽屜（放常用的東西，拿起來更快）
```

---

## 第七階段：Kubernetes（容器編排）

Kubernetes（k8s）是管理多個 container 的系統，比 docker-compose 更強大，適合正式環境與多節點部署。

### Docker Compose vs Kubernetes

| | Docker Compose | Kubernetes |
|---|---|---|
| 適合情境 | 本機開發 | 正式環境、雲端 |
| 管理單位 | container | Pod（可包含多個 container）|
| 自動重啟 | 需設定 | 內建，Pod 掛掉自動重建 |
| 水平擴展 | 手動 | `replicas: 3` 一行搞定 |
| 負載均衡 | 無 | 內建 Service 負載均衡 |
| 設定管理 | `.env` 檔 | ConfigMap / Secret |

### 這個專案的 k8s 結構

```
k8s/
├── namespace.yaml       # 隔離用的命名空間
├── secret.yaml          # 敏感資料（DB 密碼等）
├── configmap.yaml       # 非敏感設定（host / port）
├── mysql/
│   ├── pvc.yaml         # 持久化儲存（資料不會因 Pod 重啟而消失）
│   ├── deployment.yaml  # MySQL Pod 定義
│   └── service.yaml     # 讓其他 Pod 能連到 MySQL
├── redis/
│   ├── deployment.yaml
│   └── service.yaml
├── app/
│   ├── deployment.yaml  # Laravel Pod（imagePullPolicy: Never 用本地 image）
│   └── service.yaml     # NodePort 30800 → 對外開放
└── frontend/
    ├── deployment.yaml
    └── service.yaml     # NodePort 30173 → 對外開放
```

### 核心概念

**Pod** — k8s 最小部署單位，通常包含一個 container
```yaml
spec:
  containers:
    - name: mysql
      image: mysql:8.0
```

**Deployment** — 管理 Pod，設定幾個副本、如何更新
```yaml
spec:
  replicas: 1   # 要跑幾個 Pod
```

**Service** — 讓 Pod 可以被其他 Pod 或外部存取
```yaml
# ClusterIP（預設）：只有叢集內部可連
# NodePort：開放給外部，透過 localhost:nodePort 存取
type: NodePort
nodePort: 30800
```

**ConfigMap** — 存放非敏感的環境變數
```yaml
data:
  DB_HOST: mysql   # 直接用 Service 名稱，k8s 內建 DNS 會解析
```

**Secret** — 存放敏感資料（密碼等），base64 編碼儲存
```yaml
stringData:
  DB_PASSWORD: secret
```

**PVC（PersistentVolumeClaim）** — 申請持久化儲存空間，讓 MySQL 資料不隨 Pod 消失
```yaml
resources:
  requests:
    storage: 1Gi
```

### 本地啟動步驟（Docker Desktop）

**前置條件：** 在 Docker Desktop → Settings → Kubernetes → Enable Kubernetes

```bash
# 1. build 後端 image（需在 k8s 能存取的 Docker daemon 中）
docker build -t auth-by-php-app:latest ./backend

# 2. 建立所有 k8s 資源
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/mysql/
kubectl apply -f k8s/redis/
kubectl apply -f k8s/app/
kubectl apply -f k8s/frontend/

# 或一次套用所有（遞迴）
kubectl apply -R -f k8s/

# 3. 查看狀態
kubectl get all -n auth-app
```

### 常用 kubectl 指令

```bash
kubectl get pods -n auth-app              # 查看所有 Pod 狀態
kubectl get services -n auth-app          # 查看所有 Service
kubectl logs -n auth-app <pod-name>       # 查看 Pod 日誌
kubectl describe pod -n auth-app <pod>    # 詳細診斷 Pod
kubectl exec -it -n auth-app <pod> -- sh  # 進入 Pod 內部

# 刪除所有資源
kubectl delete -R -f k8s/
```

### 服務對外 Port

| 服務 | 存取網址 |
|---|---|
| Laravel API | `http://localhost:30800` |
| Vue 前端 | `http://localhost:30173` |

---

## 常用 Artisan 指令

```bash
# Migration
php artisan migrate                  # 執行所有未跑過的 migration
php artisan migrate:rollback         # 還原最後一批 migration
php artisan migrate:fresh            # 刪除所有表，重新執行所有 migration
php artisan migrate:fresh --seed     # 重建表並執行 Seeder 填入假資料
php artisan migrate:status           # 查看各 migration 是否已執行

# 產生新檔案
php artisan make:model Post                      # 建立 Model
php artisan make:controller PostController       # 建立 Controller
php artisan make:migration create_posts_table    # 建立 Migration
php artisan make:factory PostFactory             # 建立 Factory

# 其他
php artisan route:list               # 列出所有路由
php artisan tinker                   # 進入互動式環境
```

---

## 學習順序建議

```
1. Migration（建表）
        ↓
2. Model（對應表，設定 $fillable / $hidden）
        ↓
3. Route（定義 URL 對應關係）
        ↓
4. Controller（撰寫業務邏輯）
        ↓
5. Factory（產生測試資料，驗證功能）
        ↓
6. Redis（加速 Cache / Session / Queue）
        ↓
7. Kubernetes（容器編排、正式環境部署）
```

**理解核心概念後，下一步可以學：**
- Eloquent 關聯（一對多、多對多）
- Resource Controller（RESTful 標準寫法）
- Form Request（把驗證邏輯獨立出 Controller）
- Policy & Gate（權限控制）
- Queue & Job（背景任務搭配 Redis）
- Ingress（k8s 的反向代理，取代 NodePort）

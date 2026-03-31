<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

// 公開路由（不需要登入）
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

// 受保護路由（需要帶 Bearer Token）
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me',      [AuthController::class, 'me']);
});

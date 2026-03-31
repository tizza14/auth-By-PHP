<template>
  <div class="card">
    <h2>儀表板</h2>

    <div v-if="loading" style="text-align:center; color:#666">載入中...</div>

    <div v-else-if="user">
      <p style="margin-bottom:1rem; color:#555; text-align:center">
        歡迎回來！
      </p>

      <div class="user-info">
        <div class="info-row">
          <span class="label">姓名</span>
          <span>{{ user.name }}</span>
        </div>
        <div class="info-row">
          <span class="label">Email</span>
          <span>{{ user.email }}</span>
        </div>
        <div class="info-row">
          <span class="label">加入時間</span>
          <span>{{ formatDate(user.created_at) }}</span>
        </div>
      </div>

      <button @click="handleLogout" :disabled="logoutLoading" style="margin-top:1.5rem">
        {{ logoutLoading ? '登出中...' : '登出' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { authApi } from '../api/auth'

const router = useRouter()
const user = ref(null)
const loading = ref(true)
const logoutLoading = ref(false)

// 頁面載入時取得使用者資訊
onMounted(async () => {
  try {
    const response = await authApi.me()
    user.value = response.data
  } catch {
    // Token 無效，回到登入頁
    localStorage.removeItem('token')
    router.push('/login')
  } finally {
    loading.value = false
  }
})

async function handleLogout() {
  logoutLoading.value = true
  try {
    await authApi.logout()
  } finally {
    localStorage.removeItem('token')
    router.push('/login')
  }
}

function formatDate(dateStr) {
  return new Date(dateStr).toLocaleDateString('zh-TW')
}
</script>

<style scoped>
.user-info {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid #eee;
}

.info-row:last-child {
  border-bottom: none;
}

.label {
  color: #888;
  font-size: 0.9rem;
}
</style>

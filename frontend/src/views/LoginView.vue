<template>
  <div class="card">
    <h2>登入</h2>

    <!-- 錯誤提示 -->
    <div v-if="error" class="error">{{ error }}</div>

    <form @submit.prevent="handleLogin">
      <div class="form-group">
        <label>Email</label>
        <input v-model="form.email" type="email" placeholder="your@email.com" required />
      </div>

      <div class="form-group">
        <label>密碼</label>
        <input v-model="form.password" type="password" placeholder="輸入密碼" required />
      </div>

      <button type="submit" :disabled="loading">
        {{ loading ? '登入中...' : '登入' }}
      </button>
    </form>

    <div class="link-text">
      還沒有帳號？
      <a @click="$router.push('/register')">立即註冊</a>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { authApi } from '../api/auth'

const router = useRouter()

const form = ref({ email: '', password: '' })
const loading = ref(false)
const error = ref('')

async function handleLogin() {
  if (loading.value) return
  loading.value = true
  error.value = ''

  try {
    const response = await authApi.login(form.value)
    // 把 Token 存到 localStorage
    localStorage.setItem('token', response.data.token)
    // 跳到儀表板
    router.push('/dashboard')
  } catch (err) {
    error.value = err.response?.data?.message || '帳號或密碼錯誤'
  } finally {
    loading.value = false
  }
}
</script>

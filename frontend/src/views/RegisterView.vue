<template>
  <div class="card">
    <h2>註冊帳號</h2>

    <div v-if="error" class="error">{{ error }}</div>

    <form @submit.prevent="handleRegister">
      <div class="form-group">
        <label>姓名</label>
        <input v-model="form.name" type="text" placeholder="你的名字" required />
      </div>

      <div class="form-group">
        <label>Email</label>
        <input v-model="form.email" type="email" placeholder="your@email.com" required />
      </div>

      <div class="form-group">
        <label>密碼</label>
        <input v-model="form.password" type="password" placeholder="至少 8 個字元" required />
      </div>

      <div class="form-group">
        <label>確認密碼</label>
        <input v-model="form.password_confirmation" type="password" placeholder="再輸入一次密碼" required />
      </div>

      <button type="submit" :disabled="loading">
        {{ loading ? '註冊中...' : '建立帳號' }}
      </button>
    </form>

    <div class="link-text">
      已有帳號？
      <a @click="$router.push('/login')">直接登入</a>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { authApi } from '../api/auth'

const router = useRouter()

const form = ref({
  name: '',
  email: '',
  password: '',
  password_confirmation: ''
})
const loading = ref(false)
const error = ref('')

async function handleRegister() {
  loading.value = true
  error.value = ''

  try {
    const response = await authApi.register(form.value)
    localStorage.setItem('token', response.data.token)
    router.push('/dashboard')
  } catch (err) {
    // 顯示驗證錯誤（例如 email 重複）
    const errors = err.response?.data?.errors
    if (errors) {
      error.value = Object.values(errors).flat().join('、')
    } else {
      error.value = err.response?.data?.message || '註冊失敗，請稍後再試'
    }
  } finally {
    loading.value = false
  }
}
</script>

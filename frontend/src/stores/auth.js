import { defineStore } from 'pinia'
import { ref } from 'vue'
import { authApi } from '../api/auth'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(null)

  // 取得使用者資料（若已有快取則不重複打 API）
  async function fetchMe() {
    if (user.value) return
    const response = await authApi.me()
    user.value = response.data
  }

  function clearUser() {
    user.value = null
  }

  return { user, fetchMe, clearUser }
})

import axios from 'axios'
import router from '../router'

// 所有 API 請求都透過 Vite proxy 轉發到 Laravel
const api = axios.create({
  baseURL: '/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  }
})

// 每次請求前自動帶上 token（若有的話）
api.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 回應攔截器：token 過期或無效時自動登出
api.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      localStorage.removeItem('token')
      router.push('/login')
    }
    return Promise.reject(error)
  }
)

export const authApi = {
  // 註冊
  register(data) {
    return api.post('/register', data)
  },

  // 登入
  login(data) {
    return api.post('/login', data)
  },

  // 登出
  logout() {
    return api.post('/logout')
  },

  // 取得目前登入的使用者
  me() {
    return api.get('/me')
  }
}

import axios from 'axios'

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

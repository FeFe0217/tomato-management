import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'

// 创建 Vue 应用
const app = createApp(App)

// 注册路由
app.use(router)

// 挂载应用
app.mount('#app')

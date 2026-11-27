import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  base: '/tomato-management/',
  plugins: [vue()],
})

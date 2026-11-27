import { createRouter, createWebHashHistory } from 'vue-router'

import DashboardView from '../views/DashboardView.vue'
import EnvironmentView from '../views/EnvironmentView.vue'
import IrrigationView from '../views/IrrigationView.vue'
import GrowthView from '../views/GrowthView.vue'
import AnalyticsView from '../views/AnalyticsView.vue'

// 五个页面的路由配置
const routes = [
  {
    path: '/',
    redirect: '/overview'
  },
  {
    path: '/overview',
    name: 'Overview',
    component: DashboardView
  },
  {
    path: '/environment',
    name: 'Environment',
    component: EnvironmentView
  },
  {
    path: '/irrigation',
    name: 'Irrigation',
    component: IrrigationView
  },
  {
    path: '/growth',
    name: 'Growth',
    component: GrowthView
  },
  {
    path: '/analytics',
    name: 'Analytics',
    component: AnalyticsView
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/overview'
  }
]

// 创建路由实例
const router = createRouter({
  history: createWebHashHistory(import.meta.env.BASE_URL),
  routes
})

export default router



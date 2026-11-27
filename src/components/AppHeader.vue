<script setup>
import { RouterLink } from "vue-router"

const navItems = [
  { label: "综合总览", path: "/overview" },
  { label: "环境监测", path: "/environment" },
  { label: "水肥管理", path: "/irrigation" },
  { label: "生长监测", path: "/growth" },
  { label: "数据分析", path: "/analytics" }
]
</script>

<template>
  <header class="top-header">
    <div class="header-inner">

      <div class="brand">
        <div class="brand-logo">🍅</div>

        <div class="brand-info">
          <h1>智慧番茄种植管理平台</h1>
          <p>Smart Tomato Cultivation Management System</p>
        </div>
      </div>

      <nav class="top-nav">
        <RouterLink
          v-for="item in navItems"
          :key="item.path"
          :to="item.path"
          class="nav-item"
          exact-active-class="nav-active"
        >
          {{ item.label }}
        </RouterLink>
      </nav>

      <div class="header-right">

        <div class="date-time">
          <span class="clock-icon">◷</span>
          <div class="date-lines">
            <strong>2026-04-22</strong>
            <strong>15:30:46</strong>
            <small>星期三</small>
          </div>
        </div>

        <div class="header-status">
          <i></i>
          <span>系统运行中</span>
        </div>

        <div class="user-avatar">♟</div>

      </div>

    </div>
  </header>
</template>

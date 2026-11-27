<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()
const goEnvironment = () => router.push('/environment')
const goIrrigation = () => router.push('/irrigation')
const goGrowth = () => router.push('/growth')
import { ref, onMounted, onBeforeUnmount, nextTick } from "vue"
import * as echarts from "echarts"

const envChart = ref(null)
const waterChart = ref(null)
const growthChart = ref(null)
const maturityChart = ref(null)

let charts = []

const environmentMetrics = [
  { label: "空气温度", value: "26.5", unit: "℃", icon: "🌡️", change: "↑0.3", color: "temperature" },
  { label: "空气湿度", value: "68", unit: "%", icon: "💧", change: "↑1.2", color: "humidity" },
  { label: "土壤湿度", value: "52", unit: "%", icon: "🪴", change: "↓0.5", color: "soil" },
  { label: "光照强度", value: "12000", unit: "lx", icon: "☀️", change: "↑120", color: "light" }
]

const fruitStages = [
  { name: "青果", count: 40, color: "green", chartColor: "cyan", percent: "31.3%" },
  { name: "转色果", count: 35, color: "yellow", chartColor: "chart-green", percent: "27.3%" },
  { name: "成熟果", count: 53, color: "red", chartColor: "orange", percent: "41.4%" }
]

const alerts = [
  { title: "土壤湿度接近下限", time: "04-22 14:20", type: "warning", icon: "⚠" },
  { title: "环境数据正常", time: "04-22 13:50", type: "success", icon: "✓" },
  { title: "灌溉任务已完成", time: "04-22 12:30", type: "info", icon: "i" }
]

function initCharts() {
  if (envChart.value) {
    const chart = echarts.init(envChart.value)

    chart.setOption({
      backgroundColor: "transparent",
      tooltip: {
        trigger: "axis",
        backgroundColor: "#082b48",
        borderColor: "#087fae",
        textStyle: { color: "#eaf7ff" }
      },
      legend: {
        top: 0,
        left: "center",
        itemWidth: 10,
        itemHeight: 10,
        textStyle: { color: "#a8c2d7", fontSize: 11 },
        data: ["温度", "湿度"]
      },
      grid: { left: 36, right: 12, top: 35, bottom: 24 },
      xAxis: {
        type: "category",
        boundaryGap: false,
        data: ["00:00", "06:00", "12:00", "18:00", "24:00"],
        axisLine: { lineStyle: { color: "#244c68" } },
        axisTick: { show: false },
        axisLabel: { color: "#9ab3c8", fontSize: 10 }
      },
      yAxis: {
        type: "value",
        min: 0,
        max: 100,
        interval: 25,
        axisLabel: { color: "#9ab3c8", fontSize: 10 },
        splitLine: { lineStyle: { color: "rgba(70,130,165,.15)" } },
        axisLine: { show: false }
      },
      series: [
        {
          name: "温度",
          type: "line",
          smooth: true,
          showSymbol: false,
          data: [58, 76, 45, 77, 72],
          lineStyle: { width: 2, color: "#ff9f32" },
          itemStyle: { color: "#ff9f32" },
          areaStyle: { color: "rgba(255,159,50,.06)" }
        },
        {
          name: "湿度",
          type: "line",
          smooth: true,
          showSymbol: false,
          data: [28, 52, 55, 75, 48],
          lineStyle: { width: 2, color: "#19b9f2" },
          itemStyle: { color: "#19b9f2" },
          areaStyle: { color: "rgba(25,185,242,.07)" }
        }
      ]
    })

    charts.push(chart)
  }

  if (waterChart.value) {
    const chart = echarts.init(waterChart.value)

    chart.setOption({
      backgroundColor: "transparent",
      tooltip: {
        trigger: "axis",
        backgroundColor: "#082b48",
        borderColor: "#087fae",
        textStyle: { color: "#eaf7ff" }
      },
      grid: { left: 30, right: 10, top: 15, bottom: 23 },
      xAxis: {
        type: "category",
        data: ["4/16", "4/18", "4/19", "4/20", "4/21", "4/22"],
        axisLine: { lineStyle: { color: "#244c68" } },
        axisTick: { show: false },
        axisLabel: { color: "#a3bdd1", fontSize: 10 }
      },
      yAxis: {
        type: "value",
        min: 0,
        max: 20,
        interval: 5,
        axisLabel: { color: "#a3bdd1", fontSize: 10 },
        splitLine: { lineStyle: { color: "rgba(70,130,165,.15)" } }
      },
      series: [{
        type: "bar",
        barWidth: "34%",
        data: [8, 9, 10, 9, 9, 15],
        itemStyle: {
          borderRadius: [4, 4, 0, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
            { offset: 0, color: "#22c8f4" },
            { offset: 1, color: "#0876b1" }
          ])
        }
      }]
    })

    charts.push(chart)
  }

  if (growthChart.value) {
    const chart = echarts.init(growthChart.value)

    chart.setOption({
      backgroundColor: "transparent",
      tooltip: {
        trigger: "axis",
        backgroundColor: "#082b48",
        borderColor: "#087fae",
        textStyle: { color: "#eaf7ff" }
      },
      legend: {
        top: 0,
        right: 12,
        itemWidth: 10,
        itemHeight: 10,
        textStyle: { color: "#a8c2d7", fontSize: 11 },
        data: ["总数", "成熟果", "转色果"]
      },
      grid: { left: 40, right: 15, top: 35, bottom: 25 },
      xAxis: {
        type: "category",
        boundaryGap: false,
        data: ["4/16", "4/17", "4/18", "4/19", "4/20", "4/21", "4/22"],
        axisLine: { lineStyle: { color: "#244c68" } },
        axisTick: { show: false },
        axisLabel: { color: "#a3bdd1", fontSize: 10 }
      },
      yAxis: {
        type: "value",
        min: 0,
        max: 150,
        interval: 50,
        axisLabel: { color: "#a3bdd1", fontSize: 10 },
        splitLine: { lineStyle: { color: "rgba(70,130,165,.15)" } }
      },
      series: [
        {
          name: "总数",
          type: "line",
          smooth: true,
          symbol: "circle",
          symbolSize: 6,
          data: [105, 110, 115, 119, 122, 125, 128],
          lineStyle: { width: 2, color: "#21bdf3" },
          itemStyle: { color: "#21bdf3" }
        },
        {
          name: "成熟果",
          type: "line",
          smooth: true,
          symbol: "circle",
          symbolSize: 6,
          data: [42, 47, 53, 58, 63, 66, 70],
          lineStyle: { width: 2, color: "#35d18d" },
          itemStyle: { color: "#35d18d" }
        },
        {
          name: "转色果",
          type: "line",
          smooth: true,
          symbol: "circle",
          symbolSize: 6,
          data: [63, 68, 75, 80, 84, 88, 90],
          lineStyle: { width: 2, color: "#ff9e32" },
          itemStyle: { color: "#ff9e32" }
        }
      ]
    })

    charts.push(chart)
  }

  if (maturityChart.value) {
    const chart = echarts.init(maturityChart.value)

    chart.setOption({
      backgroundColor: "transparent",
      tooltip: {
        trigger: "item",
        backgroundColor: "#082b48",
        borderColor: "#087fae",
        textStyle: { color: "#eaf7ff" }
      },
      series: [{
        type: "pie",
        radius: ["57%", "80%"],
        center: ["50%", "50%"],
        label: { show: false },
        labelLine: { show: false },
        itemStyle: {
          borderColor: "#08243b",
          borderWidth: 2
        },
        data: [
          { value: 40, name: "青果", itemStyle: { color: "#20b9ec" } },
          { value: 35, name: "转色果", itemStyle: { color: "#36d18c" } },
          { value: 53, name: "成熟果", itemStyle: { color: "#ff9d2f" } }
        ]
      }]
    })

    charts.push(chart)
  }
}

function resizeCharts() {
  charts.forEach(chart => chart.resize())
}

onMounted(async () => {
  await nextTick()
  initCharts()
  window.addEventListener("resize", resizeCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener("resize", resizeCharts)
  charts.forEach(chart => chart.dispose())
  charts = []
})
</script>

<template>
  <div class="dashboard-page">

    <!-- 上半区：环境、种植画面、水肥 -->
    <div class="top-grid">

      <!-- 左上：环境监测 -->
      <div class="left-top-stack">

        <section class="panel env-panel dashboard-link" role="link" tabindex="0" @click="goEnvironment" @keydown.enter="goEnvironment">
          <div class="panel-header">
            <h3><span class="title-icon green-icon">🌿</span>环境监测</h3>
            <span class="panel-meta">实时数据</span>
          </div>

          <div class="env-grid">
            <div
              v-for="item in environmentMetrics"
              :key="item.label"
              class="env-card"
              :class="item.color"
            >
              <div class="env-card-icon">{{ item.icon }}</div>
              <div class="env-card-content">
                <span>{{ item.label }}</span>
                <strong>{{ item.value }}<small>{{ item.unit }}</small></strong>
                <em>{{ item.change }}</em>
              </div>
            </div>
          </div>
        </section>

        <section class="panel env-trend-panel">
          <div class="panel-header">
            <h3>环境变化趋势</h3>
            <div class="period-tabs">
              <span class="selected">24h</span>
              <span>7天</span>
              <span>30天</span>
            </div>
          </div>
          <div ref="envChart" class="env-chart"></div>
        </section>

      </div>

      <!-- 中上：番茄种植实景 -->
      <section class="panel greenhouse-panel">
        <div class="panel-header">
          <h3><span class="title-icon">⌂</span>种植区域实时画面</h3>
          <span class="live-status"><i></i>演示画面</span>
        </div>

        <div class="greenhouse-image-wrap">
          <img
            src="/images/greenhouse-demo.jpg"
            alt="温室番茄种植区域演示照片"
          />
        </div>
      </section>

      <!-- 右上：水肥管理 -->
      <div class="right-top-stack">

        <section class="panel irrigation-panel dashboard-link" role="link" tabindex="0" @click="goIrrigation" @keydown.enter="goIrrigation">
          <div class="panel-header">
            <h3><span class="title-icon blue-icon">💧</span>水肥管理</h3>
            <span class="panel-meta">运行状态</span>
          </div>

          <div class="irrigation-overview">
            <div class="auto-mode-ring">
              <div class="auto-mode-inner">
                <span>🌱</span>
                <strong>自动模式</strong>
              </div>
            </div>

            <div class="irrigation-stats">
              <div class="irrigation-stat">
                <span class="stat-icon">💧</span>
                <div>
                  <small>今日灌溉次数</small>
                  <strong>3 <i>次</i></strong>
                </div>
              </div>

              <div class="irrigation-stat">
                <span class="stat-icon">▣</span>
                <div>
                  <small>今日用水量</small>
                  <strong>18.5 <i>L</i></strong>
                </div>
              </div>
            </div>
          </div>

          <div class="equipment-title">设备状态</div>

          <div class="equipment-grid">
            <div class="equipment-card">
              <span class="equipment-icon pump">⚙</span>
              <div>
                <strong>水泵</strong>
                <small>待机</small>
              </div>
            </div>

            <div class="equipment-card">
              <span class="equipment-icon valve">♧</span>
              <div>
                <strong>电磁阀</strong>
                <small>关闭</small>
              </div>
            </div>
          </div>
        </section>

        <section class="panel water-trend-panel">
          <div class="panel-header">
            <h3>灌溉用水趋势</h3>
          </div>
          <div ref="waterChart" class="water-chart"></div>
        </section>

      </div>

    </div>

    <!-- 下半区：生长监测、生长趋势、预警 -->
    <div class="bottom-grid">

      <!-- 左下：番茄生长监测 -->
      <section class="panel recognition-panel dashboard-link" role="link" tabindex="0" @click="goGrowth" @keydown.enter="goGrowth">
        <div class="panel-header">
          <h3><span class="title-icon green-icon">♻</span>番茄生长监测</h3>
          <span class="ai-tag">● AI识别</span>
        </div>

        <div class="recognition-body">
          <div class="fruit-image-wrap">
            <img
              src="/images/tomato-fruits-demo.jpg"
              alt="番茄果实识别演示照片"
            />
            <span class="detect-box detect-green"></span>
            <span class="detect-box detect-yellow"></span>
            <span class="detect-box detect-red"></span>
          </div>

          <div class="recognition-stats">
            <div class="recognition-total">
              <span>识别总数</span>
              <strong>128 <small>个</small></strong>
            </div>

            <div
              v-for="item in fruitStages"
              :key="item.name"
              class="fruit-count"
            >
              <i :class="item.color"></i>
              <span>{{ item.name }}</span>
              <strong>{{ item.count }}</strong>
            </div>

            <button class="detail-button" type="button">
              查看详情 <span>›</span>
            </button>
          </div>
        </div>
      </section>

      <!-- 中下：生长趋势和成熟度 -->
      <section class="panel growth-analysis-panel dashboard-link" role="link" tabindex="0" @click="goGrowth" @keydown.enter="goGrowth">
        <div class="panel-header">
          <h3><span class="title-icon">♧</span>生长趋势分析</h3>
        </div>

        <div class="growth-analysis-body">

          <div ref="growthChart" class="growth-chart"></div>

          <div class="maturity-panel">
            <h4>成熟度占比</h4>

            <div class="maturity-content">
              <div ref="maturityChart" class="maturity-chart"></div>

              <div class="maturity-legend">
                <div v-for="item in fruitStages" :key="item.name">
                  <i :class="item.chartColor"></i>
                  <span>{{ item.name }}</span>
                  <strong>{{ item.percent }}</strong>
                </div>
              </div>
            </div>
          </div>

        </div>
      </section>

      <!-- 右下：预警信息 -->
      <section class="panel warnings-panel">
        <div class="panel-header">
          <h3><span class="warning-bell">🔔</span>预警信息</h3>
          <span class="more-link">更多 ›</span>
        </div>

        <div class="warning-list">
          <div
            v-for="item in alerts"
            :key="item.time"
            class="warning-item"
          >
            <span class="warning-symbol" :class="item.type">
              {{ item.icon }}
            </span>

            <div class="warning-text">
              <strong>{{ item.title }}</strong>
              <small>{{ item.time }}</small>
            </div>
          </div>
        </div>
      </section>

    </div>

  </div>
</template>

<style scoped>
.dashboard-page {
  width: 100%;
  height: calc(100vh - 88px);
  min-height: 720px;
  padding: 21px 20px 23px;
  display: grid;
  grid-template-rows: minmax(0, 1.72fr) minmax(0, 1fr);
  gap: 20px;
  background:
    radial-gradient(ellipse at 50% 40%, rgba(0, 95, 150, .12), transparent 60%),
    #031629;
  overflow: hidden;
}

.top-grid,
.bottom-grid {
  min-width: 0;
  min-height: 0;
  display: grid;
  gap: 16px;
  grid-template-columns:
    minmax(330px, 1.035fr)
    minmax(600px, 1.915fr)
    minmax(330px, 1fr);
}

.bottom-grid {
  grid-template-columns:
    minmax(330px, 1.035fr)
    minmax(600px, 2.05fr)
    minmax(330px, 1fr);
}

.left-top-stack,
.right-top-stack {
  min-width: 0;
  min-height: 0;
  display: grid;
  gap: 9px;
}

.left-top-stack {
  grid-template-rows: minmax(0, 1.19fr) minmax(0, 1fr);
}

.right-top-stack {
  grid-template-rows: minmax(0, 2.05fr) minmax(0, 1fr);
}

/* 通用科技面板 */

.panel {
  position: relative;
  min-width: 0;
  min-height: 0;
  padding: 11px 12px;
  overflow: hidden;
  border: 1px solid #087eae;
  border-radius: 9px;
  background:
    linear-gradient(145deg, rgba(5, 37, 63, .97), rgba(3, 23, 43, .98));
  box-shadow:
    0 0 12px rgba(0, 173, 235, .13),
    inset 0 0 22px rgba(0, 128, 194, .06);
}

.panel::before {
  content: "";
  position: absolute;
  left: 15px;
  right: 15px;
  top: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, #1bd4ff, transparent);
  opacity: .85;
}

.panel-header {
  height: 30px;
  min-height: 30px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  border-bottom: 1px solid rgba(0, 177, 231, .3);
  margin-bottom: 10px;
}

.panel-header h3 {
  margin: 0;
  color: #e7f5ff;
  font-size: 16px;
  font-weight: 700;
  white-space: nowrap;
  text-shadow: 0 0 9px rgba(0, 174, 239, .22);
}

.title-icon {
  display: inline-block;
  margin-right: 8px;
  color: #31d7e8;
  font-size: 18px;
}

.green-icon {
  color: #35d99c;
}

.blue-icon {
  color: #24c8f4;
}

.panel-meta {
  color: #a7c2d6;
  font-size: 11px;
  white-space: nowrap;
}

/* 左上环境监测 */

.env-panel {
  display: flex;
  flex-direction: column;
}

.env-grid {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  grid-template-rows: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.env-card {
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 10px;
  border-radius: 8px;
  background: linear-gradient(135deg, #0b3152, #082744);
  border: 1px solid rgba(19, 91, 135, .35);
}

.env-card-icon {
  width: 44px;
  flex-shrink: 0;
  text-align: center;
  font-size: 31px;
  filter: drop-shadow(0 0 7px rgba(0, 190, 255, .2));
}

.env-card-content {
  min-width: 0;
  display: flex;
  flex-direction: column;
  gap: 1px;
}

.env-card-content > span {
  color: #d7e9f5;
  font-size: 12px;
  white-space: nowrap;
}

.env-card-content > strong {
  color: #f2f8ff;
  font-size: 27px;
  line-height: 1.15;
  white-space: nowrap;
}

.env-card-content > strong small {
  margin-left: 3px;
  font-size: 12px;
}

.env-card-content em {
  color: #26d99a;
  font-size: 11px;
  font-style: normal;
  font-weight: 600;
}

.env-card.light .env-card-icon {
  color: #ffbd38;
}

/* 环境趋势 */

.env-trend-panel,
.water-trend-panel {
  display: flex;
  flex-direction: column;
}

.period-tabs {
  display: flex;
  gap: 5px;
}

.period-tabs span {
  padding: 4px 10px;
  color: #b6d0e2;
  font-size: 11px;
  border-radius: 5px;
  background: #103452;
  border: 1px solid #164e70;
}

.period-tabs .selected {
  color: #fff;
  background: #087eae;
  border-color: #11c4f5;
  box-shadow: 0 0 9px rgba(0, 192, 255, .3);
}

.env-chart {
  flex: 1;
  min-height: 0;
  width: 100%;
}

/* 中间种植区域 */

.greenhouse-panel {
  display: flex;
  flex-direction: column;
}

.greenhouse-image-wrap {
  flex: 1;
  min-height: 0;
  width: 100%;
  overflow: hidden;
  border: 1px solid rgba(28, 194, 235, .45);
  border-radius: 7px;
  background: #08233b;
  box-shadow: 0 0 12px rgba(0, 184, 245, .18);
}

.greenhouse-image-wrap img {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  object-position: center;
}

.live-status {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #d0e6f3;
  font-size: 11px;
}

.live-status i {
  width: 9px;
  height: 9px;
  background: #38d99b;
  border-radius: 50%;
  box-shadow: 0 0 9px #38d99b;
}

/* 右上水肥管理 */

.irrigation-panel {
  display: flex;
  flex-direction: column;
}

.irrigation-overview {
  height: 145px;
  min-height: 115px;
  display: grid;
  grid-template-columns: 43% 57%;
  align-items: center;
}

.auto-mode-ring {
  width: min(130px, 100%);
  aspect-ratio: 1;
  justify-self: center;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 50%;
  background: conic-gradient(
    #13b9ed 0deg 120deg,
    #0b5589 120deg 225deg,
    #26d99a 225deg 360deg
  );
  box-shadow: 0 0 13px rgba(0, 177, 239, .2);
}

.auto-mode-inner {
  width: 78%;
  height: 78%;
  border-radius: 50%;
  background: #082943;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
}

.auto-mode-inner span {
  font-size: 27px;
}

.auto-mode-inner strong {
  margin-top: 4px;
  color: #31dba2;
  font-size: 13px;
}

.irrigation-stats {
  height: 88%;
  padding-left: 14px;
  border-left: 1px solid rgba(0, 165, 220, .3);
  display: flex;
  flex-direction: column;
  justify-content: space-evenly;
  gap: 8px;
}

.irrigation-stat {
  display: flex;
  align-items: center;
  gap: 10px;
}

.stat-icon {
  width: 30px;
  color: #29c9f5;
  font-size: 25px;
  text-align: center;
}

.irrigation-stat small,
.irrigation-stat strong {
  display: block;
  white-space: nowrap;
}

.irrigation-stat small {
  color: #a8c2d6;
  font-size: 11px;
}

.irrigation-stat strong {
  margin-top: 3px;
  color: #f0f7ff;
  font-size: 23px;
}

.irrigation-stat strong i {
  font-size: 12px;
  font-style: normal;
}

.equipment-title {
  margin: 4px 0 8px;
  color: #c8ddeb;
  font-size: 13px;
  font-weight: 700;
}

.equipment-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.equipment-card {
  min-width: 0;
  height: 60px;
  padding: 7px 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 10px;
  border-radius: 7px;
  background: #092b48;
  border: 1px solid rgba(20, 86, 127, .32);
}

.equipment-icon {
  font-size: 25px;
}

.equipment-icon.pump {
  color: #36dca8;
}

.equipment-icon.valve {
  color: #62caff;
}

.equipment-card strong,
.equipment-card small {
  display: block;
}

.equipment-card strong {
  color: #dcecf7;
  font-size: 12px;
}

.equipment-card small {
  margin-top: 3px;
  color: #31dca5;
  font-size: 11px;
}

/* 灌溉用水趋势 */

.water-chart {
  flex: 1;
  min-height: 0;
  width: 100%;
}

/* 左下番茄生长监测 */

.recognition-panel {
  display: flex;
  flex-direction: column;
}

.ai-tag {
  color: #39d9bd;
  background: rgba(0, 194, 194, .09);
  border: 1px solid rgba(0, 194, 194, .2);
  border-radius: 5px;
  padding: 4px 8px;
  font-size: 10px;
  white-space: nowrap;
}

.recognition-body {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 1.18fr .82fr;
  gap: 12px;
}

.fruit-image-wrap {
  position: relative;
  min-width: 0;
  min-height: 0;
  overflow: hidden;
  border-radius: 6px;
  border: 1px solid rgba(24, 150, 116, .35);
  background: #163d31;
}

.fruit-image-wrap img {
  width: 100%;
  height: 100%;
  display: block;
  object-fit: cover;
  object-position: center;
}

.detect-box {
  position: absolute;
  display: block;
  border: 2px solid;
  box-shadow: 0 0 7px currentColor;
}

.detect-green {
  color: #27e68d;
  left: 18%;
  top: 23%;
  width: 39%;
  height: 44%;
}

.detect-yellow {
  color: #f1d52e;
  left: 42%;
  top: 18%;
  width: 38%;
  height: 64%;
}

.detect-red {
  color: #ff6a39;
  left: 40%;
  top: 47%;
  width: 42%;
  height: 42%;
}

.recognition-stats {
  min-width: 0;
  display: flex;
  flex-direction: column;
  justify-content: space-around;
}

.recognition-total span {
  display: block;
  color: #aac4d7;
  font-size: 11px;
}

.recognition-total strong {
  display: block;
  margin-top: 5px;
  color: #f0f8ff;
  font-size: 25px;
  white-space: nowrap;
}

.recognition-total small {
  font-size: 12px;
}

.fruit-count {
  display: flex;
  align-items: center;
  gap: 6px;
  color: #c5d9e7;
  font-size: 11px;
  white-space: nowrap;
}

.fruit-count i,
.maturity-legend i {
  width: 9px;
  height: 9px;
  flex-shrink: 0;
  border-radius: 50%;
}

.fruit-count strong {
  margin-left: auto;
  color: #f0f7ff;
  font-size: 13px;
}

.green { background: #32d79b; }
.yellow { background: #d4db45; }
.red { background: #ff5145; }

.detail-button {
  height: 34px;
  margin-top: 4px;
  border: 1px solid #096ca0;
  border-radius: 6px;
  color: #c8e8fa;
  background: linear-gradient(180deg, #0b6194, #08436f);
  font-size: 12px;
  cursor: default;
}

.detail-button span {
  margin-left: 5px;
  font-size: 18px;
  vertical-align: -1px;
}

/* 中下生长趋势分析 */

.growth-analysis-panel {
  display: flex;
  flex-direction: column;
}

.growth-analysis-body {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 1.55fr 1fr;
}

.growth-chart {
  min-width: 0;
  min-height: 0;
  width: 100%;
  height: 100%;
}

.maturity-panel {
  min-width: 0;
  padding-left: 13px;
  border-left: 1px solid rgba(0, 171, 229, .3);
  display: flex;
  flex-direction: column;
}

.maturity-panel h4 {
  margin: 0 0 5px;
  color: #e1eff8;
  font-size: 14px;
}

.maturity-content {
  flex: 1;
  min-height: 0;
  display: grid;
  grid-template-columns: 1fr 1.05fr;
  align-items: center;
  gap: 4px;
}

.maturity-chart {
  width: 100%;
  height: 100%;
  min-height: 100px;
}

.maturity-legend {
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.maturity-legend > div {
  display: grid;
  grid-template-columns: 10px 1fr auto;
  align-items: center;
  gap: 7px;
  color: #bdd2e1;
  font-size: 11px;
  white-space: nowrap;
}

.maturity-legend strong {
  color: #e8f4fc;
  font-size: 12px;
}

/* 右下预警 */

.warnings-panel {
  display: flex;
  flex-direction: column;
}

.warning-bell {
  margin-right: 8px;
  color: #ffb12e;
  font-size: 19px;
}

.more-link {
  color: #a9c4d8;
  font-size: 12px;
  white-space: nowrap;
}

.warning-list {
  display: flex;
  flex-direction: column;
}

.warning-item {
  min-height: 74px;
  display: flex;
  align-items: center;
  gap: 12px;
  border-bottom: 1px solid rgba(59, 116, 151, .23);
}

.warning-item:last-child {
  border-bottom: 0;
}

.warning-symbol {
  width: 28px;
  height: 28px;
  flex-shrink: 0;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 50%;
  font-size: 16px;
  font-weight: 700;
}

.warning-symbol.warning {
  color: #fff;
  background: #f5a329;
  box-shadow: 0 0 10px rgba(245, 163, 41, .3);
}

.warning-symbol.success {
  color: #052c24;
  background: #35d99a;
}

.warning-symbol.info {
  color: #fff;
  background: #18a9e9;
}

.warning-text strong,
.warning-text small {
  display: block;
}

.warning-text strong {
  color: #dceaf5;
  font-size: 12px;
  font-weight: 600;
}

.warning-text small {
  margin-top: 5px;
  color: #8daac1;
  font-size: 11px;
}

/* 中等屏幕适配 */

@media (max-width: 1450px) {
  .dashboard-page {
    padding: 15px;
    gap: 14px;
  }

  .top-grid,
  .bottom-grid {
    gap: 11px;
  }

  .panel {
    padding: 9px;
  }

  .env-card {
    gap: 5px;
    padding: 6px;
  }

  .env-card-icon {
    width: 34px;
    font-size: 24px;
  }

  .env-card-content > strong {
    font-size: 22px;
  }

  .panel-header h3 {
    font-size: 14px;
  }

  .maturity-legend {
    gap: 10px;
  }
}
.cyan { background: #20b9ec; }
.chart-green { background: #36d18c; }
.orange { background: #ff9d2f; }
/* td-dashboard-patch：仅修复预警显示、边框与导航交互 */
.warnings-panel .warning-list { flex: 1; min-height: 0; justify-content: space-around; }
.warnings-panel .warning-item { min-height: 0; flex: 1 1 0; padding: 3px 0; }
.panel { border-radius: 0 !important; border: 1px solid #0b9ac7 !important; clip-path: polygon(0 10px, 10px 0, calc(100% - 10px) 0, 100% 10px, 100% calc(100% - 10px), calc(100% - 10px) 100%, 10px 100%, 0 calc(100% - 10px)); box-shadow: inset 0 0 14px rgba(0,170,255,.13), 0 0 15px rgba(0,195,255,.18) !important; }
.panel::after { content: ''; pointer-events: none; position: absolute; inset: 0; background: linear-gradient(90deg, rgba(20,209,255,.12), transparent 22%, transparent 78%, rgba(20,209,255,.12)); opacity: .65; }
.dashboard-link { cursor: pointer; }
.dashboard-link:hover { border-color: #4ee6ff !important; box-shadow: inset 0 0 22px rgba(0,207,255,.17), 0 0 20px rgba(0,207,255,.3) !important; }
.dashboard-link:focus-visible { outline: 2px solid #4ee6ff; outline-offset: 2px; }
</style>



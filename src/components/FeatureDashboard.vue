<script setup>
const baseUrl = import.meta.env.BASE_URL
import { ref, computed, onMounted, onBeforeUnmount, nextTick } from "vue"
import * as echarts from "echarts"

const props = defineProps({
  mode: { type: String, required: true }
})

const trendChart = ref(null)
const sideChart = ref(null)
const bottomChart = ref(null)
const donutChart = ref(null)

const selectedPeriod = ref("24小时")
const selectedSensor = ref("空气温度")
const selectedObject = ref("A01")

const operationMode = ref("自动")
const pumpOn = ref(false)
const valveOpen = ref(false)
const controlMessage = ref("当前为模拟运行状态")

const currentEc = ref(2.1)
const currentPh = ref(6.8)
const targetEc = ref(2.4)
const targetPh = ref(6.2)

const ecDeviation = computed(() =>
  Number((currentEc.value - targetEc.value).toFixed(2))
)
const phDeviation = computed(() =>
  Number((currentPh.value - targetPh.value).toFixed(2))
)

const ecAdvice = computed(() => {
  if (ecDeviation.value < -0.1) return "肥液EC低于目标，建议检查母液配比并小步调整"
  if (ecDeviation.value > 0.1) return "肥液EC高于目标，建议检查肥液浓度"
  return "肥液EC处于设定目标附近"
})

const phAdvice = computed(() => {
  if (phDeviation.value > 0.1) return "肥液pH高于目标，建议检查酸碱调节"
  if (phDeviation.value < -0.1) return "肥液pH低于目标，建议检查酸碱调节"
  return "肥液pH处于设定目标附近"
})

const mainMetrics = [
  { name: "空气温度", value: "26.5", unit: "℃", icon: "🌡", color: "#ffae45" },
  { name: "空气湿度", value: "68", unit: "%", icon: "💧", color: "#21c4f3" },
  { name: "土壤湿度", value: "52", unit: "%", icon: "🌱", color: "#39d99d" },
  { name: "光照强度", value: "12000", unit: "lx", icon: "☀", color: "#f6cf55" }
]

const sensorDetails = ref([
  { name: "空气温度", value: "26.5 ℃", status: "正常" },
  { name: "空气湿度", value: "68 %", status: "正常" },
  { name: "土壤湿度", value: "52 %", status: "正常" },
  { name: "光照强度", value: "12000 lx", status: "正常" },
  { name: "CO₂浓度", value: "680 ppm", status: "正常" },
  { name: "土壤温度", value: "22.4 ℃", status: "正常" },
  { name: "土壤pH", value: "6.3", status: "正常" },
  { name: "土壤EC", value: "1.8 mS/cm", status: "正常" },
  { name: "土壤氮 N", value: "156 mg/kg", status: "正常" },
  { name: "土壤磷 P", value: "48 mg/kg", status: "正常" },
  { name: "土壤钾 K", value: "210 mg/kg", status: "正常" }
])

const environmentAlerts = ref([
  { name: "土壤湿度接近下限", time: "14:20", level: "warning", done: false },
  { name: "CO₂浓度监测正常", time: "13:50", level: "success", done: false },
  { name: "土壤EC监测正常", time: "13:30", level: "success", done: false },
  { name: "土壤pH监测正常", time: "13:10", level: "success", done: false },
  { name: "土壤温度监测正常", time: "12:50", level: "success", done: false },
  { name: "NPK养分数据正常", time: "12:30", level: "success", done: false }
])

const plants = ref([
  { id: "A01", area: "北区一排", height: 86.4, lai: 2.8, stage: "结果期" },
  { id: "A02", area: "北区二排", height: 82.1, lai: 2.6, stage: "结果期" },
  { id: "A03", area: "中区一排", height: 91.2, lai: 3.0, stage: "盛果期" },
  { id: "A04", area: "中区二排", height: 78.5, lai: 2.4, stage: "结果期" },
  { id: "A05", area: "南区一排", height: 72.6, lai: 2.2, stage: "开花期" },
  { id: "A06", area: "南区二排", height: 88.3, lai: 2.9, stage: "盛果期" }
])

const selectedPlant = computed(() =>
  plants.value.find(p => p.id === selectedObject.value) || plants.value[0]
)

const fruitStages = [
  { name: "青果", value: 40, color: "#20b9ec" },
  { name: "转色果", value: 35, color: "#36d18c" },
  { name: "成熟果", value: 53, color: "#ff9d2f" }
]

const irrigationRecords = ref([
  { time: "14:20", name: "一区定时灌溉", type: "灌溉", amount: "5.0 L", status: "已完成" },
  { time: "12:30", name: "二区水肥任务", type: "施肥", amount: "2.0 L", status: "已完成" },
  { time: "10:15", name: "一区补水任务", type: "灌溉", amount: "3.5 L", status: "已完成" },
  { time: "09:00", name: "三区水肥任务", type: "施肥", amount: "1.5 L", status: "已完成" }
])

const archives = [
  { date: "11-27", name: "A01 生长监测", detail: "株高 86.4 cm · LAI 2.8" },
  { date: "11-26", name: "A01 生长监测", detail: "株高 85.2 cm · LAI 2.7" },
  { date: "11-25", name: "A02 生长监测", detail: "株高 82.1 cm · LAI 2.6" },
  { date: "11-24", name: "A03 生长监测", detail: "株高 91.2 cm · LAI 3.0" },
  { date: "11-23", name: "A04 生长监测", detail: "株高 78.5 cm · LAI 2.4" }
]

const selectedArchive = ref(null)

function selectSensor(sensor) {
  selectedSensor.value = sensor.name
}

function resolveAlert(alert) {
  alert.done = true
}

function changeMode(value) {
  operationMode.value = value
  controlMessage.value = `已切换为${value}模式（模拟）`
}

function togglePump() {
  if (operationMode.value !== "手动") {
    controlMessage.value = "请先切换手动模式"
    return
  }
  pumpOn.value = !pumpOn.value
  controlMessage.value = `水泵已${pumpOn.value ? "启动" : "停止"}（模拟）`
}

function toggleValve() {
  if (operationMode.value !== "手动") {
    controlMessage.value = "请先切换手动模式"
    return
  }
  valveOpen.value = !valveOpen.value
  controlMessage.value = `电磁阀已${valveOpen.value ? "打开" : "关闭"}（模拟）`
}

function simulateFertilizer() {
  const now = new Date().toLocaleTimeString("zh-CN", {
    hour: "2-digit",
    minute: "2-digit"
  })

  irrigationRecords.value.unshift({
    time: now,
    name: "EC/pH目标偏差调整",
    type: "施肥",
    amount: "模拟执行",
    status: "模拟完成"
  })

  currentEc.value = Number(targetEc.value)
  currentPh.value = Number(targetPh.value)
  controlMessage.value = "模拟施肥任务完成，当前数值已更新"
}

const periodConfigs = {
  environment: {
    "24小时": {
      labels: ["00时", "04时", "08时", "12时", "16时", "20时", "24时"],
      data: [[22, 21, 24, 27, 26, 24, 23], [60, 63, 65, 70, 68, 66, 64], [650, 670, 690, 680, 670, 660, 680]]
    },
    "7天": {
      labels: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
      data: [[24, 25, 25, 26, 27, 26, 26], [62, 64, 65, 67, 68, 66, 68], [660, 670, 680, 675, 690, 680, 680]]
    },
    "30天": {
      labels: ["第1周", "第2周", "第3周", "第4周"],
      data: [[23, 24, 25, 26], [60, 63, 65, 68], [650, 660, 670, 680]]
    }
  },
  irrigation: {
    "7天": {
      labels: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
      data: [[12, 15, 10, 18, 16, 13, 18.5]]
    },
    "30天": {
      labels: ["第1周", "第2周", "第3周", "第4周"],
      data: [[72, 85, 79, 92]]
    }
  },
  growth: {
    "7天": {
      labels: ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
      data: [[105, 110, 115, 119, 122, 125, 128], [42, 45, 48, 50, 51, 52, 53], [25, 28, 30, 32, 34, 34, 35]]
    },
    "30天": {
      labels: ["第1周", "第2周", "第3周", "第4周"],
      data: [[65, 82, 105, 128], [20, 30, 42, 53], [12, 20, 28, 35]]
    }
  }
}

let charts = []
let primaryChart = null

function lineOption(labels, series) {
  const colors = ["#22c6f2", "#35d99a", "#ffae45"]

  return {
    backgroundColor: "transparent",
    tooltip: {
      trigger: "axis",
      backgroundColor: "#082b48",
      borderColor: "#087fae",
      textStyle: { color: "#eaf7ff" }
    },
    legend: {
      top: 2,
      itemWidth: 9,
      itemHeight: 9,
      textStyle: { color: "#aac5d9", fontSize: 10 },
      data: series.map(s => s.name)
    },
    grid: { left: 38, right: 12, top: 35, bottom: 25 },
    xAxis: {
      type: "category",
      boundaryGap: false,
      data: labels,
      axisLine: { lineStyle: { color: "#244c68" } },
      axisTick: { show: false },
      axisLabel: { color: "#a4bfd3", fontSize: 10 }
    },
    yAxis: {
      type: "value",
      axisLabel: { color: "#a4bfd3", fontSize: 10 },
      splitLine: { lineStyle: { color: "rgba(70,130,165,.16)" } }
    },
    series: series.map((s, i) => ({
      name: s.name,
      type: "line",
      smooth: true,
      showSymbol: true,
      symbolSize: 5,
      data: s.data,
      lineStyle: { width: 2, color: colors[i % colors.length] },
      itemStyle: { color: colors[i % colors.length] },
      areaStyle: { opacity: .035 }
    }))
  }
}

function barOption(labels, data, name = "用量") {
  return {
    backgroundColor: "transparent",
    tooltip: { trigger: "axis" },
    grid: { left: 38, right: 12, top: 18, bottom: 26 },
    xAxis: {
      type: "category",
      data: labels,
      axisLine: { lineStyle: { color: "#244c68" } },
      axisLabel: { color: "#a4bfd3", fontSize: 10 }
    },
    yAxis: {
      type: "value",
      axisLabel: { color: "#a4bfd3", fontSize: 10 },
      splitLine: { lineStyle: { color: "rgba(70,130,165,.16)" } }
    },
    series: [{
      name,
      type: "bar",
      barWidth: "38%",
      data,
      itemStyle: {
        borderRadius: [4, 4, 0, 0],
        color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
          { offset: 0, color: "#24cef4" },
          { offset: 1, color: "#0874b0" }
        ])
      }
    }]
  }
}

function pieOption(data) {
  return {
    backgroundColor: "transparent",
    tooltip: { trigger: "item" },
    series: [{
      type: "pie",
      radius: ["53%", "77%"],
      center: ["50%", "50%"],
      label: { show: false },
      itemStyle: { borderColor: "#08243b", borderWidth: 3 },
      data
    }]
  }
}

function initChart(element, option) {
  if (!element.value) return null
  const chart = echarts.init(element.value)
  chart.setOption(option)
  charts.push(chart)
  return chart
}

function changePeriod(period) {
  selectedPeriod.value = period

  const config = periodConfigs[props.mode]?.[period]
  if (!config || !primaryChart) return

  primaryChart.setOption({
    xAxis: { data: config.labels },
    series: config.data.map(data => ({ data }))
  })
}

function resizeCharts() {
  charts.forEach(chart => chart.resize())
}

onMounted(async () => {
  await nextTick()

  if (props.mode === "environment") {
    primaryChart = initChart(
      trendChart,
      lineOption(
        ["00时", "04时", "08时", "12时", "16时", "20时", "24时"],
        [
          { name: "空气温度", data: [22, 21, 24, 27, 26, 24, 23] },
          { name: "空气湿度", data: [60, 63, 65, 70, 68, 66, 64] },
          { name: "CO₂", data: [650, 670, 690, 680, 670, 660, 680] }
        ]
      )
    )

    initChart(
      sideChart,
      lineOption(
        ["00时", "04时", "08时", "12时", "16时", "20时"],
        [
          { name: "土壤温度", data: [21, 21, 22, 23, 22, 22] },
          { name: "土壤湿度", data: [50, 51, 52, 54, 52, 52] }
        ]
      )
    )
  }

  if (props.mode === "irrigation") {
    primaryChart = initChart(
      bottomChart,
      barOption(
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
        [12, 15, 10, 18, 16, 13, 18.5],
        "灌溉用水量"
      )
    )

    initChart(
      donutChart,
      pieOption([
        { value: 65, name: "自动模式", itemStyle: { color: "#21bdf0" } },
        { value: 35, name: "手动模式", itemStyle: { color: "#35d99a" } }
      ])
    )

    initChart(
      sideChart,
      barOption(["一区", "二区", "三区", "四区"], [35, 28, 22, 15], "区域用水占比")
    )
  }

  if (props.mode === "growth") {
    primaryChart = initChart(
      bottomChart,
      lineOption(
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
        [
          { name: "果实总数", data: [105, 110, 115, 119, 122, 125, 128] },
          { name: "成熟果", data: [42, 45, 48, 50, 51, 52, 53] },
          { name: "转色果", data: [25, 28, 30, 32, 34, 34, 35] }
        ]
      )
    )

    initChart(
      donutChart,
      pieOption([
        { value: 40, name: "青果", itemStyle: { color: "#20b9ec" } },
        { value: 35, name: "转色果", itemStyle: { color: "#36d18c" } },
        { value: 53, name: "成熟果", itemStyle: { color: "#ff9d2f" } }
      ])
    )

    initChart(
      sideChart,
      lineOption(
        ["周一", "周二", "周三", "周四", "周五", "周六", "周日"],
        [{ name: "识别准确率", data: [94, 95, 96, 95.5, 97, 96.5, 96.8] }]
      )
    )
  }

  window.addEventListener("resize", resizeCharts)
})

onBeforeUnmount(() => {
  window.removeEventListener("resize", resizeCharts)
  charts.forEach(chart => chart.dispose())
  charts = []
})
</script>

<template>
  <div class="feature-page" :class="'mode-' + mode">

    <!-- 上半区：左侧信息、中间画面、右侧状态 -->
    <div class="feature-top">

      <div class="feature-stack">

        <section class="feature-panel">
          <header class="panel-head">
            <h3>
              {{ mode === "environment" ? "环境指标总览" : mode === "irrigation" ? "灌溉运行统计" : "番茄果实识别统计" }}
            </h3>
            <span class="panel-tag">实时数据</span>
          </header>

          <div v-if="mode === 'environment'" class="metric-grid">
            <div v-for="item in mainMetrics" :key="item.name" class="metric-card">
              <span class="metric-icon" :style="{color:item.color}">{{ item.icon }}</span>
              <div>
                <small>{{ item.name }}</small>
                <strong>{{ item.value }}<i>{{ item.unit }}</i></strong>
              </div>
            </div>
          </div>

          <div v-if="mode === 'irrigation'" class="metric-grid">
            <div class="metric-card">
              <span class="metric-icon">💧</span>
              <div><small>今日灌溉次数</small><strong>3<i>次</i></strong></div>
            </div>
            <div class="metric-card">
              <span class="metric-icon">◈</span>
              <div><small>今日用水量</small><strong>18.5<i>L</i></strong></div>
            </div>
            <div class="metric-card">
              <span class="metric-icon">🌱</span>
              <div><small>今日施肥次数</small><strong>2<i>次</i></strong></div>
            </div>
            <div class="metric-card">
              <span class="metric-icon">▣</span>
              <div><small>设备在线率</small><strong>98<i>%</i></strong></div>
            </div>
          </div>

          <div v-if="mode === 'growth'" class="fruit-stat-grid">
            <div class="fruit-stat total"><small>识别总数</small><strong>128</strong><i>个</i></div>
            <div class="fruit-stat"><small>青果</small><strong>40</strong><i>个</i></div>
            <div class="fruit-stat"><small>转色果</small><strong>35</strong><i>个</i></div>
            <div class="fruit-stat"><small>成熟果</small><strong>53</strong><i>个</i></div>
          </div>
        </section>

        <section class="feature-panel">
          <header class="panel-head">
            <h3>
              {{ mode === "environment" ? "传感器指标详情" : mode === "irrigation" ? "灌溉策略与设备控制" : "监测对象与生长阶段" }}
            </h3>
            <span class="panel-tag">详情</span>
          </header>

          <div v-if="mode === 'environment'" class="scroll-area sensor-list">
            <button
              v-for="item in sensorDetails"
              :key="item.name"
              class="sensor-row"
              :class="{active:selectedSensor===item.name}"
              @click="selectSensor(item)"
            >
              <span>{{ item.name }}</span>
              <strong>{{ item.value }}</strong>
              <i>{{ item.status }}</i>
            </button>
          </div>

          <div v-if="mode === 'irrigation'" class="control-content">
            <div class="mode-switch">
              <span>控制模式</span>
              <button :class="{active:operationMode==='自动'}" @click="changeMode('自动')">自动</button>
              <button :class="{active:operationMode==='手动'}" @click="changeMode('手动')">手动</button>
            </div>

            <div class="device-control">
              <div>
                <span>水泵</span>
                <strong :class="{online:pumpOn}">{{ pumpOn ? "运行中" : "待机" }}</strong>
                <button @click="togglePump">{{ pumpOn ? "停止" : "启动" }}</button>
              </div>
              <div>
                <span>电磁阀</span>
                <strong :class="{online:valveOpen}">{{ valveOpen ? "开启" : "关闭" }}</strong>
                <button @click="toggleValve">{{ valveOpen ? "关闭" : "开启" }}</button>
              </div>
            </div>
            <div class="control-note">{{ controlMessage }}</div>
            <div class="strategy-row"><span>土壤湿度启动阈值</span><strong>45%</strong></div>
            <div class="strategy-row"><span>土壤湿度停止阈值</span><strong>65%</strong></div>
            <div class="strategy-row"><span>施肥策略</span><strong>按目标EC/pH偏差调整</strong></div>
          </div>

          <div v-if="mode === 'growth'" class="scroll-area plant-list">
            <button
              v-for="plant in plants"
              :key="plant.id"
              class="plant-row"
              :class="{active:selectedObject===plant.id}"
              @click="selectedObject=plant.id"
            >
              <span class="plant-id">{{ plant.id }}</span>
              <span>{{ plant.area }}</span>
              <strong>{{ plant.stage }}</strong>
            </button>
            <div class="stage-summary">
              <h4>生长阶段统计</h4>
              <div class="stage-line"><span>开花期</span><div><i style="width:25%"></i></div><strong>25%</strong></div>
              <div class="stage-line"><span>结果期</span><div><i style="width:45%"></i></div><strong>45%</strong></div>
              <div class="stage-line"><span>盛果期</span><div><i style="width:30%"></i></div><strong>30%</strong></div>
            </div>
          </div>
        </section>

      </div>

      <!-- 中间种植区域画面 -->
      <section class="feature-panel scene-panel">
        <header class="panel-head">
          <h3>
            {{ mode === "environment" ? "种植区域环境实时监测" : mode === "irrigation" ? "水肥一体化运行监控" : "番茄生长监测实时画面" }}
          </h3>
          <span class="live-label"><i></i>演示画面</span>
        </header>

        <div class="scene-body">
          <img :src="baseUrl + 'images/greenhouse-demo.jpg'" alt="番茄种植区域演示画面"/>

          <div class="scene-shade"></div>

          <div v-if="mode==='environment'" class="scene-tags">
            <span>🌡 空气温度 26.5℃</span>
            <span>💧 空气湿度 68%</span>
            <span>CO₂ 680 ppm</span>
            <span>土壤湿度 52%</span>
          </div>

          <div v-if="mode==='irrigation'" class="scene-tags">
            <span>💧 水泵 {{ pumpOn ? "运行" : "待机" }}</span>
            <span>电磁阀 {{ valveOpen ? "开启" : "关闭" }}</span>
            <span>今日用水 18.5 L</span>
          </div>

          <div v-if="mode==='growth'" class="detection-overlay">
            <span class="detect detect-one"></span>
            <span class="detect detect-two"></span>
            <span class="detect detect-three"></span>
            <span class="detect-label">AI识别演示 · 96.8%</span>
          </div>

          <div class="scene-watermark">SMART TOMATO · DEMO</div>
        </div>

        <div class="scene-footer">
          <span>监测区域：实验室番茄种植区</span>
          <span>画面来源：模拟图片，后续替换实时视频</span>
        </div>
      </section>

      <div class="feature-stack">

        <section class="feature-panel">
          <header class="panel-head">
            <h3>
              {{ mode === "environment" ? "环境状态与新增指标" : mode === "irrigation" ? "肥液EC / pH精细管控" : "生长识别结果摘要" }}
            </h3>
            <span class="panel-tag">监测分析</span>
          </header>

          <div v-if="mode==='environment'" class="scroll-area status-list">
            <div v-for="item in sensorDetails.slice(4)" :key="item.name" class="status-row">
              <span>{{ item.name }}</span>
              <strong>{{ item.value }}</strong>
              <i class="normal-dot"></i>
            </div>
            <div class="status-hint">土壤N、P、K分别监测，不以土壤EC代替单项养分测量。</div>
          </div>

          <div v-if="mode==='irrigation'" class="fert-control">
            <div class="fert-current">
              <div><small>当前肥液EC</small><strong>{{ currentEc.toFixed(2) }} <i>mS/cm</i></strong></div>
              <div><small>当前肥液pH</small><strong>{{ currentPh.toFixed(2) }}</strong></div>
            </div>

            <div class="target-inputs">
              <label>目标EC
                <input v-model.number="targetEc" type="number" min="0" step="0.1"/>
              </label>
              <label>目标pH
                <input v-model.number="targetPh" type="number" min="0" max="14" step="0.1"/>
              </label>
            </div>

            <div class="deviation-row">
              <span>EC偏差</span>
              <strong :class="{negative:ecDeviation<0,positive:ecDeviation>0}">
                {{ ecDeviation > 0 ? "+" : "" }}{{ ecDeviation.toFixed(2) }}
              </strong>
            </div>
            <div class="deviation-row">
              <span>pH偏差</span>
              <strong :class="{negative:phDeviation<0,positive:phDeviation>0}">
                {{ phDeviation > 0 ? "+" : "" }}{{ phDeviation.toFixed(2) }}
              </strong>
            </div>
            <div class="advice-text">{{ ecAdvice }}</div>
            <div class="advice-text">{{ phAdvice }}</div>
            <button class="primary-action" @click="simulateFertilizer">模拟执行施肥调整</button>
            <small class="demo-warning">演示控制，不连接真实设备；目标值需按实际种植方案设定。</small>
          </div>

          <div v-if="mode==='growth'" class="growth-summary">
            <div class="summary-highlight">
              <span>识别果实总数</span><strong>128 <i>个</i></strong>
            </div>
            <div class="summary-highlight">
              <span>平均识别置信度</span><strong>96.8 <i>%</i></strong>
            </div>
            <div class="summary-pair">
              <div><small>当前株高</small><strong>{{ selectedPlant.height }} cm</strong></div>
              <div><small>叶面积指数 LAI</small><strong>{{ selectedPlant.lai }}</strong></div>
            </div>
            <div class="summary-note">当前监测对象：{{ selectedPlant.id }} · {{ selectedPlant.area }}</div>
          </div>
        </section>

        <section class="feature-panel">
          <header class="panel-head">
            <h3>
              {{ mode === "environment" ? "环境波动分析" : mode === "irrigation" ? "近期灌溉与施肥记录" : "识别准确率趋势" }}
            </h3>
            <span class="panel-tag">历史数据</span>
          </header>

          <div v-if="mode==='environment'" ref="sideChart" class="chart-area"></div>

          <div v-if="mode==='irrigation'" class="scroll-area record-list">
            <div v-for="record in irrigationRecords" :key="record.time+record.name" class="record-row">
              <div><strong>{{ record.name }}</strong><small>{{ record.time }} · {{ record.type }}</small></div>
              <div><strong>{{ record.amount }}</strong><small class="record-done">{{ record.status }}</small></div>
            </div>
          </div>

          <div v-if="mode==='growth'" class="growth-accuracy">
            <div ref="sideChart" class="chart-area"></div>
            <div class="video-state"><i></i>识别画面正常 · 演示模式</div>
          </div>
        </section>

      </div>
    </div>

    <!-- 下半区：统计图表和预警档案 -->
    <div class="feature-bottom">

      <section class="feature-panel">
        <header class="panel-head">
          <h3>
            {{ mode === "environment" ? "传感器在线状态" : mode === "irrigation" ? "近7日每日灌溉统计" : "近7日果实数量变化" }}
          </h3>
          <span class="panel-tag">统计</span>
        </header>

        <div v-if="mode==='environment'" class="scroll-area online-list">
          <div v-for="item in sensorDetails" :key="item.name" class="online-row">
            <span>{{ item.name }}</span><strong>在线</strong><i></i>
          </div>
        </div>

        <div v-if="mode==='irrigation'" class="chart-area" ref="bottomChart"></div>

        <div v-if="mode==='growth'" class="chart-area" ref="bottomChart"></div>
      </section>

      <section class="feature-panel">
        <header class="panel-head">
          <h3>
            {{ mode === "environment" ? "24小时环境变化分析" : mode === "irrigation" ? "水肥运行模式占比" : "果实成熟度占比" }}
          </h3>
          <div class="period-tabs">
            <button
              v-for="p in (mode==='environment'?['24小时','7天','30天']:['7天','30天'])"
              :key="p"
              :class="{active:selectedPeriod===p}"
              @click="changePeriod(p)"
            >{{ p }}</button>
          </div>
        </header>

        <div v-if="mode==='environment'" class="chart-area" ref="trendChart"></div>
        <div v-if="mode==='irrigation'" class="donut-wrap">
          <div ref="donutChart" class="donut-chart"></div>
          <div class="donut-legend">
            <span><i style="background:#21bdf0"></i>自动模式 65%</span>
            <span><i style="background:#35d99a"></i>手动模式 35%</span>
          </div>
        </div>
        <div v-if="mode==='growth'" class="donut-wrap">
          <div ref="donutChart" class="donut-chart"></div>
          <div class="donut-legend">
            <span><i style="background:#20b9ec"></i>青果 40个</span>
            <span><i style="background:#36d18c"></i>转色果 35个</span>
            <span><i style="background:#ff9d2f"></i>成熟果 53个</span>
          </div>
        </div>
      </section>

      <section class="feature-panel">
        <header class="panel-head">
          <h3>
            {{ mode === "environment" ? "环境评分与胁迫预警" : mode === "irrigation" ? "各区域用水分布" : "历史生长档案" }}
          </h3>
          <span class="panel-tag">详情</span>
        </header>

        <div v-if="mode==='environment'" class="environment-warning">
          <div class="score-row"><span>环境综合评分</span><strong>92 <i>/100</i></strong></div>
          <div class="score-track"><i></i></div>
          <div class="scroll-area alert-list">
            <div v-for="alert in environmentAlerts" :key="alert.name" class="alert-row">
              <span :class="alert.level">{{ alert.level==='warning'?'⚠':'●' }}</span>
              <div><strong>{{ alert.name }}</strong><small>{{ alert.time }}</small></div>
              <button v-if="!alert.done" @click="resolveAlert(alert)">处理</button>
              <small v-else class="resolved">已处理</small>
            </div>
          </div>
        </div>

        <div v-if="mode==='irrigation'" class="chart-area" ref="sideChart"></div>

        <div v-if="mode==='growth'" class="scroll-area archive-list">
          <button
            v-for="archive in archives"
            :key="archive.date+archive.name"
            class="archive-row"
            :class="{active:selectedArchive===archive}"
            @click="selectedArchive=archive"
          >
            <span>{{ archive.date }}</span>
            <div><strong>{{ archive.name }}</strong><small>{{ archive.detail }}</small></div>
            <b>›</b>
          </button>
          <div v-if="selectedArchive" class="archive-detail">
            已选择：{{ selectedArchive.name }} · {{ selectedArchive.detail }}
          </div>
        </div>
      </section>

    </div>
  </div>
</template>

<style scoped>
.feature-page {
  width: 100%;
  height: calc(100vh - 88px);
  min-height: 680px;
  padding: 17px 19px 19px;
  display: grid;
  grid-template-rows: minmax(0, 1.58fr) minmax(0, 1fr);
  gap: 14px;
  overflow: hidden;
  color: #e5f3fc;
  background:
    radial-gradient(ellipse at 50% 20%,rgba(0,110,170,.12),transparent 65%),
    #031629;
}

.feature-top,.feature-bottom {
  min-width: 0;
  min-height: 0;
  display: grid;
  grid-template-columns: minmax(270px,1fr) minmax(460px,1.85fr) minmax(270px,1fr);
  gap: 13px;
}

.feature-bottom {
  grid-template-columns: minmax(270px,1fr) minmax(460px,1.85fr) minmax(270px,1fr);
}

.feature-stack {
  min-width: 0;
  min-height: 0;
  display: grid;
  grid-template-rows: minmax(0,1fr) minmax(0,1fr);
  gap: 10px;
}

.feature-panel {
  min-width: 0;
  min-height: 0;
  position: relative;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  padding: 10px 12px;
  border: 1px solid #087eae;
  border-radius: 4px;
  background: linear-gradient(145deg,#082c49,#041c34);
  box-shadow: 0 0 12px rgba(0,174,235,.13),inset 0 0 18px rgba(0,128,194,.06);
  clip-path: polygon(0 10px,10px 0,calc(100% - 10px) 0,100% 10px,100% calc(100% - 10px),calc(100% - 10px) 100%,10px 100%,0 calc(100% - 10px));
}

.feature-panel::before {
  content:"";
  position:absolute;
  top:0;
  left:12px;
  right:12px;
  height:1px;
  background:linear-gradient(90deg,transparent,#1bd4ff,transparent);
}

.panel-head {
  height:31px;
  min-height:31px;
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap:8px;
  margin-bottom:8px;
  border-bottom:1px solid rgba(0,177,231,.3);
}

.panel-head h3 {
  margin:0;
  color:#e6f5ff;
  font-size:15px;
  font-weight:700;
  white-space:nowrap;
}

.panel-tag {
  color:#65b8df;
  font-size:10px;
  white-space:nowrap;
}

.metric-grid {
  flex:1;
  min-height:0;
  display:grid;
  grid-template-columns:repeat(2,minmax(0,1fr));
  grid-template-rows:repeat(2,minmax(0,1fr));
  gap:8px;
}

.metric-card {
  min-width:0;
  display:flex;
  align-items:center;
  gap:8px;
  padding:7px;
  border:1px solid rgba(29,117,158,.38);
  border-radius:5px;
  background:linear-gradient(135deg,#103956,#082742);
}

.metric-icon { font-size:26px; flex-shrink:0; }
.metric-card small,.metric-card strong { display:block; }
.metric-card small { color:#a9c5d9; font-size:11px; }
.metric-card strong { margin-top:3px; color:#f2f9ff; font-size:23px; white-space:nowrap; }
.metric-card strong i { margin-left:3px; font-size:10px; font-style:normal; }

.fruit-stat-grid {
  flex:1;
  display:grid;
  grid-template-columns:repeat(2,1fr);
  grid-template-rows:repeat(2,1fr);
  gap:8px;
}

.fruit-stat {
  position:relative;
  display:flex;
  align-items:center;
  justify-content:center;
  gap:5px;
  flex-direction:column;
  border:1px solid #16557a;
  border-radius:5px;
  background:#0b304d;
}
.fruit-stat small { color:#aac5d8; font-size:11px; }
.fruit-stat strong { color:#eff9ff; font-size:25px; }
.fruit-stat i { position:absolute; right:9px; bottom:8px; color:#8aaec5; font-size:10px; font-style:normal; }
.fruit-stat.total { border-color:#119bc5; }

.scroll-area {
  flex:1;
  min-height:0;
  overflow-y:auto;
  overflow-x:hidden;
  scrollbar-width:thin;
  scrollbar-color:#148bbd #062039;
  padding-right:4px;
}
.scroll-area::-webkit-scrollbar { width:5px; }
.scroll-area::-webkit-scrollbar-track { background:#062039; border-radius:5px; }
.scroll-area::-webkit-scrollbar-thumb { background:#1688b8; border-radius:5px; }
.scroll-area::-webkit-scrollbar-thumb:hover { background:#29cafa; }

.sensor-row,.plant-row {
  width:100%;
  min-height:30px;
  display:grid;
  grid-template-columns:1fr auto auto;
  align-items:center;
  gap:8px;
  padding:5px 7px;
  color:#c4d9e7;
  text-align:left;
  border:0;
  border-bottom:1px solid rgba(54,117,150,.18);
  background:transparent;
  cursor:pointer;
  font-size:11px;
}
.sensor-row strong { color:#e5f6ff; font-size:11px; }
.sensor-row i { color:#36d99b; font-size:10px; font-style:normal; }
.sensor-row.active,.plant-row.active { background:#104465; border-left:2px solid #23cafa; }
.sensor-row:hover,.plant-row:hover,.archive-row:hover { background:#104465; }

.status-list { display:flex; flex-direction:column; }
.status-row {
  min-height:28px;
  display:grid;
  grid-template-columns:1fr auto 12px;
  align-items:center;
  gap:7px;
  border-bottom:1px solid rgba(54,117,150,.18);
  color:#bad2e2;
  font-size:11px;
}
.status-row strong { color:#e5f6ff; font-size:11px; }
.normal-dot,.online-row i { width:7px;height:7px;border-radius:50%;background:#36d99b;box-shadow:0 0 7px #36d99b; }
.status-hint { padding:7px 3px;color:#6faac9;font-size:10px; }

.scene-panel { padding:10px; }
.scene-body {
  position:relative;
  flex:1;
  min-height:0;
  overflow:hidden;
  border:1px solid #117fa8;
  border-radius:3px;
  background:#08243b;
}
.scene-body img { width:100%;height:100%;object-fit:cover;display:block; }
.scene-shade { position:absolute;inset:0;background:linear-gradient(180deg,rgba(1,15,28,.12),transparent 45%,rgba(1,15,28,.25));pointer-events:none; }
.scene-tags { position:absolute;top:12px;left:12px;display:flex;flex-direction:column;gap:7px; }
.scene-tags span,.detect-label {
  width:max-content;
  padding:6px 9px;
  color:#e8f8ff;
  background:rgba(3,29,48,.84);
  border:1px solid rgba(38,196,238,.7);
  border-radius:3px;
  font-size:11px;
}
.scene-watermark { position:absolute;right:12px;bottom:10px;color:rgba(230,248,255,.6);font-size:10px;letter-spacing:2px; }
.live-label { color:#37d99c;font-size:11px;white-space:nowrap; }
.live-label i { display:inline-block;width:7px;height:7px;margin-right:5px;border-radius:50%;background:#36d99b;box-shadow:0 0 8px #36d99b; }
.scene-footer { min-height:24px;display:flex;align-items:center;justify-content:space-between;gap:6px;color:#81a8c1;font-size:10px;white-space:nowrap; }
.detection-overlay { position:absolute;inset:0; }
.detect { position:absolute;border:2px solid #32e795;box-shadow:0 0 8px #32e795; }
.detect-one { left:20%;top:24%;width:24%;height:36%; }
.detect-two { left:52%;top:28%;width:25%;height:39%;border-color:#ffdb42;box-shadow:0 0 8px #ffdb42; }
.detect-three { left:38%;top:54%;width:22%;height:27%;border-color:#ff664e;box-shadow:0 0 8px #ff664e; }
.detect-label { position:absolute;right:12px;top:12px; }

.control-content { flex:1;min-height:0;display:flex;flex-direction:column;gap:7px; }
.mode-switch { display:flex;align-items:center;gap:6px;color:#a9c5d9;font-size:11px; }
.mode-switch span { margin-right:auto; }
.mode-switch button,.device-control button {
  padding:5px 9px;
  color:#bcd8e8;
  border:1px solid #16547a;
  border-radius:4px;
  background:#0a2d49;
  font-size:10px;
  cursor:pointer;
}
.mode-switch button.active,.primary-action { color:white;background:#087cac;border-color:#1bbdf0; }
.device-control { display:grid;grid-template-columns:1fr 1fr;gap:8px; }
.device-control>div { display:grid;grid-template-columns:1fr auto;gap:5px;padding:7px;background:#0b304c;border-radius:4px;color:#bcd4e4;font-size:11px; }
.device-control strong { color:#a9c3d4;font-size:10px; }
.device-control strong.online { color:#36d99b; }
.device-control button { grid-column:1 / -1; }
.control-note { color:#39c5ed;font-size:10px; }
.strategy-row { display:flex;justify-content:space-between;gap:6px;padding:3px 0;border-bottom:1px solid rgba(54,117,150,.2);color:#a9c5d9;font-size:10px; }
.strategy-row strong { color:#e3f4fc; }

.plant-list { display:flex;flex-direction:column; }
.plant-row { grid-template-columns:45px 1fr auto;min-height:31px; }
.plant-id { color:#28c6f1;font-weight:700; }
.plant-row strong { color:#38d79e;font-size:10px; }
.stage-summary { padding:8px 2px; }
.stage-summary h4 { margin:0 0 7px;color:#dceef9;font-size:12px; }
.stage-line { display:grid;grid-template-columns:50px 1fr 32px;align-items:center;gap:6px;margin:7px 0;color:#9dbbd0;font-size:10px; }
.stage-line>div { height:6px;background:#143750;border-radius:5px;overflow:hidden; }
.stage-line i { display:block;height:100%;background:linear-gradient(90deg,#087cb0,#28c9ec);border-radius:5px; }

.fert-control { flex:1;min-height:0;display:flex;flex-direction:column;gap:6px;overflow-y:auto;scrollbar-width:thin;scrollbar-color:#1688b8 #062039; }
.fert-current { display:grid;grid-template-columns:1fr 1fr;gap:8px; }
.fert-current>div { padding:7px;background:#0b304d;border:1px solid #16557a;border-radius:4px; }
.fert-current small,.fert-current strong { display:block; }
.fert-current small { color:#9fbdd1;font-size:10px; }
.fert-current strong { margin-top:4px;color:#eaf8ff;font-size:19px; }
.fert-current strong i { font-size:9px;font-style:normal; }
.target-inputs { display:grid;grid-template-columns:1fr 1fr;gap:7px; }
.target-inputs label { color:#a9c4d8;font-size:10px; }
.target-inputs input { width:100%;margin-top:4px;padding:6px;color:#f1faff;background:#061f37;border:1px solid #17658d;border-radius:4px; }
.deviation-row { display:flex;justify-content:space-between;color:#a9c5d9;font-size:10px; }
.deviation-row strong { color:#ffbd4a;font-size:12px; }
.deviation-row strong.negative { color:#29c9ee; }
.deviation-row strong.positive { color:#ffae45; }
.advice-text { padding:5px 7px;background:#0b304c;border-radius:3px;color:#b7d2e2;font-size:10px;line-height:1.5; }
.primary-action { padding:8px;border-radius:4px;font-size:11px;cursor:pointer; }
.demo-warning { color:#779cb5;font-size:9px;line-height:1.4; }

.growth-summary { flex:1;display:flex;flex-direction:column;justify-content:space-around;gap:7px; }
.summary-highlight { display:flex;align-items:center;justify-content:space-between;color:#a8c3d7;font-size:11px; }
.summary-highlight strong { color:#e9f7ff;font-size:22px; }
.summary-highlight i { font-size:10px;font-style:normal; }
.summary-pair { display:grid;grid-template-columns:1fr 1fr;gap:8px; }
.summary-pair>div { padding:8px;background:#0b304c;border-radius:4px; }
.summary-pair small,.summary-pair strong { display:block; }
.summary-pair small { color:#9fbcd0;font-size:10px; }
.summary-pair strong { margin-top:4px;color:#35d3f2;font-size:17px; }
.summary-note { color:#8eb2c9;font-size:10px; }

.chart-area { flex:1;min-height:0;width:100%; }
.growth-accuracy { flex:1;min-height:0;display:flex;flex-direction:column; }
.video-state { color:#38d99c;font-size:10px; }
.video-state i { display:inline-block;width:6px;height:6px;margin-right:5px;border-radius:50%;background:#38d99c; }

.period-tabs { display:flex;gap:4px; }
.period-tabs button { padding:4px 7px;color:#a9c4d8;background:#0b304c;border:1px solid #16547a;border-radius:3px;font-size:9px;cursor:pointer; }
.period-tabs button.active { color:white;background:#087eae;border-color:#21c5f2; }

.online-list { display:flex;flex-direction:column; }
.online-row { min-height:25px;display:grid;grid-template-columns:1fr auto 14px;align-items:center;gap:6px;color:#a9c5d9;font-size:10px;border-bottom:1px solid rgba(54,117,150,.18); }
.online-row strong { color:#39d99b;font-size:10px; }

.donut-wrap { flex:1;min-height:0;display:grid;grid-template-columns:1.2fr 1fr;align-items:center; }
.donut-chart { width:100%;height:100%;min-height:110px; }
.donut-legend { display:flex;flex-direction:column;gap:12px;color:#bfd5e3;font-size:10px; }
.donut-legend span { display:flex;align-items:center;gap:6px; }
.donut-legend i { width:8px;height:8px;border-radius:50%; }

.environment-warning { flex:1;min-height:0;display:flex;flex-direction:column; }
.score-row { display:flex;align-items:center;justify-content:space-between;color:#b4ccdc;font-size:11px; }
.score-row strong { color:#38d99b;font-size:22px; }
.score-row strong i { color:#8daec3;font-size:10px;font-style:normal; }
.score-track { height:6px;margin:7px 0;background:#143750;border-radius:5px;overflow:hidden; }
.score-track i { display:block;width:92%;height:100%;background:linear-gradient(90deg,#1b9acb,#37d99b); }
.alert-list { margin-top:3px; }
.alert-row { min-height:34px;display:grid;grid-template-columns:14px 1fr auto;align-items:center;gap:6px;border-bottom:1px solid rgba(54,117,150,.18); }
.alert-row>span { color:#36d99b;font-size:11px; }
.alert-row>span.warning { color:#ffb33e; }
.alert-row strong,.alert-row small { display:block; }
.alert-row strong { color:#c8dce9;font-size:10px;font-weight:500; }
.alert-row small { color:#789eb7;font-size:9px; }
.alert-row button { padding:3px 7px;color:#d7f2ff;background:#0d5277;border:1px solid #137fa8;border-radius:3px;font-size:9px;cursor:pointer; }
.resolved { color:#36d99b !important; }

.record-list { display:flex;flex-direction:column; }
.record-row { min-height:43px;display:flex;align-items:center;justify-content:space-between;gap:7px;border-bottom:1px solid rgba(54,117,150,.18); }
.record-row strong,.record-row small { display:block; }
.record-row strong { color:#d8eaf5;font-size:10px; }
.record-row small { margin-top:3px;color:#8caec3;font-size:9px; }
.record-row>div:last-child { text-align:right; }
.record-done { color:#36d99b !important; }

.archive-list { display:flex;flex-direction:column; }
.archive-row { width:100%;min-height:43px;display:grid;grid-template-columns:43px 1fr 15px;align-items:center;gap:7px;padding:5px 3px;color:#bcd2e0;background:transparent;border:0;border-bottom:1px solid rgba(54,117,150,.2);text-align:left;cursor:pointer; }
.archive-row>span { color:#36c9ed;font-size:10px; }
.archive-row strong,.archive-row small { display:block; }
.archive-row strong { color:#dcebf5;font-size:10px; }
.archive-row small { margin-top:3px;color:#87a9bf;font-size:9px; }
.archive-row b { color:#31c5ed;font-size:18px; }
.archive-row.active { background:#104465; }
.archive-detail { padding:7px;color:#38c9ed;background:#0a304b;font-size:10px; }

@media(max-width:1450px) {
  .feature-page { padding:12px;gap:10px; }
  .feature-top,.feature-bottom { grid-template-columns:minmax(245px,1fr) minmax(420px,1.8fr) minmax(245px,1fr);gap:9px; }
  .feature-panel { padding:8px; }
  .metric-card { gap:5px;padding:5px; }
  .metric-icon { font-size:21px; }
  .metric-card strong { font-size:19px; }
  .panel-head h3 { font-size:13px; }
}

@media(max-height:780px) {
  .feature-page { min-height:620px;padding-top:9px;padding-bottom:9px;gap:9px; }
  .feature-top,.feature-bottom { gap:8px; }
  .feature-stack { gap:7px; }
  .feature-panel { padding:7px 9px; }
  .panel-head { height:27px;min-height:27px;margin-bottom:5px; }
  .metric-card strong { font-size:18px; }
}
</style>



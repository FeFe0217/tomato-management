$ErrorActionPreference = 'Stop'
Set-Location 'D:\tomato-management'
if (!(Test-Path '.\src\views\DashboardView.vue')) { throw '未找到现有项目。请确认目录 D:\tomato-management。' }

$backup = Join-Path $env:TEMP ('tomato-ui-backup-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$affected = @('src\views\DashboardView.vue','src\views\EnvironmentView.vue','src\views\IrrigationView.vue','src\views\GrowthView.vue','src\components\DetailPage.vue','src\components\DemoChart.vue')
foreach ($f in $affected) {
  if (Test-Path $f) { Copy-Item -LiteralPath $f -Destination (Join-Path $backup (($f -replace '[\\/]','__'))) }
}

# 综合总览：仅修预警截断、增强科技边框、添加跳转
$dashPath = '.\src\views\DashboardView.vue'
$dash = Get-Content -LiteralPath $dashPath -Raw
if ($dash -notmatch 'dashboard-link') {
  $dash = $dash.Replace('<section class="panel env-panel">','<section class="panel env-panel dashboard-link" role="link" tabindex="0" @click="goEnvironment" @keydown.enter="goEnvironment">')
  $dash = $dash.Replace('<section class="panel irrigation-panel">','<section class="panel irrigation-panel dashboard-link" role="link" tabindex="0" @click="goIrrigation" @keydown.enter="goIrrigation">')
  $dash = $dash.Replace('<section class="panel recognition-panel">','<section class="panel recognition-panel dashboard-link" role="link" tabindex="0" @click="goGrowth" @keydown.enter="goGrowth">')
  $dash = $dash.Replace('<section class="panel growth-analysis-panel">','<section class="panel growth-analysis-panel dashboard-link" role="link" tabindex="0" @click="goGrowth" @keydown.enter="goGrowth">')
  $routerCode = @'
<script setup>
import { useRouter } from 'vue-router'
const router = useRouter()
const goEnvironment = () => router.push('/environment')
const goIrrigation = () => router.push('/irrigation')
const goGrowth = () => router.push('/growth')
'@
  $dash = $dash.Replace('<script setup>', $routerCode)
}
if ($dash -notmatch 'td-dashboard-patch') {
  $dashboardCss = @'
/* td-dashboard-patch：仅修复预警显示、边框与导航交互 */
.warnings-panel .warning-list { flex: 1; min-height: 0; justify-content: space-around; }
.warnings-panel .warning-item { min-height: 0; flex: 1 1 0; padding: 3px 0; }
.panel { border-radius: 0 !important; border: 1px solid #0b9ac7 !important; clip-path: polygon(0 10px, 10px 0, calc(100% - 10px) 0, 100% 10px, 100% calc(100% - 10px), calc(100% - 10px) 100%, 10px 100%, 0 calc(100% - 10px)); box-shadow: inset 0 0 14px rgba(0,170,255,.13), 0 0 15px rgba(0,195,255,.18) !important; }
.panel::after { content: ''; pointer-events: none; position: absolute; inset: 0; background: linear-gradient(90deg, rgba(20,209,255,.12), transparent 22%, transparent 78%, rgba(20,209,255,.12)); opacity: .65; }
.dashboard-link { cursor: pointer; }
.dashboard-link:hover { border-color: #4ee6ff !important; box-shadow: inset 0 0 22px rgba(0,207,255,.17), 0 0 20px rgba(0,207,255,.3) !important; }
.dashboard-link:focus-visible { outline: 2px solid #4ee6ff; outline-offset: 2px; }
</style>
'@
  $dash = $dash.Replace('</style>', $dashboardCss)
}
Set-Content -LiteralPath $dashPath -Value $dash -Encoding utf8

Set-Content -LiteralPath '.\src\components\DemoChart.vue' -Encoding utf8 -Value @'
<script setup>
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import * as echarts from 'echarts'

const props = defineProps({ kind: { type: String, required: true }, range: { type: String, default: '24h' } })
const holder = ref(null)
let chart = null
let resizeObserver = null
const axisColor = '#83acc6'
const chartColors = ['#26caff', '#27d6a1', '#f3b65a', '#ff6971']

function base() {
  const label = props.range === '7天' ? ['周一','周二','周三','周四','周五','周六','周日'] : props.range === '30天' ? ['1日','5日','10日','15日','20日','25日','30日'] : ['00:00','04:00','08:00','12:00','16:00','20:00','24:00']
  return { label, tooltip: { trigger: 'axis', backgroundColor: '#082740', borderColor: '#16a5d6', textStyle: { color: '#effaff' } }, grid: { left: 36, right: 15, top: 35, bottom: 28 }, xAxis: { type: 'category', boundaryGap: false, data: label, axisTick: { show: false }, axisLine: { lineStyle: { color: '#265678' } }, axisLabel: { color: axisColor, fontSize: 10 } }, yAxis: { type: 'value', axisLabel: { color: axisColor, fontSize: 10 }, splitLine: { lineStyle: { color: 'rgba(74,138,171,.17)' } } } }
}
function line(name, values, color, index = 0) { return { name, type: 'line', smooth: true, symbol: 'circle', symbolSize: 4, yAxisIndex: index, data: values, lineStyle: { width: 2, color }, itemStyle: { color }, areaStyle: { color: color + '12' } } }
function bar(name, values, color) { return { name, type: 'bar', data: values, barWidth: '42%', itemStyle: { color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [{ offset: 0, color }, { offset: 1, color: '#0b4266' }]), borderRadius: [4,4,0,0] } } }
function pie(data, centerText) { return { backgroundColor: 'transparent', tooltip: { trigger: 'item', backgroundColor: '#082740', borderColor: '#16a5d6', textStyle: { color: '#effaff' } }, series: [{ type: 'pie', radius: ['55%','78%'], center: ['50%','50%'], label: { show: false }, data: data.map((item,i) => ({ name: item[0], value: item[1], itemStyle: { color: chartColors[i % chartColors.length], borderColor: '#08223b', borderWidth: 2 } })) }], graphic: [{ type:'text', left:'center', top:'43%', style: { text: centerText, fill:'#e7f8ff', fontSize:16, fontWeight:'bold', textAlign:'center' } }] } }
function option() {
  if (props.kind === 'growthPie') return pie([['青果',40],['转色果',35],['成熟果',53]], '128个')
  if (props.kind === 'waterModes') return pie([['自动模式',20],['手动模式',5]], '自动80%')
  if (props.kind === 'envScore') return pie([['适宜',92],['待改善',8]], '92分')
  const b = base()
  let series = []
  if (props.kind === 'envTrend') series = [line('温度℃',[22,21,23,27,29,27,26.5],chartColors[0]),line('空气湿度%',[72,75,71,65,62,66,68],chartColors[1]),line('土壤湿度%',[51,49,48,55,54,53,52],chartColors[2]),line('光照×1000lx',[0,0,5,12,9,2,0],chartColors[3])]
  if (props.kind === 'envMini') series = [line('温度℃',[22,21,23,27,29,27,26.5],chartColors[2]),line('湿度%',[72,75,71,65,62,66,68],chartColors[0])]
  if (props.kind === 'soil') { series = [bar('土壤湿度%',[48,50,55,49,53,52],chartColors[1])]; b.xAxis.data = ['A01','A02','A03','A04','A05','A06']; b.xAxis.boundaryGap = true }
  if (props.kind === 'light') series = [line('光照lx',[0,800,4300,12000,9000,1300,0],chartColors[0])]
  if (props.kind === 'waterTrend') { series = [bar('用水量L',[12.6,14.3,15.1,16.4,17.8,15.7,18.5],chartColors[0])]; b.xAxis.boundaryGap = true }
  if (props.kind === 'waterDaily') { series = [bar('灌溉次数',[2,2,3,3,3,2,3],chartColors[0]),line('用水量L',[12.6,14.3,15.1,16.4,17.8,15.7,18.5],chartColors[1],1)]; b.xAxis.boundaryGap = true; b.yAxis = [{ type:'value', min:0, max:5, axisLabel:{ color:axisColor }, splitLine:{ lineStyle:{ color:'rgba(74,138,171,.15)' } } },{ type:'value', min:0, max:25, axisLabel:{ color:axisColor }, splitLine:{ show:false } }] }
  if (props.kind === 'waterDistribution') { series = [bar('用水量L',[3.0,3.1,3.2,3.1,3.3,2.8],chartColors[1])]; b.xAxis.data=['A01','A02','A03','A04','A05','A06']; b.xAxis.boundaryGap = true }
  if (props.kind === 'growthTrend') series = [line('果实总数',[95,101,107,113,118,123,128],chartColors[0]),line('青果',[36,37,38,39,39,40,40],chartColors[1]),line('转色果',[30,31,33,34,34,35,35],chartColors[2]),line('成熟果',[29,33,36,40,45,48,53],chartColors[3])]
  if (props.kind === 'confidence') series = [line('模拟置信度%',[93.5,94.0,94.2,94.8,95.1,95.3,95.6],chartColors[1])]
  return { ...b, backgroundColor:'transparent', legend: { top:0, textStyle: { color:'#a8cce0', fontSize:10 }, itemWidth:10, itemHeight:8 }, series }
}
function render() { if (chart) chart.setOption(option(), true) }
onMounted(() => { chart = echarts.init(holder.value); render(); resizeObserver = new ResizeObserver(() => chart?.resize()); resizeObserver.observe(holder.value) })
watch(() => [props.kind, props.range], render)
onBeforeUnmount(() => { resizeObserver?.disconnect(); chart?.dispose(); chart = null })
</script>
<template><div ref="holder" class="td-chart"></div></template>
<style scoped>.td-chart{width:100%;height:100%;min-height:125px}</style>
'@

Set-Content -LiteralPath '.\src\components\DetailPage.vue' -Encoding utf8 -Value @'
<script setup>
import { computed, ref } from 'vue'
import DemoChart from './DemoChart.vue'

const props = defineProps({ section: { type: String, required: true } })
const range = ref('24h')
const selectedPot = ref('A01')
const mode = ref('自动')
const pump = ref(false)
const valve = ref(false)
const photoIndex = ref(0)
const photos = ['/images/greenhouse-demo.jpg','/images/tomato-fruits-demo.jpg']
const logs = ref([{ time:'11-27 09:10', text:'自动灌溉完成', detail:'5.8 L' },{ time:'11-26 16:20', text:'自动灌溉完成', detail:'6.2 L' },{ time:'11-26 09:00', text:'手动灌溉完成', detail:'4.5 L' }])
const config = {
  environment: { title:'环境监测', badge:'模拟传感器数据', metrics:[['空气温度','26.5','℃','🌡'],['空气湿度','68','%','💧'],['土壤湿度','52','%','🌱'],['光照强度','12000','lx','☀']], scene:'种植区域环境监测画面' },
  irrigation: { title:'水肥管理', badge:'模拟设备控制', metrics:[['今日灌溉','3','次','💧'],['今日用水','18.5','L','◉'],['当前模式','自动','模式','⚙'],['水箱余量','72','%','▤']], scene:'种植区域水肥运行画面' },
  growth: { title:'生长监测', badge:'演示图片 / 模拟识别', metrics:[['果实总数','128','个','◎'],['青果','40','个','🌱'],['转色果','35','个','●'],['成熟果','53','个','🍅']], scene:'种植区域生长监测画面' }
}
const c = computed(() => config[props.section])
const currentPhoto = computed(() => photos[photoIndex.value])
function togglePump() { if (mode.value !== '手动') return; pump.value = !pump.value; logs.value.unshift({time:'当前演示',text:pump.value?'模拟启动水泵':'模拟停止水泵',detail:'无实际硬件'}); logs.value = logs.value.slice(0,4) }
function toggleValve() { if (mode.value !== '手动') return; valve.value = !valve.value; logs.value.unshift({time:'当前演示',text:valve.value?'模拟打开电磁阀':'模拟关闭电磁阀',detail:'无实际硬件'}); logs.value = logs.value.slice(0,4) }
const switchPhoto = () => { photoIndex.value = (photoIndex.value+1) % photos.length }
</script>

<template>
  <div class="tomato-detail">
    <div class="td-kpis">
      <div v-for="(m,i) in c.metrics" :key="m[0]" class="td-kpi td-panel">
        <span class="td-kpi-icon">{{m[3]}}</span>
        <div><small>{{m[0]}}</small><strong>{{m[1]}} <em>{{m[2]}}</em></strong><span>● {{section==='irrigation'?'模拟运行状态':'演示监测数据'}}</span></div>
        <i class="td-kpi-line"></i>
      </div>
    </div>

    <div class="td-main">
      <div class="td-side">
        <section class="td-panel td-side-panel">
          <h3>{{section==='environment'?'监测点状态':section==='irrigation'?'设备状态':'监测对象'}}</h3>
          <template v-if="section==='environment'">
            <div class="td-row" v-for="v in [['🌡','空气温度传感器','在线'],['💧','空气湿度传感器','在线'],['🌱','土壤湿度传感器','在线'],['☀','光照传感器','在线']]" :key="v[1]"><span>{{v[0]}} {{v[1]}}</span><b class="ok">● {{v[2]}}（模拟）</b></div>
          </template>
          <template v-else-if="section==='irrigation'">
            <div class="td-row" v-for="v in [['水泵',pump?'运行中':'待机'],['电磁阀',valve?'开启':'关闭'],['流量计','正常'],['水箱液位','72%']]" :key="v[0]"><span>{{v[0]}}</span><b class="ok">{{v[1]}}（模拟）</b></div>
          </template>
          <template v-else>
            <button v-for="pot in ['A01','A02','A03','A04','A05','A06']" :key="pot" class="td-pot" :class="{active:selectedPot===pot}" @click="selectedPot=pot"><span>🌱 {{pot}} 号盆栽</span><b>{{selectedPot===pot?'当前查看':'生长良好'}}</b></button>
          </template>
        </section>
        <section class="td-panel td-side-panel">
          <h3>{{section==='environment'?'环境预警':section==='irrigation'?'灌溉策略与模拟控制':'生长阶段统计'}}</h3>
          <template v-if="section==='environment'">
            <div class="td-row"><span>⚠ 土壤湿度接近下限</span><b class="warn">待关注</b></div>
            <div class="td-row"><span>✓ 环境温度正常</span><b class="ok">正常</b></div>
            <div class="td-row"><span>✓ 光照水平正常</span><b class="ok">正常</b></div>
          </template>
          <template v-else-if="section==='irrigation'">
            <div class="td-row"><span>灌溉启动阈值</span><b>35%</b></div><div class="td-row"><span>灌溉停止阈值</span><b>55%</b></div><div class="td-row"><span>单次最大时长</span><b>10分钟</b></div>
            <div class="td-buttons"><button :class="{active:mode==='自动'}" @click="mode='自动'">自动模式</button><button :class="{active:mode==='手动'}" @click="mode='手动'">手动模式</button></div>
            <div class="td-buttons"><button :disabled="mode!=='手动'" @click="togglePump">{{pump?'停止水泵':'启动水泵'}}</button><button :disabled="mode!=='手动'" @click="toggleValve">{{valve?'关闭阀门':'打开阀门'}}</button></div>
          </template>
          <template v-else>
            <div class="td-row"><span>🟢 青果</span><b>40 个 · 31.3%</b></div><div class="td-row"><span>🟡 转色果</span><b>35 个 · 27.3%</b></div><div class="td-row"><span>🔴 成熟果</span><b>53 个 · 41.4%</b></div>
            <p class="td-note">当前为模拟识别统计，尚未运行真实 AI 推理。</p>
          </template>
        </section>
      </div>

      <section class="td-panel td-main-scene">
        <div class="td-panel-title"><h3>{{c.scene}}</h3><span class="td-tag">{{c.badge}}</span></div>
        <div class="td-photo">
          <img :src="section==='growth'?currentPhoto:'/images/greenhouse-demo.jpg'" alt="番茄种植区演示素材" />
          <span class="td-overlay-label">实验种植区 A区　|　{{section==='growth'?selectedPot:'A01-A06'}}</span>
          <template v-if="section==='environment'">
            <span class="td-point p1">🌡 温度 26.5℃</span><span class="td-point p2">☀ 光照 12000 lx</span><span class="td-point p3">💧 空气湿度 68%</span><span class="td-point p4">🌱 土壤湿度 52%</span>
          </template>
          <template v-if="section==='irrigation'">
            <span class="td-flow-flow" :class="{running:pump}"></span>
            <span class="td-point p1">水箱 · 72%</span><span class="td-point p2">水泵 · {{pump?'模拟运行':'模拟待机'}}</span><span class="td-point p3">电磁阀 · {{valve?'模拟开启':'模拟关闭'}}</span><span class="td-point p4">滴灌支路 · 6路</span>
          </template>
          <template v-if="section==='growth'">
            <span class="td-detect d1">青果 · 示例</span><span class="td-detect d2">转色果 · 示例</span><span class="td-detect d3">成熟果 · 示例</span>
            <button class="td-photo-switch" @click="switchPhoto">切换演示图片 ›</button>
          </template>
        </div>
        <div class="td-scene-footer"><span>● {{section==='growth'?'演示图片 / 暂无实时视频':section==='irrigation'?'模拟水肥流程 / 未接入设备':'模拟监测点 / 未接入传感器'}}</span><span>当前模式：演示</span></div>
      </section>

      <div class="td-side">
        <section class="td-panel td-side-panel">
          <h3>{{section==='environment'?'环境状态':section==='irrigation'?'实时运行状态':'识别结果摘要'}}</h3>
          <template v-if="section==='environment'">
            <div class="td-score">92 <small>分</small><span>环境综合评分（模拟）</span></div>
            <div class="td-row"><span>空气温度</span><b class="ok">适宜</b></div><div class="td-row"><span>空气湿度</span><b class="ok">适宜</b></div><div class="td-row"><span>监测点在线</span><b>4/4（模拟）</b></div>
          </template>
          <template v-else-if="section==='irrigation'">
            <div class="td-score">{{pump?'2.6':'0.0'}} <small>L/min</small><span>模拟瞬时流量</span></div>
            <div class="td-row"><span>今日用水量</span><b>18.5 L</b></div><div class="td-row"><span>灌溉方式</span><b class="ok">{{mode}}模式</b></div><div class="td-row"><span>控制状态</span><b class="ok">仅模拟</b></div>
          </template>
          <template v-else>
            <div class="td-score">128 <small>个</small><span>演示果实识别总数</span></div>
            <div class="td-row"><span>模拟平均置信度</span><b>95.6%</b></div><div class="td-row"><span>当前监测对象</span><b>{{selectedPot}}</b></div><div class="td-row"><span>识别来源</span><b class="ok">演示数据</b></div>
          </template>
        </section>
        <section class="td-panel td-side-panel td-mini-chart-panel">
          <h3>{{section==='environment'?'环境波动分析':section==='irrigation'?'近7日用水趋势':'模拟识别置信度趋势'}}</h3>
          <DemoChart :kind="section==='environment'?'envMini':section==='irrigation'?'waterTrend':'confidence'" />
        </section>
      </div>
    </div>

    <div class="td-bottom">
      <section class="td-panel td-bottom-panel td-large-chart">
        <div class="td-panel-title"><h3>{{section==='environment'?'24小时环境变化分析':section==='irrigation'?'每日灌溉与用水统计':'近7日果实数量变化'}}</h3><div v-if="section==='environment'" class="td-buttons"><button v-for="x in ['24h','7天','30天']" :key="x" :class="{active:range===x}" @click="range=x">{{x}}</button></div></div>
        <DemoChart :kind="section==='environment'?'envTrend':section==='irrigation'?'waterDaily':'growthTrend'" :range="range" />
      </section>
      <section class="td-panel td-bottom-panel"><h3>{{section==='environment'?'土壤湿度分布':section==='irrigation'?'灌溉模式占比':'成熟度占比'}}</h3><DemoChart :kind="section==='environment'?'soil':section==='irrigation'?'waterModes':'growthPie'" /></section>
      <section class="td-panel td-bottom-panel"><h3>{{section==='environment'?'光照分时分析':section==='irrigation'?'各盆用水分布':'历史生长档案'}}</h3>
        <DemoChart v-if="section!=='growth'" :kind="section==='environment'?'light':'waterDistribution'" />
        <div v-else class="td-history"><button v-for="(p,i) in photos" :key="p" @click="photoIndex=i"><img :src="p" alt="演示生长档案照片"/><span>{{i===0?'11-20 生长期':'11-27 结果期'}}</span></button></div>
      </section>
      <section class="td-panel td-bottom-panel"><h3>{{section==='environment'?'环境预警记录':section==='irrigation'?'近期灌溉记录':'最近识别记录'}}</h3>
        <template v-if="section==='environment'"><div class="td-row"><span>11-27 14:20</span><b class="warn">土壤湿度接近下限</b></div><div class="td-row"><span>11-27 12:30</span><b class="ok">环境状态正常</b></div><div class="td-row"><span>11-26 17:10</span><b class="ok">光照已恢复</b></div></template>
        <template v-else-if="section==='irrigation'"><div v-for="(log,i) in logs" :key="i" class="td-row"><span>{{log.time}} · {{log.text}}</span><b>{{log.detail}}</b></div></template>
        <template v-else><div v-for="(date,i) in ['11-27 15:30','11-26 15:30','11-25 15:30']" :key="date" class="td-row"><span>{{date}}</span><b class="ok">模拟识别 {{128-i*3}} 个</b></div></template>
      </section>
    </div>
    <div class="td-disclaimer">演示系统：所有数字、传感器在线状态、设备运行状态与 AI 统计均为模拟数据；图片为演示素材。未接入真实硬件。</div>
  </div>
</template>

<style scoped>
.tomato-detail{height:calc(100vh - 88px);min-height:760px;padding:16px 18px;display:grid;grid-template-rows:100px minmax(350px,1.55fr) minmax(250px,1fr) 16px;gap:12px;background:radial-gradient(ellipse at 50% 20%,#10314c,#031629 75%);color:#e6f4fc;font-size:12px}
.td-kpis{display:grid;grid-template-columns:repeat(4,minmax(0,1fr));gap:12px;min-height:0}.td-panel{min-width:0;min-height:0;position:relative;padding:12px;overflow:hidden;background:linear-gradient(135deg,#0c304c,#061e36 85%);border:1px solid #0c95c1;clip-path:polygon(0 10px,10px 0,calc(100% - 10px) 0,100% 10px,100% calc(100% - 10px),calc(100% - 10px) 100%,10px 100%,0 calc(100% - 10px));box-shadow:0 0 15px #029bd12a,inset 0 0 19px #01abdb12}.td-panel::before{content:'';position:absolute;top:0;left:18px;right:18px;height:1px;background:linear-gradient(90deg,transparent,#36cfff,transparent);opacity:.75;pointer-events:none}
.td-kpi{display:flex;align-items:center;gap:15px;padding:15px 20px}.td-kpi-icon{font-size:34px;color:#33d8bb}.td-kpi small,.td-kpi strong,.td-kpi span:not(.td-kpi-icon){display:block}.td-kpi small{color:#94b5c9;font-size:12px}.td-kpi strong{font-size:30px;color:#e6faff;margin:5px 0}.td-kpi strong em{font-size:12px;color:#37d8ba;font-style:normal}.td-kpi div>span{color:#40d7a7;font-size:10px}.td-kpi-line{margin-left:auto;width:55px;height:25px;border-bottom:2px solid #20badb;transform:skewY(-12deg);opacity:.6}
.td-main{display:grid;grid-template-columns:minmax(250px,1fr) minmax(430px,1.95fr) minmax(250px,1fr);gap:12px;min-height:0}.td-side{display:grid;grid-template-rows:1fr 1fr;gap:12px;min-height:0}.td-side-panel{display:flex;flex-direction:column}.td-panel h3{font-size:14px;font-weight:700;margin:0 0 11px;border-bottom:1px solid #1a5775;padding-bottom:9px;white-space:nowrap}.td-row{display:flex;align-items:center;justify-content:space-between;gap:7px;padding:9px 2px;border-bottom:1px solid #1a49644d;color:#c9deec;font-size:11px}.td-row b{color:#e6f9ff;font-size:11px;white-space:nowrap}.td-row .ok,.ok{color:#35dca8!important}.td-row .warn,.warn{color:#efb556!important}.td-mini-chart-panel{display:flex;flex-direction:column}.td-mini-chart-panel :deep(.td-chart){flex:1;min-height:130px}.td-score{margin:5px auto;color:#32d8b8;font-size:34px;text-shadow:0 0 13px #16b0b858}.td-score small{font-size:15px}.td-score span{display:block;text-align:center;color:#9cbbd0;font-size:11px;text-shadow:none}.td-note{color:#8eacc1;font-size:10px;line-height:1.6}.td-buttons{display:flex;justify-content:flex-end;gap:5px;flex-wrap:wrap}.td-buttons button,.td-photo-switch{border:1px solid #1c6791;background:#093450;color:#aad7ee;padding:5px 8px;border-radius:4px;font-size:11px;cursor:pointer}.td-buttons button.active{background:#086b95;border-color:#26cffc;color:#fff}.td-buttons button:disabled{opacity:.4;cursor:not-allowed}.td-pot{display:flex;justify-content:space-between;align-items:center;color:#c4e4f5;background:#0b3653;border:1px solid #144d69;margin-bottom:5px;padding:5px 9px;cursor:pointer;font-size:11px}.td-pot.active{border-color:#27cdea;background:#0b5a74}.td-pot b{color:#34d6a6;font-size:10px}
.td-main-scene{display:flex;flex-direction:column}.td-panel-title{display:flex;align-items:center;justify-content:space-between;gap:6px}.td-tag{color:#44e1c0;font-size:10px;border:1px solid #1e8f94;padding:4px 8px;border-radius:4px;white-space:nowrap}.td-photo{position:relative;flex:1;min-height:0;border:1px solid #187699;overflow:hidden;background:linear-gradient(135deg,#092840,#0b433b)}.td-photo>img{display:block;width:100%;height:100%;object-fit:cover;filter:brightness(.85)}.td-overlay-label{position:absolute;top:9px;left:9px;background:#041e35bc;padding:6px 10px;color:#c8f1ed;font-size:10px;border:1px solid #168cb1}.td-point{position:absolute;background:#072940d9;border:1px solid #23d1ee;box-shadow:0 0 12px #13e0f454;color:#eefcff;padding:7px 9px;border-radius:3px;font-size:11px}.p1{left:8%;top:24%}.p2{right:6%;top:16%}.p3{right:7%;bottom:22%}.p4{left:16%;bottom:17%}.td-flow-flow{position:absolute;left:12%;right:15%;top:54%;height:5px;background:#16bdf680;transform:rotate(-9deg);box-shadow:0 0 16px #0deaff;opacity:.45}.td-flow-flow.running{opacity:1;animation:flash 1s infinite alternate}@keyframes flash{to{filter:brightness(2)}}.td-detect{position:absolute;border:2px solid #37e69f;background:#072a28bf;padding:4px 7px;color:#caffdf}.d1{left:20%;top:25%;width:24%;height:35%}.d2{right:18%;top:28%;width:25%;height:37%;border-color:#f9c75c;color:#ffe49c}.d3{left:40%;bottom:12%;width:23%;height:28%;border-color:#ff726c;color:#ffd5d5}.td-photo-switch{position:absolute;bottom:10px;right:10px;background:#074366d9}.td-scene-footer{display:flex;justify-content:space-between;margin-top:8px;font-size:10px;color:#5adabf}
.td-bottom{min-height:0;display:grid;grid-template-columns:1.45fr 1fr 1fr 1.05fr;gap:12px}.td-bottom-panel{display:flex;flex-direction:column}.td-bottom-panel :deep(.td-chart){flex:1;min-height:150px}.td-bottom-panel .td-panel-title h3{border:0;margin:0;padding:0}.td-bottom-panel .td-panel-title{border-bottom:1px solid #1a5775;padding-bottom:6px;margin-bottom:5px}.td-disclaimer{text-align:center;color:#789db5;font-size:10px}.td-history{display:grid;grid-template-columns:1fr 1fr;gap:7px;flex:1;min-height:0}.td-history button{background:#082b49;border:1px solid #186887;color:#c6ecf4;cursor:pointer;padding:4px;font-size:10px}.td-history img{display:block;width:100%;height:75%;max-height:125px;object-fit:cover}.td-history span{display:block;margin-top:5px}
@media(max-width:1460px){.tomato-detail{min-height:850px}.td-main{grid-template-columns:minmax(230px,1fr) minmax(390px,1.7fr) minmax(230px,1fr)}.td-bottom{grid-template-columns:1.4fr 1fr 1fr 1fr}.td-row{font-size:10px;padding:7px 0}.td-kpi strong{font-size:26px}}
</style>
'@

Set-Content -LiteralPath '.\src\views\EnvironmentView.vue' -Encoding utf8 -Value @'
<script setup>import DetailPage from '../components/DetailPage.vue'</script>
<template><DetailPage section="environment" /></template>
'@
Set-Content -LiteralPath '.\src\views\IrrigationView.vue' -Encoding utf8 -Value @'
<script setup>import DetailPage from '../components/DetailPage.vue'</script>
<template><DetailPage section="irrigation" /></template>
'@
Set-Content -LiteralPath '.\src\views\GrowthView.vue' -Encoding utf8 -Value @'
<script setup>import DetailPage from '../components/DetailPage.vue'</script>
<template><DetailPage section="growth" /></template>
'@

npm run build
if ($LASTEXITCODE -ne 0) { throw '构建失败，请把终端错误发给我。备份在：' + $backup }
Write-Host '三个功能页面、总览预警修复与跳转已写入，构建通过。' -ForegroundColor Green
Write-Host ('原文件备份位置：' + $backup)

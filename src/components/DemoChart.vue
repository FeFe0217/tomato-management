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

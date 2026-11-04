<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%!
// ===== 把 Java 集合转成合法的 JS 数组字面量 =====
// 坑：List<String>.toString() 得到的是 [内科, 外科]，即“不带引号的中文”；
//     浏览器会把它当成变量名去解析，直接抛 ReferenceError，整个 <script> 从此中断。
//     所以字符串必须逐个用双引号包起来并做转义。
String jsStrList(java.util.List<String> list){
    StringBuilder b = new StringBuilder("[");
    for(int i=0;i<list.size();i++){
        if(i>0) b.append(",");
        String s = list.get(i);
        if(s==null) s = "";
        b.append("\"").append(s.replace("\\","\\\\").replace("\"","\\\"")
                            .replace("\r","").replace("\n","\\n")).append("\"");
    }
    return b.append("]").toString();
}
String jsNumList(java.util.List<?> list){
    StringBuilder b = new StringBuilder("[");
    for(int i=0;i<list.size();i++){
        if(i>0) b.append(",");
        Object v = list.get(i);
        b.append(v==null ? "0" : String.valueOf(v));
    }
    return b.append("]").toString();
}
%>
<%
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}

// ===== 准备看板数据（逐个查询，每个结果集用完再查下一个） =====
List<String> kb = new ArrayList<String>();      // 科室
List<Integer> pc = new ArrayList<Integer>();     // 各科室病人数
ResultSet r1 = a.executeQuery("SELECT kebie,COUNT(*) c FROM patient GROUP BY kebie");
while(r1.next()){ kb.add(r1.getString("kebie")==null?"未知":r1.getString("kebie")); pc.add(r1.getInt("c")); }

List<String> bs = new ArrayList<String>();       // 床位状态
List<Integer> bc = new ArrayList<Integer>();      // 各状态数量
ResultSet r2 = a.executeQuery("SELECT state,COUNT(*) c FROM bed GROUP BY state");
while(r2.next()){ bs.add(r2.getString("state")==null?"未知":r2.getString("state")); bc.add(r2.getInt("c")); }

List<String> gk = new ArrayList<String>();       // 挂号科室
List<Integer> gc = new ArrayList<Integer>();      // 各科室挂号量
ResultSet r3 = a.executeQuery("SELECT kebie,COUNT(*) c FROM guahao GROUP BY kebie");
while(r3.next()){ gk.add(r3.getString("kebie")==null?"未知":r3.getString("kebie")); gc.add(r3.getInt("c")); }

List<String> ck = new ArrayList<String>();       // 收费项目
List<Double> cm = new ArrayList<Double>();       // 各项目金额
ResultSet r4 = a.executeQuery("SELECT xiangmu,SUM(jine+0) s FROM cost GROUP BY xiangmu");
while(r4.next()){ ck.add(r4.getString("xiangmu")==null?"未知":r4.getString("xiangmu")); cm.add(r4.getDouble("s")); }

// KPI
int totalPatient = 0, totalDoctor = 0, emptyBed = 0, totalGuahao = 0;
ResultSet r5 = a.executeQuery("SELECT COUNT(*) c FROM patient"); if(r5.next()) totalPatient=r5.getInt("c");
ResultSet r6 = a.executeQuery("SELECT COUNT(*) c FROM doctor");  if(r6.next()) totalDoctor=r6.getInt("c");
ResultSet r7 = a.executeQuery("SELECT COUNT(*) c FROM bed WHERE state='空' OR state='空闲'"); if(r7.next()) emptyBed=r7.getInt("c");
ResultSet r8 = a.executeQuery("SELECT COUNT(*) c FROM guahao");  if(r8.next()) totalGuahao=r8.getInt("c");
a.close();

// 转成 JS 数组字符串（字符串数组必须加引号，数值数组直接输出）
String jKb = jsStrList(kb), jBs = jsStrList(bs), jGk = jsStrList(gk), jCk = jsStrList(ck);
String jPc = jsNumList(pc), jBc = jsNumList(bc), jGc = jsNumList(gc), jCm = jsNumList(cm);
%>
<html>
<head>
<title>数据看板</title>
<script src="https://cdn.jsdelivr.net/npm/echarts@5.4.3/dist/echarts.min.js"></script>
<style type="text/css">
body{font-family:"Microsoft YaHei",Arial;background:#f3f6fb;margin:0;}
.topbar{background:#347fbd;color:#fff;padding:12px 20px;font-size:17px;font-weight:bold;}
.kpis{display:flex;gap:14px;padding:18px 20px;}
.kpi{flex:1;background:#fff;border-radius:8px;padding:16px;text-align:center;box-shadow:0 1px 4px #cdd8e6;}
.kpi .num{font-size:28px;color:#0277bd;font-weight:bold;}
.kpi .lab{font-size:13px;color:#666;margin-top:4px;}
.grid{display:flex;flex-wrap:wrap;gap:14px;padding:0 20px 20px;align-items:flex-start;}
.cell{background:#fff;border-radius:8px;box-shadow:0 1px 4px #cdd8e6;padding:8px;}
.cell h4{margin:6px 10px;font-size:14px;color:#333;}
.chart{width:560px;height:320px;}
/* ===== AI 自然语言查询条 ===== */
.ai-bar{margin:0 20px 14px;background:#fff;border-radius:8px;box-shadow:0 1px 4px #cdd8e6;padding:14px 16px;}
.ai-bar .row1{display:flex;align-items:center;gap:10px;}
.ai-bar .tag{background:linear-gradient(135deg,#4f81b3,#5c6bc0);color:#fff;font-size:12px;padding:3px 10px;border-radius:10px;white-space:nowrap;}
.ai-bar input{flex:1;border:1px solid #cdd8e6;border-radius:6px;padding:8px 12px;font-size:14px;outline:none;}
.ai-bar input:focus{border-color:#4f81b3;}
.ai-bar button{background:linear-gradient(135deg,#4f81b3,#5c6bc0);color:#fff;border:none;border-radius:6px;
  padding:8px 22px;font-size:14px;cursor:pointer;}
.ai-bar button:hover{opacity:.9;}
.ai-bar button:disabled{opacity:.5;cursor:not-allowed;}
.ai-bar .chips{margin-top:9px;display:flex;gap:8px;flex-wrap:wrap;}
.ai-bar .chip{font-size:12px;color:#5c6bc0;background:#f0ecff;border:1px solid #d5ccff;border-radius:12px;
  padding:3px 12px;cursor:pointer;}
.ai-bar .chip:hover{background:#e3daff;}
#aiCell{width:576px;}
.empty{height:320px;display:flex;flex-direction:column;align-items:center;justify-content:center;color:#b0b3bd;font-size:14px;text-align:center;padding:0 10px;}
#aiNote{font-size:12px;color:#e65100;margin:2px 12px 6px;}
#aiConclusion{font-size:13px;color:#333;margin:2px 12px 8px;font-weight:bold;}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-stats.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-stats">
<div class="topbar">医院运营数据看板</div>
<div class="kpis">
  <div class="kpi"><div class="num"><%=totalPatient%></div><div class="lab">在册病人</div></div>
  <div class="kpi"><div class="num"><%=totalDoctor%></div><div class="lab">医生总数</div></div>
  <div class="kpi"><div class="num"><%=emptyBed%></div><div class="lab">空闲床位</div></div>
  <div class="kpi"><div class="num"><%=totalGuahao%></div><div class="lab">挂号总量</div></div>
</div>

<!-- ===== AI 自然语言查询 ===== -->
<div class="ai-bar">
  <div class="row1">
    <span class="tag">AI 智能查询</span>
    <input id="aiQ" type="text" placeholder="用一句话查数据，例如：最近7天哪个医生挂号最多？"
      onkeydown="if(event.keyCode===13)runAIQ()"/>
    <button id="aiBtn" onclick="runAIQ()">查询</button>
  </div>
  <div class="chips">
    <span class="chip" onclick="quickQ('最近7天哪个医生挂号最多')">最近7天哪个医生挂号最多</span>
    <span class="chip" onclick="quickQ('各科室挂号量分布')">各科室挂号量分布</span>
    <span class="chip" onclick="quickQ('收费金额按项目统计')">收费金额按项目统计</span>
    <span class="chip" onclick="quickQ('最近30天每天的挂号趋势')">最近30天每天的挂号趋势</span>
  </div>
</div>

<div class="grid">
  <div class="cell"><h4>各科室病人分布</h4><div id="c1" class="chart"></div></div>
  <div class="cell"><h4>床位状态分布</h4><div id="c2" class="chart"></div></div>
  <div class="cell"><h4>各科室挂号量</h4><div id="c3" class="chart"></div></div>
  <div class="cell"><h4>收费项目金额合计</h4><div id="c4" class="chart"></div></div>
  <div class="cell" id="aiCell">
    <h4>AI 查询结果</h4>
    <div id="aiNote" style="display:none"></div>
    <div id="aiConclusion" style="display:none"></div>
    <div id="c5" class="chart"></div>
  </div>
</div>

<script type="text/javascript">
var kb=<%=jKb%>, pc=<%=jPc%>;
var bs=<%=jBs%>, bc=<%=jBc%>;
var gk=<%=jGk%>, gc=<%=jGc%>;
var ck=<%=jCk%>, cm=<%=jCm%>;

// 图表库可能因网络/CDN 原因加载失败：先探测，避免整个脚本中断导致按钮“点不动”
var HAS_ECHARTS = (typeof echarts !== 'undefined');
if(!HAS_ECHARTS){
  ['c1','c2','c3','c4','c5'].forEach(function(id){
    var el=document.getElementById(id);
    if(el) el.innerHTML='<div class="empty">图表库(echarts)加载失败<br/>请检查网络后刷新页面</div>';
  });
}

if(HAS_ECHARTS){
echarts.init(document.getElementById('c1')).setOption({
  tooltip:{}, xAxis:{type:'category',data:kb}, yAxis:{type:'value'},
  series:[{type:'bar',data:pc,itemStyle:{color:'#347fbd'},label:{show:true,position:'top'}}]
});
echarts.init(document.getElementById('c2')).setOption({
  color:['#4c83b8','#82ac98','#ccb17c','#a3aec0'],
  tooltip:{}, legend:{bottom:0},
  series:[{type:'pie',radius:'55%',data:bs.map((v,i)=>({name:v,value:bc[i]})),
           label:{formatter:'{b}: {c}'}}]
});
echarts.init(document.getElementById('c3')).setOption({
  tooltip:{}, xAxis:{type:'category',data:gk}, yAxis:{type:'value'},
  series:[{type:'bar',data:gc,itemStyle:{color:'#659b87'},label:{show:true,position:'top'}}]
});
// 收费项目：条目多、名称长（"体外冲击波碎石"等），竖排柱子标签必然重叠
// 改为横向条形图：标签横排、按条目数自动撑高，并按金额从大到小排序
(function(){
  var el = document.getElementById('c4');
  if(!el) return;
  var pair = ck.map(function(n,i){ return {name:n, value:cm[i]}; })
               .sort(function(p,q){ return p.value - q.value; });  // 升序 → 金额最大的排最上面
  var maxLen = 0;
  for(var i=0;i<ck.length;i++){ if(ck[i].length>maxLen) maxLen = ck[i].length; }
  el.style.height = Math.max(320, pair.length*22 + 40) + 'px';      // 每行 22px，标签互不挤压
  echarts.init(el).setOption({
    tooltip:{trigger:'axis',axisPointer:{type:'shadow'}},
    grid:{left:Math.max(72, maxLen*13 + 12), right:70, top:10, bottom:26},
    xAxis:{type:'value'},
    yAxis:{type:'category', data:pair.map(function(d){ return d.name; }),
           axisLabel:{interval:0, fontSize:12, color:'#555'}},
    series:[{type:'bar', data:pair.map(function(d){ return d.value; }),
             itemStyle:{color:'#bd9662'}, barMaxWidth:14,
             label:{show:true, position:'right', fontSize:11, color:'#666'}}]
  });
})();
}

// ===== AI 自然语言查询 =====
var aiChart = HAS_ECHARTS ? echarts.init(document.getElementById('c5')) : null;
// 页面加载先初始化好 ECharts 实例，避免第一次查询时才创建导致偶发渲染失败
(function initEmpty(){
  if(!aiChart) return;
  aiChart.setOption({
    title:{text:'在上方输入统计问题\nAI 解析后自动生成图表',left:'center',top:'center',
           textStyle:{fontSize:14,color:'#b0b3bd'},textAlign:'center'},
    xAxis:{type:'category',data:[],show:false},
    yAxis:{type:'value',show:false},
    series:[]
  }, true);
})();

function quickQ(q){ document.getElementById('aiQ').value=q; runAIQ(); }

function renderEmpty(msg){
  if(!aiChart){   // 没有图表库时降级为文字提示，绝不抛异常
    document.getElementById('c5').innerHTML='<div class="empty">'+(msg||'暂无数据')+'</div>';
    return;
  }
  aiChart.setOption({
    title:{text:msg||'暂无数据',left:'center',top:'center',textStyle:{fontSize:14,color:'#b0b3bd'},textAlign:'center'},
    xAxis:{type:'category',data:[],show:false},
    yAxis:{type:'value',show:false},
    series:[]
  }, true);
}

function runAIQ(){
  var q=document.getElementById('aiQ').value.trim();
  if(!q){ alert('请输入统计问题'); return; }
  var btn=document.getElementById('aiBtn');
  btn.disabled=true; btn.textContent='查询中…';
  renderEmpty('AI 正在解析问题并查询数据…');
  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"task=stats_query&q="+encodeURIComponent(q)
  }).then(function(r){
    // 如果后端返回 500/404，r.ok 为 false，这里直接抛错让外层 catch 走“网络异常”
    if(!r.ok) throw new Error('HTTP '+r.status);
    return r.json();
  }).then(function(d){
    btn.disabled=false; btn.textContent='查询';
    if(!d.ok){ renderEmpty(d.error||'查询失败'); return; }
    var x=d.data;
    var noteEl=document.getElementById('aiNote'), conEl=document.getElementById('aiConclusion');
    if(x.note){ noteEl.textContent=''+x.note; noteEl.style.display='block'; } else { noteEl.style.display='none'; }
    if(!x.rows || x.rows.length===0){
      conEl.style.display='none';
      renderEmpty('该问题没有查询到数据，换个问法试试');
      return;
    }
    conEl.textContent=''+x.conclusion; conEl.style.display='block';
    if(!aiChart){ renderEmpty('图表库未加载，结论见上方文字'); return; }
    var names = x.rows.map(function(r){return r.name;});
    var vals  = x.rows.map(function(r){return r.value;});
    var color = x.metric==='fee' ? '#bd9662' : (x.metric==='patient' ? '#659b87' : '#4f81b3');
    try {
      aiChart.setOption({
        title:{text:x.title,left:10,top:4,textStyle:{fontSize:13,color:'#555'}},
        tooltip:{},
        grid:{left:50,right:20,bottom:60,top:40},
        xAxis:{type:'category',data:names,axisLabel:{interval:0,rotate:30,fontSize:11},show:true},
        yAxis:{type:'value',show:true},
        series:[{type:'bar',data:vals,itemStyle:{color:color},
          label:{show:true,position:'top',fontSize:11}}]
      }, true);  // true = 不合并，整体替换
    } catch(err) {
      console.error('ECharts render error', err);
      renderEmpty('图表渲染失败：'+err.message);
    }
  }).catch(function(e){
    btn.disabled=false; btn.textContent='查询';
    console.error('fetch/network error', e);
    renderEmpty('网络异常，请稍后重试');
  });
}

// 窗口大小变化时重绘
function resizeDashboardCharts(){ if(!HAS_ECHARTS)return; document.querySelectorAll('.chart').forEach(function(el){var chart=echarts.getInstanceByDom(el);if(chart)chart.resize();}); }
window.addEventListener('resize',resizeDashboardCharts);
if(window.ResizeObserver){var dashboardObserver=new ResizeObserver(resizeDashboardCharts);document.querySelectorAll('.cell').forEach(function(el){dashboardObserver.observe(el);});}
</script>
</body>
</html>

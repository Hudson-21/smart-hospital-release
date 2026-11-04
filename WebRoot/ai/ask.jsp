<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String usertype = (String)session.getAttribute("usertype");
String roleName = "访客";
// 注意：usertype 在本库里存的是中文（管理员/医生/病人），英文值只在老数据里出现，两种都要认
if("管理员".equals(usertype) || "admin".equalsIgnoreCase(usertype)) roleName="管理员";
else if("医生".equals(usertype) || "doctor".equalsIgnoreCase(usertype)) roleName="医生";
else if("病人".equals(usertype) || "patient".equalsIgnoreCase(usertype)) roleName="病人";
// 注入到 JS 里的当前账号（本地会话历史要按账号隔离，必须先做转义防止破坏 JS）
String jsUser = loginname.replace("\\","\\\\").replace("\"","\\\"");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>智能导诊助手 · 小医</title>
<style>
  * { margin:0; padding:0; box-sizing:border-box; }
  html, body { height:100%; }
  body { font-family:"PingFang SC","Microsoft YaHei",Helvetica,Arial,sans-serif; display:flex; background:#fff; color:#1f2023; }

  /* ===== 左侧深色会话栏 ===== */
  .sidebar { width:260px; flex-shrink:0; background:#171717; color:#ececf1; display:flex; flex-direction:column; height:100%; }
  .sidebar-top { padding:14px 12px 8px; }
  .new-chat {
    width:100%; padding:11px 12px; background:#2a2b32; color:#fff; border:1px solid #4d4e57;
    border-radius:9px; cursor:pointer; font-size:14px; display:flex; align-items:center; gap:10px; transition:background .2s;
  }
  .new-chat:hover { background:#343541; }
  .conv-list { flex:1; overflow-y:auto; padding:8px; margin-top:6px; }
  .conv-list::-webkit-scrollbar { width:6px; }
  .conv-list::-webkit-scrollbar-thumb { background:#3a3b44; border-radius:3px; }
  .conv-item {
    padding:10px 12px; border-radius:8px; font-size:13.5px; color:#c5c5d1; cursor:pointer;
    white-space:nowrap; overflow:hidden; text-overflow:ellipsis; margin-bottom:4px;
    display:flex; align-items:center; gap:9px; transition:background .15s;
  }
  .conv-item:hover { background:#2a2b32; }
  .conv-item.active { background:#343541; color:#fff; }
  .conv-item .ico { flex-shrink:0; opacity:.8; }
  .conv-item .txt { flex:1; overflow:hidden; text-overflow:ellipsis; }
  .conv-item .del { flex-shrink:0; opacity:0; font-size:13px; color:#9b9bab; padding:0 2px; }
  .conv-item:hover .del { opacity:1; }
  .conv-item .del:hover { color:#f87171; }
  .sidebar-bottom {
    padding:12px; border-top:1px solid #2a2b32; display:flex; align-items:center; gap:10px;
  }
  .sidebar-bottom .uavatar {
    width:34px; height:34px; border-radius:50%; background:linear-gradient(135deg,#1976d2,#42a5f5);
    display:flex; align-items:center; justify-content:center; color:#fff; font-size:14px; flex-shrink:0;
  }
  .sidebar-bottom .uinfo { overflow:hidden; }
  .sidebar-bottom .uname { font-size:13.5px; color:#ececf1; white-space:nowrap; overflow:hidden; text-overflow:ellipsis; }
  .sidebar-bottom .urole { font-size:11.5px; color:#8e8ea0; }

  /* ===== 右侧主区域 ===== */
  .main { flex:1; display:flex; flex-direction:column; height:100%; min-width:0; }
  .main-header {
    height:54px; flex-shrink:0; border-bottom:1px solid #ececf1; display:flex; align-items:center;
    justify-content:space-between; padding:0 20px; background:#fff;
  }
  .main-header .title { font-size:15px; font-weight:600; display:flex; align-items:center; gap:9px; }
  .main-header .title .dot { width:9px; height:9px; border-radius:50%; background:#22c55e; box-shadow:0 0 0 3px rgba(34,197,94,.18); }
  .main-header .right { display:flex; align-items:center; gap:14px; }
  .model-tag { font-size:12px; color:#666; background:#f0f0f3; padding:4px 12px; border-radius:20px; }
  .clear-btn { font-size:12.5px; color:#8e8ea0; cursor:pointer; padding:5px 10px; border-radius:7px; transition:background .15s; }
  .clear-btn:hover { background:#f0f0f3; color:#444; }

  .msgs { flex:1; overflow-y:auto; background:#fff; }
  .msgs::-webkit-scrollbar { width:8px; }
  .msgs::-webkit-scrollbar-thumb { background:#d9d9e3; border-radius:4px; }
  .msgs-inner { max-width:760px; margin:0 auto; padding:26px 20px 30px; display:flex; flex-direction:column; gap:22px; }
  .msg { display:flex; gap:14px; align-items:flex-start; animation:fadeIn .25s ease; }
  @keyframes fadeIn { from{opacity:0; transform:translateY(6px);} to{opacity:1; transform:translateY(0);} }
  .msg.user { flex-direction:row-reverse; }
  .avatar { width:32px; height:32px; border-radius:7px; flex-shrink:0; display:flex; align-items:center; justify-content:center; font-size:14px; }
  .avatar.bot { background:linear-gradient(135deg,#1976d2,#42a5f5); color:#fff; }
  .avatar.user { background:#e8e8ee; color:#333; }
  .bubble {
    max-width:72%; padding:12px 16px; border-radius:18px; font-size:15px; line-height:1.75;
    white-space:pre-wrap; word-break:break-word; box-shadow:0 1px 3px rgba(0,0,0,.04);
  }
  .bubble.bot { background:#f5f7fa; color:#1f2023; border-top-left-radius:5px; }
  .bubble.user { background:#2563eb; color:#fff; border-top-right-radius:5px; }
  .bubble.typing::after { content:"▍"; display:inline-block; margin-left:1px; color:#1976d2; animation:blink 1s infinite; }
  .bubble.user.typing::after { color:#fff; }
  @keyframes blink { 0%,100%{opacity:1;} 50%{opacity:0;} }

  /* 欢迎页 */
  .welcome { max-width:680px; margin:0 auto; padding:8vh 20px 0; text-align:center; }
  .welcome h1 { font-size:27px; font-weight:600; margin-bottom:12px; letter-spacing:.5px; }
  .welcome p { color:#8e8ea0; font-size:14.5px; margin-bottom:32px; }
  .chips { display:flex; flex-wrap:wrap; gap:12px; justify-content:center; }
  .chip {
    padding:12px 18px; border:1px solid #e2e2ea; border-radius:13px; cursor:pointer; font-size:14px;
    color:#374151; background:#fff; transition:all .18s; display:flex; align-items:center; gap:7px;
  }
  .chip:hover { background:#f7f8fa; border-color:#c5c5d1; transform:translateY(-1px); }

  /* 输入区 */
  .input-area { padding:14px 20px 22px; background:#fff; border-top:1px solid #f0f0f3; }
  .input-box { max-width:760px; margin:0 auto; position:relative; background:#fff; border:1px solid #d9d9e3; border-radius:26px; padding:8px 8px 8px 20px; display:flex; align-items:flex-end; transition:border-color .2s, box-shadow .2s; }
  .input-box:focus-within { border-color:#60a5fa; box-shadow:0 4px 20px rgba(33,150,243,.1); }
  .input-box textarea { flex:1; border:none; outline:none; resize:none; overflow-x:hidden; overflow-y:scroll; font-size:15px; line-height:1.5; color:#1f2023; padding:9px 0; max-height:160px; background:transparent; font-family:inherit; }
  .input-box textarea::placeholder { color:#9ca3af; }
  .send-btn { width:38px; height:38px; flex-shrink:0; border:none; border-radius:50%; background:linear-gradient(135deg,#1976d2,#2196f3); color:#fff; font-size:16px; cursor:pointer; display:flex; align-items:center; justify-content:center; transition:all .2s; }
  .send-btn:hover:not(:disabled) { background:linear-gradient(135deg,#1565c0,#1e88e5); transform:scale(1.05); }
  .send-btn:disabled { background:#cbd5e1; cursor:not-allowed; }
  .hint { text-align:center; font-size:11.5px; color:#b0b3bd; margin-top:9px; }

  /* 科室推荐卡片 */
  .dept-card {
    align-self:flex-start; max-width:460px; width:100%; margin-top:10px;
    background:#fff; border:1px solid #e6e8ee; border-radius:14px; padding:14px 16px;
    box-shadow:0 2px 10px rgba(0,0,0,.05); font-size:14px; color:#374151;
  }
  .dept-card .dc-head { display:flex; align-items:center; gap:10px; }
  .dept-card .dc-icon { width:38px; height:38px; border-radius:10px; background:linear-gradient(135deg,#1976d2,#42a5f5); color:#fff; display:flex; align-items:center; justify-content:center; font-size:18px; flex-shrink:0; }
  .dept-card .dc-name { font-size:15px; font-weight:600; color:#111827; }
  .dept-card .dc-code { font-size:11px; font-weight:500; color:#2563eb; background:#eaf2ff; padding:1px 7px; border-radius:6px; margin-left:6px; }
  .dept-card .dc-loc { font-size:12px; color:#8b8fa3; margin-top:2px; }
  .dept-card .dc-intro { margin:10px 0; color:#4b5563; line-height:1.6; }
  .dept-card .dc-doctors { font-size:13px; color:#4b5563; display:flex; flex-wrap:wrap; align-items:center; gap:6px; }
  .dept-card .dc-label { color:#9aa0b0; }
  .dept-card .dc-doc { background:#f1f5f9; color:#334155; padding:2px 9px; border-radius:7px; font-size:12.5px; }
  .dept-card .dc-doc-empty { background:#fef2f2; color:#b91c1c; }
  .dept-card .dc-remain { color:#059669; margin-left:4px; }
  .dept-card .dc-btn { margin-top:12px; width:100%; padding:9px 0; border:none; border-radius:10px; background:linear-gradient(135deg,#1976d2,#2196f3); color:#fff; font-size:14px; cursor:pointer; transition:background .2s; }
  .dept-card .dc-btn:hover { background:linear-gradient(135deg,#1565c0,#1e88e5); }

  /* 强免责声明弹窗 */
  .disclaimer-mask { display:none; position:fixed; inset:0; background:rgba(15,23,42,.55); align-items:center; justify-content:center; z-index:1000; padding:20px; }
  .disclaimer-box { background:#fff; max-width:480px; width:100%; border-radius:16px; padding:26px 26px 22px; box-shadow:0 20px 60px rgba(0,0,0,.25); }
  .disclaimer-box h2 { font-size:18px; margin-bottom:14px; display:flex; align-items:center; gap:8px; }
  .disclaimer-box .dc-text { font-size:13.5px; color:#4b5563; line-height:1.8; background:#fff7ed; border:1px solid #fed7aa; border-radius:10px; padding:12px 14px; margin-bottom:18px; }
  .disclaimer-box .dc-actions { display:flex; gap:12px; justify-content:flex-end; }
  .disclaimer-box .btn-agree { background:linear-gradient(135deg,#1976d2,#2196f3); color:#fff; border:none; padding:9px 20px; border-radius:9px; cursor:pointer; font-size:14px; }
  .disclaimer-box .btn-cancel { background:#f1f5f9; color:#475569; border:none; padding:9px 18px; border-radius:9px; cursor:pointer; font-size:14px; }

  /* 结构化问诊问卷卡片 */
  .q-card { align-self:flex-start; max-width:520px; width:100%; margin-top:10px; background:#fff; border:1px solid #e6e8ee; border-radius:14px; padding:16px 18px; box-shadow:0 2px 10px rgba(0,0,0,.05); font-size:14px; color:#374151; }
  .q-card .q-title { font-size:15px; font-weight:600; color:#111827; margin-bottom:14px; display:flex; align-items:center; gap:8px; }
  .q-section { margin-bottom:14px; }
  .q-label { font-size:13px; color:#6b7280; margin-bottom:7px; }
  .q-chips { display:flex; flex-wrap:wrap; gap:8px; }
  .q-chip { padding:6px 13px; border:1px solid #d9d9e3; border-radius:20px; cursor:pointer; font-size:13px; color:#374151; background:#fff; transition:all .15s; user-select:none; }
  .q-chip:hover { border-color:#93c5fd; }
  .q-chip.sel { background:#eaf2ff; border-color:#2563eb; color:#1d4ed8; }
  .q-input { width:100%; border:1px solid #d9d9e3; border-radius:9px; padding:8px 12px; font-size:14px; outline:none; font-family:inherit; box-sizing:border-box; }
  .q-input:focus { border-color:#60a5fa; }
  .q-submit { margin-top:4px; width:100%; padding:10px 0; border:none; border-radius:10px; background:linear-gradient(135deg,#1976d2,#2196f3); color:#fff; font-size:14px; cursor:pointer; transition:background .2s; }
  .q-submit:hover { background:linear-gradient(135deg,#1565c0,#1e88e5); }
  .q-submit:disabled { background:#cbd5e1; cursor:not-allowed; }

  @media (max-width:768px){
    .sidebar { width:72px; }
    .new-chat span, .conv-item .txt, .conv-item .del, .sidebar-bottom .uinfo { display:none; }
    .new-chat { justify-content:center; }
    .conv-item { justify-content:center; }
    .bubble { max-width:82%; }
    .welcome { padding-top:5vh; }
  }
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-chat.css?v=20261104-2">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
</head>
<body class="h-chat">
  <!-- 左侧会话栏 -->
  <aside class="sidebar" aria-label="导诊会话历史">
    <div class="sidebar-top">
      <button class="new-chat" aria-label="新建对话" onclick="newChat()"><span style="font-size:17px;line-height:1;">＋</span><span>新建对话</span></button>
    </div>
    <div class="conv-list" id="convList"></div>
    <div class="sidebar-bottom">
      <div class="uavatar"><%=loginname!=null && loginname.length()>0 ? loginname.substring(0,1) : "我"%></div>
      <div class="uinfo">
        <div class="uname"><%=loginname%></div>
        <div class="urole"><%=roleName%></div>
      </div>
    </div>
  </aside>

  <!-- 右侧主区 -->
  <main class="main">
    <header class="main-header">
      <div class="title"><span class="dot"></span>智能导诊助手 · 小医</div>
      <div class="right">
        <span class="clear-btn" onclick="window.open('history.jsp','_blank')"> 问诊记录</span>
        <span class="clear-btn" onclick="clearCurrent()">清空对话</span>
      </div>
    </header>

    <div class="msgs" id="msgs">
      <div class="msgs-inner" id="msgsInner"></div>
    </div>

    <div class="input-area">
      <div class="input-box">
        <textarea aria-label="描述您的症状" id="input" rows="1" placeholder="描述症状，例如头痛、腹痛…" onkeydown="if(event.key==='Enter'&&!event.shiftKey&&!event.isComposing){event.preventDefault();send();}" oninput="autoGrow(this)"></textarea>
        <button class="send-btn" id="sendBtn" onclick="send()" title="发送" aria-label="发送">➤</button>
      </div>
      <div class="hint">回复来源见每条建议下方。仅供就诊参考，不替代医生诊断。紧急情况请立即就医或拨打 120。</div>
    </div>
  </main>

  <!-- 强免责声明（首次进入需确认） -->
  <div class="disclaimer-mask" id="disclaimerMask">
    <div class="disclaimer-box" role="dialog" aria-modal="true" aria-label="医疗免责声明">
      <h2>⚠️ 医疗免责声明</h2>
      <div class="dc-text">
        「小医」仅为基于症状的智能导诊参考工具，<b>不能替代医生的诊断与治疗</b>。<br>
        本工具给出的科室与就医建议仅供参考；如病情紧急（如剧烈胸痛、呼吸困难、大出血、昏迷等），请<b>立即前往急诊科或拨打 120</b>。
      </div>
      <div class="dc-actions">
        <button class="btn-cancel" onclick="disagreeDisclaimer()">暂不使用</button>
        <button class="btn-agree" onclick="agreeDisclaimer()">我已阅读并同意</button>
      </div>
    </div>
  </div>

<script>
const CURRENT_USER = "<%=jsUser%>";
// 会话历史必须按登录账号隔离：同一台电脑换账号登录时，
// 绝不能把上一个账号（医生/管理员）的导诊记录展示给病人
const STORE_KEY = "hospital_ai_conv_v2__" + CURRENT_USER;
// 旧版本用的是全站共用的 key（hospital_ai_conv_v1），无法判断记录属于谁，
// 存在跨角色泄露风险，这里直接清除；服务端 ai_chat 里的记录不受影响，可在「问诊记录」页查看
try { localStorage.removeItem("hospital_ai_conv_v1"); } catch(e){}
let agreed = (sessionStorage.getItem("xiao_yi_agreed") === "1"); // 是否已同意免责声明
let conversations = loadConv();
let currentId = (conversations[0] && conversations[0].id) || null;
let messages = [];
let isSending = false;

function loadConv(){
  try { return JSON.parse(localStorage.getItem(STORE_KEY)) || []; } catch(e){ return []; }
}
function saveConv(){ localStorage.setItem(STORE_KEY, JSON.stringify(conversations)); }

function renderSidebar(){
  const list = document.getElementById("convList");
  list.innerHTML = "";
  if(conversations.length === 0){
    list.innerHTML = '<div style="color:#6b6b76;font-size:12.5px;text-align:center;padding:18px 8px;">暂无对话历史</div>';
    return;
  }
  conversations.forEach(c => {
    const div = document.createElement("div");
    div.className = "conv-item" + (c.id === currentId ? " active" : "");
    div.innerHTML = '<span class="ico">·</span><span class="txt">'+escapeHtml(c.title || "新对话")+'</span><span class="del" title="删除">×</span>';
    div.onclick = (e) => { if(e.target.classList.contains("del")){ deleteConv(c.id); } else { selectConv(c.id); } };
    list.appendChild(div);
  });
}

function selectConv(id){
  currentId = id;
  const conv = conversations.find(c => c.id === id);
  messages = conv ? (conv.messages || []) : [];
  renderMessages();
  renderSidebar();
}

function newChat(){
  currentId = "c" + Date.now();
  messages = [];
  conversations.unshift({ id: currentId, title:"新对话", messages:[] });
  saveConv();
  renderMessages();
  renderSidebar();
  document.getElementById("input").focus();
}

function deleteConv(id){
  conversations = conversations.filter(c => c.id !== id);
  if(currentId === id){
    if(conversations.length > 0){ currentId = conversations[0].id; messages = conversations[0].messages || []; }
    else { currentId = null; messages = []; }
  }
  saveConv();
  renderSidebar();
  if(currentId === null) renderMessages(); else selectConv(currentId);
}

function clearCurrent(){
  if(!currentId) return;
  const conv = conversations.find(c => c.id === currentId);
  if(conv) conv.messages = [];
  messages = [];
  saveConv();
  renderMessages();
}

function renderMessages(){
  const inner = document.getElementById("msgsInner");
  if(!messages || messages.length === 0){
    inner.innerHTML =
      '<div class="welcome">' +
      '<h1>描述症状，了解就诊科室</h1>' +
      '<p>请说明不适部位、持续时间和伴随症状，导诊建议仅供就医参考。<br>也可以先填写症状问卷，或了解挂号与预约流程。</p>' +
      '<div class="chips">' +
      '<div class="chip" onclick="quick(\'我最近总是头痛头晕，是怎么回事？\')"> 头痛头晕</div>' +
      '<div class="chip" onclick="quick(\'孩子发烧咳嗽三天了，要挂什么科？\')"> 小儿发热咳嗽</div>' +
      '<div class="chip" onclick="quick(\'不小心摔了一跤，手腕很疼，是不是骨折了？\')">摔伤手腕疼</div>' +
      '<div class="chip" onclick="quick(\'胸口闷，偶尔心慌\')">胸闷心慌</div>' +
      '<div class="chip" onclick="quick(\'皮肤起红疹，很痒\')">皮肤红疹瘙痒</div>' +
      '<div class="chip" onclick="quick(\'医院介绍\')"> 医院介绍</div>' +
      '<div class="chip" onclick="quick(\'怎么挂号\')"> 怎么挂号</div>' +
      '<div class="chip" onclick="quick(\'怎么预约\')">怎么预约</div>' +
      '<div class="chip" onclick="openQuestionnaire()"> 智能问诊</div>' +
      '</div></div>';
    return;
  }
  inner.innerHTML = "";
  messages.forEach(m => {
    inner.appendChild(buildRow(m.role, m.content, false, m.source));
    if(m.card){ const c = buildCard(m.card); if(c) inner.appendChild(c); }
  });
  scrollBottom();
}

function buildRow(role, text, withCursor, source){
  const row = document.createElement("div");
  row.className = "msg " + (role === "user" ? "user" : "assistant");
  const av = document.createElement("div");
  av.className = "avatar " + (role === "user" ? "user" : "bot");
  av.textContent = role === "user" ? "我" : "小";
  const bub = document.createElement("div");
  bub.className = "bubble " + (role === "user" ? "user" : "bot") + (withCursor ? " typing" : "");
  setBubbleText(bub, text, role);
  if(role !== "user") setReplySource(bub, source || {source:withCursor ? "pending" : "unknown"});
  row.appendChild(av);
  row.appendChild(bub);
  return row;
}

// Only recognize bold emphasis; model-provided HTML is always a text node.
function setBubbleText(bubble, text, role){
  let content = bubble.querySelector(".reply-text");
  if(!content){ content = document.createElement("div"); content.className="reply-text"; bubble.prepend(content); }
  content.replaceChildren();
  if(role === "user"){ content.textContent=text; return; }
  const pattern = /\*\*([^*\n]+)\*\*/g;
  let start=0, match;
  while((match=pattern.exec(text)) !== null){
    content.appendChild(document.createTextNode(text.slice(start,match.index)));
    const strong=document.createElement("strong"); strong.textContent=match[1]; content.appendChild(strong);
    start=pattern.lastIndex;
  }
  content.appendChild(document.createTextNode(text.slice(start)));
}
function setReplySource(bubble, meta){
  let label=bubble.querySelector(".reply-source");
  if(!label){ label=document.createElement("div"); label.className="reply-source"; bubble.appendChild(label); }
  const source=meta && meta.source;
  label.dataset.source=source || "unknown";
  if(source === "llm") label.textContent="大模型回复 · " + (meta.model || "已收到模型响应");
  else if(source === "local") label.textContent="本地规则回复" + (meta.detail ? " · " + meta.detail : "");
  else if(source === "pending") label.textContent="正在等待服务响应…";
  else if(source === "error") label.textContent="请求未完成，请重试";
  else label.textContent="回复来源未记录";
}

function escapeHtml(t){ const d=document.createElement("div"); d.textContent=t; return d.innerHTML; }
function scrollBottom(){ const m=document.getElementById("msgs"); m.scrollTop = m.scrollHeight; }
function autoGrow(el){ el.style.height="auto"; el.style.height=Math.min(el.scrollHeight,160)+"px"; }

// 渲染后端推送的科室卡片（含医生与今日号源，带"去挂号"按钮）
function buildCard(card){
  if(!card || !card.name) return null;
  const wrap = document.createElement("div");
  wrap.className = "dept-card";
  const isEmergency = card.name === "急诊科";
  let docsHtml = (card.doctors && card.doctors.length)
    ? card.doctors.map(d=>'<span class="dc-doc">'+escapeHtml(d)+'</span>').join("")
    : '<span class="dc-doc dc-doc-empty">暂无出诊医生</span>';
  const remainHtml = (card.todayRemain>0) ? '今日剩余号源：<b>'+card.todayRemain+'</b>' : '今日号源已满';
  wrap.innerHTML =
    '<div class="dc-head">'+
      '<div class="dc-icon">'+(isEmergency?'🚑':'')+'</div>'+
      '<div class="dc-titles"><div class="dc-name">'+escapeHtml(card.name)+
        (card.code?' <span class="dc-code">'+escapeHtml(card.code)+'</span>':'')+'</div>'+
        (card.location?'<div class="dc-loc"> '+escapeHtml(card.location)+'</div>':'')+
      '</div>'+
    '</div>'+
    (card.intro?'<div class="dc-intro">'+escapeHtml(card.intro)+'</div>':'')+
    '<div class="dc-doctors"><span class="dc-label">出诊医生：</span>'+docsHtml+
      ' <span class="dc-remain">'+remainHtml+'</span></div>'+
    '<button class="dc-btn">'+(isEmergency?'立即前往急诊科':'去挂号 →')+'</button>';
  wrap.querySelector(".dc-btn").addEventListener("click", function(){ goGuahao(card.name); });
  return wrap;
}

// 跳转到挂号页并预选科室（相对路径：当前在 /ai/，挂号页在 /patient/）
function goGuahao(name){
  window.location.href = "../patient/guahao.jsp?dept=" + encodeURIComponent(name);
}

function quick(t){
  const input = document.getElementById("input");
  input.value = t;
  send();
}

function send(presetText, extra){
  if(isSending) return;
  if(!agreed){ showDisclaimer(); return; }
  const input = document.getElementById("input");
  const text = (presetText!=null) ? presetText.trim() : input.value.trim();
  if(!text) return;

  // 确保有当前会话
  if(!currentId){
    currentId = "c" + Date.now();
    conversations.unshift({ id:currentId, title:"新对话", messages:[] });
  }
  // 首条消息作为会话标题
  const conv = conversations.find(c => c.id === currentId);
  if(messages.length === 0 && conv) conv.title = text.slice(0, 18);

  messages.push({ role:"user", content:text });
  conv.messages = messages;
  saveConv();
  renderSidebar();

  // 渲染：先清欢迎页，再加入用户消息 + 机器人占位
  const inner = document.getElementById("msgsInner");
  if(inner.querySelector(".welcome")) inner.innerHTML = "";
  inner.appendChild(buildRow("user", text));
  const botRow = buildRow("assistant", "", true);
  inner.appendChild(botRow);
  const botBub = botRow.querySelector(".bubble");
  scrollBottom();

  input.value = "";
  autoGrow(input);
  const btn = document.getElementById("sendBtn");
  btn.disabled = true;
  isSending = true;

  let fullReply = "";
  let currentCard = null;
  let replySource = {source:"unknown"};
  let finished = false;
  // 收尾：定稿文本、写入历史、渲染科室卡片
  function finishReply(){
    if(finished) return;
    finished = true;
    botBub.classList.remove("typing");
    setBubbleText(botBub, fullReply, "assistant");
    setReplySource(botBub, replySource);
    const msgObj = { role:"assistant", content:fullReply, source:replySource };
    if(currentCard) msgObj.card = currentCard;
    messages.push(msgObj);
    conv.messages = messages;
    saveConv();
    if(currentCard){
      const cardEl = buildCard(currentCard);
      if(cardEl) document.getElementById("msgsInner").appendChild(cardEl);
    }
    btn.disabled = false;
    isSending = false;
  }
  // 组装请求体（支持结构化问诊参数）
  let body = "messages=" + encodeURIComponent(JSON.stringify(messages));
  if(extra){
    body += "&part=" + encodeURIComponent(extra.part||"") + "&syms=" + encodeURIComponent(extra.syms||"")
          + "&dur=" + encodeURIComponent(extra.dur||"") + "&acc=" + encodeURIComponent(extra.acc||"");
  }
  fetch("api.jsp", {
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body: body
  })
  .then(resp => {
    if(!resp.ok || !resp.body) throw new Error("状态码：" + resp.status);
    const reader = resp.body.getReader();
    const decoder = new TextDecoder("utf-8");
    let buffer = "";
    function read(){
      return reader.read().then(({done, value}) => {
        if(done){ finishReply(); return; }
        buffer += decoder.decode(value, {stream:true});
        const parts = buffer.split("\n\n");
        buffer = parts.pop();
        for(let i=0; i<parts.length; i++){
          const ev = parts[i].trim();
          if(!ev.startsWith("data:")) continue;
          const json = ev.substring(5).trim();
          try{
            const data = JSON.parse(json);
            if(data.done){ finishReply(); return; }
            else if(data.meta){
              replySource = data.meta;
              if(data.meta.reset){ fullReply=""; setBubbleText(botBub, "", "assistant"); }
              setReplySource(botBub, replySource);
            }
            else if(data.card){ currentCard = data.card; }
            else if(data.chunk){ fullReply += data.chunk; setBubbleText(botBub, fullReply, "assistant"); scrollBottom(); }
          } catch(e){}
        }
        return read();
      });
    }
    return read();
  })
  .catch(err => {
    botBub.classList.remove("typing");
    setBubbleText(botBub, "网络异常，请稍后重试。", "assistant");
    setReplySource(botBub, {source:"error"});
    btn.disabled = false;
    isSending = false;
    console.error(err);
  });
}

// ===== 强制免责声明 =====
function showDisclaimer(){ const m=document.getElementById("disclaimerMask"); if(m) m.style.display="flex"; }
function hideDisclaimer(){ const m=document.getElementById("disclaimerMask"); if(m) m.style.display="none"; }
function agreeDisclaimer(){
  agreed = true;
  sessionStorage.setItem("xiao_yi_agreed","1");
  hideDisclaimer();
  document.getElementById("input").disabled = false;
  document.getElementById("sendBtn").disabled = false;
  document.getElementById("input").focus();
}
function disagreeDisclaimer(){
  hideDisclaimer();
  document.getElementById("input").disabled = true;
  document.getElementById("sendBtn").disabled = true;
  const inner = document.getElementById("msgsInner");
  inner.innerHTML = '<div class="welcome"><h1>已退出智能导诊</h1><p>如需使用，请刷新页面并同意免责声明。</p></div>';
}

// ===== 结构化症状问卷 =====
function openQuestionnaire(){
  if(!agreed){ showDisclaimer(); return; }
  const inner = document.getElementById("msgsInner");
  if(inner.querySelector(".welcome")) inner.innerHTML = "";
  const row = document.createElement("div");
  row.className = "msg assistant";
  row.innerHTML = '<div class="avatar bot">小</div>';
  row.appendChild(buildQuestionnaire());
  inner.appendChild(row);
  scrollBottom();
}
function buildQuestionnaire(){
  const wrap = document.createElement("div");
  wrap.className = "q-card";
  const state = { part:"", dur:"", syms:"", acc:new Set() };
  const parts = ["头部","胸部","腹部","四肢关节","皮肤","五官","全身","其他"];
  const durs  = ["今天刚出现","1-3天","4-7天","超过1周","反复出现"];
  const accs  = ["发热","恶心呕吐","头晕","乏力","出血","无"];
  wrap.innerHTML =
    '<div class="q-title"> 智能问诊 · 请选择您的情况</div>'+
    '<div class="q-section"><div class="q-label">1. 主要不适部位（单选）</div><div class="q-chips" id="qPart"></div></div>'+
    '<div class="q-section"><div class="q-label">2. 具体症状描述</div><input class="q-input" id="qSyms" placeholder="如：头痛、咳嗽、腹痛…"></div>'+
    '<div class="q-section"><div class="q-label">3. 持续时间（单选）</div><div class="q-chips" id="qDur"></div></div>'+
    '<div class="q-section"><div class="q-label">4. 伴随症状（可多选）</div><div class="q-chips" id="qAcc"></div></div>'+
    '<button class="q-submit" id="qSubmit">生成分诊建议</button>';
  // 部位
  const qPart = wrap.querySelector("#qPart");
  parts.forEach(p=>{
    const c = document.createElement("span"); c.className="q-chip"; c.textContent=p;
    c.onclick=()=>{ state.part=p; qPart.querySelectorAll(".q-chip").forEach(x=>x.classList.remove("sel")); c.classList.add("sel"); };
    qPart.appendChild(c);
  });
  // 时长
  const qDur = wrap.querySelector("#qDur");
  durs.forEach(d=>{
    const c=document.createElement("span"); c.className="q-chip"; c.textContent=d;
    c.onclick=()=>{ state.dur=d; qDur.querySelectorAll(".q-chip").forEach(x=>x.classList.remove("sel")); c.classList.add("sel"); };
    qDur.appendChild(c);
  });
  // 伴随（多选；"无"为独占）
  const qAcc = wrap.querySelector("#qAcc");
  accs.forEach(a=>{
    const c=document.createElement("span"); c.className="q-chip multi"; c.textContent=a;
    c.onclick=()=>{
      if(a==="无"){ state.acc.clear(); qAcc.querySelectorAll(".q-chip").forEach(x=>x.classList.remove("sel")); c.classList.add("sel"); return; }
      if(state.acc.has(a)){ state.acc.delete(a); c.classList.remove("sel"); }
      else { state.acc.add(a); c.classList.add("sel"); }
      if(state.acc.size>0){ qAcc.querySelectorAll(".q-chip").forEach(x=>{ if(x.textContent==="无") x.classList.remove("sel"); }); }
    };
    qAcc.appendChild(c);
  });
  // 提交：生成结构化文本 + 携带字段给后端分诊
  wrap.querySelector("#qSubmit").onclick = ()=>{
    if(!state.part){ alert("请先选择主要不适部位"); return; }
    const syms = wrap.querySelector("#qSyms").value.trim();
    const acc = Array.from(state.acc).join("、");
    const summary = "【智能问诊】部位：" + state.part + "；症状：" + (syms||"未填写") + "；持续：" + (state.dur||"未填写") + (acc? "；伴随："+acc : "");
    wrap.querySelectorAll("input,button,.q-chip").forEach(el=>el.style.pointerEvents="none");
    wrap.querySelector("#qSubmit").textContent = "已提交，正在生成建议…";
    send(summary, { part: state.part, syms: syms, dur: state.dur, acc: acc });
  };
  return wrap;
}

// 初始化
if(conversations.length > 0){
  selectConv(currentId);
} else {
  renderMessages();
  renderSidebar();
}
if(agreed){
  hideDisclaimer();
} else {
  document.getElementById("input").disabled = true;
  document.getElementById("sendBtn").disabled = true;
  showDisclaimer();
}
document.getElementById("input").focus();
</script>
</body>
</html>

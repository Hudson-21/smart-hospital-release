<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!("医生".equals(usertype)||"doctor".equalsIgnoreCase(usertype)) || !(session.getAttribute("uid") instanceof Integer)){response.sendError(403);return;}
response.setHeader("Cache-Control","no-store");
request.setCharacterEncoding("UTF-8");
boolean post="POST".equals(request.getMethod());
if(!post && !"GET".equals(request.getMethod())){response.sendError(405);return;}
String param=request.getParameter("visit_id");
if(!post && param==null){response.sendRedirect("my_guahao.jsp");return;}
int visitId;try{visitId=Integer.parseInt(param);if(visitId<=0)throw new NumberFormatException();}catch(NumberFormatException e){response.sendError(400);return;}
int uid=(Integer)session.getAttribute("uid"); VisitNote.Context visit;
try{
    if(post){
        String zd=request.getParameter("zhenduan"),ct=request.getParameter("content");
        if(zd==null||zd.trim().isEmpty()||zd.length()>200||ct==null||ct.trim().isEmpty()){response.sendError(400);return;}
        if(!VisitNote.save(a,visitId,uid,loginname,zd.trim(),ct.trim())){response.sendError(404);return;}
        Audit.log(loginname,"保存就诊病历","visit_id="+visitId);
        session.setAttribute("intakeFeedback","病历已保存，就诊 #"+visitId+"。");
        response.setStatus(303);response.setHeader("Location",response.encodeRedirectURL("my_guahao.jsp")+"#visit-"+visitId);return;
    }
    synchronized(Dbcoon.class){visit=VisitNote.context(a.getConnection(),visitId,uid,loginname,false);}
    if(visit==null){response.sendError(404);return;}
}catch(SQLException e){response.sendError(503);return;}
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>书写病历</title>
<style type="text/css">
.ai-btn{background:linear-gradient(135deg,#7c4dff,#5c6bc0);color:#fff;border:none;border-radius:5px;
  padding:5px 16px;font-size:13px;cursor:pointer;margin-left:8px;}
.ai-btn:hover{opacity:.9;}
.ai-btn:disabled{opacity:.5;cursor:not-allowed;}
.qc-btn{background:linear-gradient(135deg,#1976d2,#2196f3);color:#fff;border:none;border-radius:5px;
  padding:6px 22px;font-size:14px;cursor:pointer;}
.qc-btn:hover{opacity:.9;}
.tip{font-size:12px;color:#888;margin-left:6px;}
#aiStatus{font-size:12px;color:#7c4dff;margin-left:6px;}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">医生工作台 > 书写病历（医生：<%=WebUtil.htmlEscape(loginname)%>）</td></tr>
</table>
<form method="post" action="add_bingli.jsp" id="blForm" onsubmit="return false;">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<table width="70%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">当前就诊：</td>
<td><strong><%=WebUtil.htmlEscape(visit.name)%></strong> · <%=WebUtil.htmlEscape(visit.dept)%> · <%=WebUtil.htmlEscape(visit.day)%> · 就诊 #<%=visitId%>
<input type="hidden" name="visit_id" value="<%=visitId%>">
</td></tr>
<tr><td align="right" class="COLLECTION">病情简述：</td>
<td><input type="text" id="descInput" placeholder="仅填写本次就诊已获知的信息" style="width:240px"/>
<button type="button" class="ai-btn" id="draftBtn" onclick="aiDraft()">AI 生成草稿</button><span id="aiStatus"></span>
<div class="tip">AI 只生成草稿，最终内容由您审核修改后提交</div>
</td></tr>
<tr><td align="right" class="COLLECTION">诊断结果：</td>
<td><input type="text" name="zhenduan" id="zhenduan" style="width:240px"/></td></tr>
<tr><td align="right" class="COLLECTION">病历内容：</td>
<td><textarea name="content" id="content" rows="8" style="width:320px"></textarea></td></tr>
<tr><td colspan="2" align="center">
<button type="button" class="qc-btn" id="submitBtn" onclick="doSubmit()">AI 质控并保存病历</button>
</td></tr>
</table>
</form>
</td></tr></table>

<script type="text/javascript">
function aiDraft(){
  var desc=document.getElementById("descInput").value.trim();

  if(!desc){ alert("请先填写病情简述"); return; }
  if(document.getElementById("content").value.trim() && !confirm("替换当前病历正文草稿？"))return;
  var btn=document.getElementById("draftBtn"), st=document.getElementById("aiStatus");
  btn.disabled=true; st.textContent="正在生成草稿…";
  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"_csrf=<%=com.hospital.Csrf.token(session)%>&task=bingli_draft&desc="+encodeURIComponent(desc)
  }).then(function(r){return r.json();}).then(function(d){
    btn.disabled=false; st.textContent="";
    if(d.ok){
      // 诊断仅由医生填写。
      document.getElementById("content").value=d.data.content;
      st.textContent="仅整理已提供的信息；诊断须由医生填写";
    }else{
      st.textContent="";
      alert(d.error||"生成失败，请稍后重试");
    }
  }).catch(function(e){ btn.disabled=false; st.textContent=""; alert("网络异常，请稍后重试"); });
}

// 提交前 AI 质控：有警告时医生确认后仍可提交（提交权永远归医生）
function doSubmit(){


  var zd=document.getElementById("zhenduan").value.trim();
  var ct=document.getElementById("content").value.trim();
  if(!zd){ alert("请填写诊断结果"); return; }
  if(!ct){ alert("请填写病历内容"); return; }
  var btn=document.getElementById("submitBtn");
  btn.disabled=true; btn.textContent="AI 质控中…";

  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"_csrf=<%=com.hospital.Csrf.token(session)%>&task=bingli_qc&zhenduan="+encodeURIComponent(zd)
        +"&content="+encodeURIComponent(ct)
  }).then(function(r){return r.json();}).then(function(d){
    btn.disabled=false; btn.textContent="AI 质控并保存病历";
    if(!d.ok){ alert(d.error||"质控服务异常，请直接提交"); document.getElementById("blForm").submit(); return; }
    var ws=d.data.warnings||[];
    if(ws.length===0){ document.getElementById("blForm").submit(); return; }
    var ok=confirm("AI 质控发现以下 "+ws.length+" 条提醒：\n\n"+ws.map(function(w,i){return (i+1)+". "+w;}).join("\n")
      +"\n\n仍要保存提交吗？（提交权归医生，确认后提交）");
    if(ok) document.getElementById("blForm").submit();
  }).catch(function(e){
    btn.disabled=false; btn.textContent="AI 质控并保存病历";
    if(confirm("质控服务暂不可用，是否直接提交？")) document.getElementById("blForm").submit();
  });
}
</script>
</body>
</html>

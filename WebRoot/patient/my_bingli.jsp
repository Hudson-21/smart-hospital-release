<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%!
// 病历字段转成可安全嵌入 JS 字符串的形式（复用 WebUtil.jsEscape，含 </script> 逃逸防护）
String jsStr(String s){
    return com.hospital.WebUtil.jsEscape(s);
}
%>
<%
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;
// 参数化查询：杜绝拼接用户名的 SQL 注入
String sql = "SELECT * FROM bingli WHERE patientname=? ORDER BY id DESC";
// 单次查询：同时渲染表格行 + 收集 JS 数据供 AI 解读按钮传参
StringBuilder js = new StringBuilder();
StringBuilder rows = new StringBuilder();
boolean has=false;
int idx=0;
ResultSet rs = a.executeQuery(sql, myname);
while(rs.next()){
    has=true;
    if(idx>0) js.append(",");
    js.append("{id:").append(idx)
      .append(",kebie:\"").append(jsStr(rs.getString("kebie"))).append("\"")
      .append(",doctor:\"").append(jsStr(rs.getString("doctor"))).append("\"")
      .append(",zhenduan:\"").append(jsStr(rs.getString("zhenduan"))).append("\"")
      .append(",content:\"").append(jsStr(rs.getString("content"))).append("\"")
      .append(",riqi:\"").append(jsStr(rs.getString("riqi"))).append("\"}");
    rows.append("<tr class=\"even\">")
        .append("<td align=\"center\">").append(com.hospital.WebUtil.htmlEscape(rs.getString("kebie"))).append("</td>")
        .append("<td align=\"center\">").append(com.hospital.WebUtil.htmlEscape(rs.getString("doctor"))).append("</td>")
        .append("<td align=\"center\">").append(com.hospital.WebUtil.htmlEscape(rs.getString("zhenduan"))).append("</td>")
        .append("<td align=\"left\" class=\"padl5\">").append(com.hospital.WebUtil.htmlEscape(rs.getString("content"))).append("</td>")
        .append("<td align=\"center\">").append(com.hospital.WebUtil.htmlEscape(rs.getString("riqi"))).append("</td>")
        .append("<td align=\"center\"><button class=\"exp-btn\" id=\"btn_").append(idx).append("\" onclick=\"explain(").append(idx).append(")\">AI 解读</button></td>")
        .append("</tr>");
    idx++;
}
a.close();
if(!has) rows.append("<tr><td colspan=\"6\" align=\"center\" class=\"even\">暂无病历记录</td></tr>");
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>我的病历</title>
<style type="text/css">
.exp-btn{background:linear-gradient(135deg,#00897b,#26a69a);color:#fff;border:none;border-radius:4px;
  padding:4px 12px;font-size:12px;cursor:pointer;white-space:nowrap;}
.exp-btn:hover{opacity:.85;}
/* 解读弹层 */
#mask{display:none;position:fixed;left:0;top:0;width:100%;height:100%;background:rgba(0,0,0,.45);z-index:99;}
#dlg{display:none;position:fixed;left:50%;top:50%;transform:translate(-50%,-50%);
  width:520px;max-width:92%;max-height:82%;overflow-y:auto;background:#fff;border-radius:10px;
  box-shadow:0 8px 30px rgba(0,0,0,.25);z-index:100;padding:0;}
#dlg h3{margin:0;padding:14px 18px;font-size:16px;color:#fff;background:linear-gradient(135deg,#00897b,#26a69a);
  border-radius:10px 10px 0 0;position:relative;}
#dlgClose{position:absolute;right:12px;top:10px;color:#fff;font-size:18px;cursor:pointer;background:none;border:none;}
.exp-body{padding:16px 18px;}
.exp-item{margin-bottom:12px;}
.exp-item .t{font-size:13px;color:#00796b;font-weight:bold;margin-bottom:3px;}
.exp-item .c{font-size:14px;color:#333;line-height:1.65;white-space:pre-wrap;background:#f4fbfa;
  border-left:3px solid #26a69a;padding:8px 10px;border-radius:0 6px 6px 0;}
.exp-foot{font-size:12px;color:#999;padding:0 18px 14px;line-height:1.6;}
.exp-loading{text-align:center;color:#26a69a;font-size:14px;padding:40px 0;}
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
<td width="98%" align="left" class="lan13b">个人中心 > 我的病历（就诊人：<%=myname%>）</td></tr>
</table>
<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
<tr>
<th width="10%" nowrap class="COLLECTION">科别</th>
<th width="11%" nowrap class="COLLECTION">主治医生</th>
<th width="13%" nowrap class="COLLECTION">诊断</th>
<th width="38%" nowrap class="COLLECTION">病历内容</th>
<th width="10%" nowrap class="COLLECTION">日期</th>
<th width="10%" nowrap class="COLLECTION">操作</th>
</tr>
<%=rows.toString()%>
</table>
</td></tr></table>

<!-- AI 通俗解读弹层 -->
<div id="mask" onclick="closeDlg()"></div>
<div id="dlg">
  <h3>病历大白话解读<button id="dlgClose" onclick="closeDlg()">×</button></h3>
  <div class="exp-body" id="dlgBody"></div>
  <div class="exp-foot">以上解读由 AI 生成，仅供科普参考，一切以主治医生的当面解释和医嘱为准。<br>如有疑问，请携带病历咨询您的主治医生。</div>
</div>

<script type="text/javascript">
var bls=[<%=js.toString()%>];
var myNameJ="<%=jsStr(myname)%>";

function explain(i){
  var b=bls[i]; if(!b) return;
  var mask=document.getElementById("mask"), dlg=document.getElementById("dlg"), body=document.getElementById("dlgBody");
  mask.style.display="block"; dlg.style.display="block";
  body.innerHTML='<div class="exp-loading">AI 正在解读您的病历，请稍候…</div>';
  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"task=bingli_explain&patient="+encodeURIComponent(myNameJ)
        +"&kebie="+encodeURIComponent(b.kebie)
        +"&doctor="+encodeURIComponent(b.doctor)
        +"&zhenduan="+encodeURIComponent(b.zhenduan)
        +"&content="+encodeURIComponent(b.content)
        +"&riqi="+encodeURIComponent(b.riqi)
  }).then(function(r){return r.json();}).then(function(d){
    if(d.ok){
      var x=d.data;
      body.innerHTML=
        '<div class="exp-item"><div class="t">❓ 这是什么病</div><div class="c">'+x.what+'</div></div>'+
        '<div class="exp-item"><div class="t">🏥 医生做了什么处理</div><div class="c">'+x.treat+'</div></div>'+
        '<div class="exp-item"><div class="t">🏠 回家注意什么</div><div class="c">'+x.care+'</div></div>'+
        '<div class="exp-item"><div class="t">⚠️ 什么情况要立即复诊</div><div class="c">'+x.warning+'</div></div>';
    }else{
      body.innerHTML='<div class="exp-loading">'+(d.error||"解读失败，请稍后重试")+'</div>';
    }
  }).catch(function(e){
    body.innerHTML='<div class="exp-loading">网络异常，请稍后重试</div>';
  });
}

function closeDlg(){
  document.getElementById("mask").style.display="none";
  document.getElementById("dlg").style.display="none";
}
</script>
</body>
</html>

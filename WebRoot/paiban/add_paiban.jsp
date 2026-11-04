<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可新增排班');history.back();</script>"); return;
}

// 读医生字典，供下拉
ResultSet rdr = a.executeQuery("SELECT name,kebie,number FROM doctor ORDER BY kebie,name");
StringBuilder doc = new StringBuilder();
while(rdr.next()){
    doc.append("['").append(rdr.getString("name")==null?"":rdr.getString("name").replace("'","").replace("\\","\\\\"))
        .append("','").append(rdr.getString("kebie")==null?"":rdr.getString("kebie").replace("'",""))
        .append("','").append(rdr.getString("number")==null?"":rdr.getString("number").replace("'",""))
        .append("'],");
}
if(doc.length()>0) doc.setLength(doc.length()-1);
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>新增排班</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">排班管理 > 新增排班</td></tr>
</table>
<form method="post" action="save_paiban.jsp" name="addForm" onsubmit="return check();">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">医生姓名：</td>
<td><select name="doctor_name" id="doctor_name" style="width:220px" onchange="fillKb()">
<option value="">--请选择医生--</option>
</select></td></tr>
<tr><td align="right" class="COLLECTION">工号：</td>
<td><input type="text" name="doctor_code" id="doctor_code" style="width:220px" readonly/></td></tr>
<tr><td align="right" class="COLLECTION">科室：</td>
<td><input type="text" name="kebie" id="kebie" style="width:220px" readonly/></td></tr>
<tr><td align="right" class="COLLECTION">出诊日期：</td>
<td><input type="date" name="work_date" id="work_date" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">时段：</td>
<td><select name="shift" id="shift" style="width:220px">
<option value="上午">上午</option>
<option value="下午">下午</option>
</select></td></tr>
<tr><td align="right" class="COLLECTION">总号源：</td>
<td><input type="number" name="total" id="total" min="1" max="500" value="20" style="width:220px"/></td></tr>
<tr><td colspan="2" align="center">
<input type="submit" value="保存" style="width:120px;height:28px"/>
<input type="button" value="返回" onclick="history.go(-1)" style="width:120px;height:28px"/>
</td></tr>
</table>
</form>
</td></tr></table>
<script type="text/javascript">
var docs = [<%=doc.toString()%>];
var sel=document.getElementById("doctor_name");
docs.forEach(function(d){
  var o=document.createElement("option");
  o.value=d[0]; o.text=d[0]+"（"+d[1]+"）"; o.setAttribute("data-kb",d[1]); o.setAttribute("data-code",d[2]);
  sel.appendChild(o);
});
function fillKb(){
  var o=sel.options[sel.selectedIndex];
  document.getElementById("kebie").value = o?o.getAttribute("data-kb")||"": "";
  document.getElementById("doctor_code").value = o?o.getAttribute("data-code")||"": "";
}
function check(){
  if(!sel.value){ alert("请选择医生"); return false; }
  var wd=document.getElementById("work_date").value;
  if(!wd){ alert("请选择出诊日期"); return false; }
  var t=parseInt(document.getElementById("total").value);
  if(!(t>0)){ alert("总号源必须为正整数"); return false; }
  return true;
}
</script>
</body>
</html>
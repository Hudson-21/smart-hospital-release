<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可新增药品');history.back();</script>"); return;
}
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>新增药品</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">药品库存 > 新增药品</td></tr>
</table>
<form method="post" action="save_yaoku.jsp" name="addForm" onsubmit="return check();">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">药品编码：</td>
<td><input type="text" name="code" maxlength="20" style="width:220px" value="YP<%=System.currentTimeMillis()%1000%>"/></td></tr>
<tr><td align="right" class="COLLECTION">药品名称：</td>
<td><input type="text" name="name" maxlength="100" style="width:220px"/><font color="red">*</font></td></tr>
<tr><td align="right" class="COLLECTION">规格：</td>
<td><input type="text" name="spec" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">单位：</td>
<td><input type="text" name="unit" maxlength="20" style="width:220px" value="盒"/></td></tr>
<tr><td align="right" class="COLLECTION">单价（元）：</td>
<td><input type="number" name="price" min="0" step="0.01" style="width:220px" value="0"/></td></tr>
<tr><td align="right" class="COLLECTION">初始库存：</td>
<td><input type="number" name="stock" min="0" style="width:220px" value="100"/></td></tr>
<tr><td align="right" class="COLLECTION">分类：</td>
<td><select name="category" style="width:220px">
<option value="抗生素">抗生素</option>
<option value="解热镇痛">解热镇痛</option>
<option value="心血管">心血管</option>
<option value="止咳化痰">止咳化痰</option>
<option value="消化系统">消化系统</option>
<option value="输液">输液</option>
<option value="其他">其他</option>
</select></td></tr>
<tr><td colspan="2" align="center">
<input type="submit" value="保存" style="width:120px;height:28px"/>
<input type="button" value="返回" onclick="history.go(-1)" style="width:120px;height:28px"/>
</td></tr>
</table>
</form>
</td></tr></table>
<script type="text/javascript">
function check(){
  if(!document.addForm.name.value.trim()){ alert("请填写药品名称"); return false; }
  return true;
}
</script>
</body>
</html>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path;
String applicationPath = basePath + "/" + "application";
String username = (String)request.getSession().getAttribute("loginname");
String usertype = (String)request.getSession().getAttribute("usertype");
// 把英文角色名映射为中文显示
String displayType = usertype;
if ("admin".equalsIgnoreCase(usertype)) displayType = "管理员";
else if ("doctor".equalsIgnoreCase(usertype)) displayType = "医生";
else if ("patient".equalsIgnoreCase(usertype)) displayType = "病人";
if (displayType == null) displayType = "";
%>
<html>
<head>
<title>顶部页面</title>
<link href="images/css1/top_css.css" rel="stylesheet" type="text/css">
</head>
<body bgcolor="#03A8F6">
<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td width="194" height="60" align="center" background="images/top_logo.jpg"></td>
    <td align="center" style="background:url(images/top_bg.jpg) no-repeat"><table cellspacing="0" cellpadding="0" border="0" width="100%" height="33">
      <tbody>
        <tr>
          <td width="30" align="left"> </td>
          <td width="420" align="left">
		      <span class="top_link"> </span> <a class="top_link" href="#" >当前用户：<%=username%>&nbsp;|&nbsp;角色：<%=displayType%></a> </td>
          <td width="80" align="right" nowrap="nowrap" class="topbar"> </td>
          <td class="topbar">&nbsp;</td>
        </tr>
      </tbody>
    </table>
    <table height="26" border="0" align="left" cellpadding="0" cellspacing="0" class="subbg" NAME=t1>
      <tbody>

      </tbody>
    </table></td>
  </tr>
  <tr height="6">
    <td bgcolor="#1F3A65" background="images/top_bg.jpg"></td>
  </tr>
</table>
<script language="javascript">

</script></body>
</html>

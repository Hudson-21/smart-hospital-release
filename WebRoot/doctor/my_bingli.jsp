<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;
// 参数化查询：杜绝拼接用户名的 SQL 注入
String sql = "SELECT * FROM bingli WHERE doctor=? ORDER BY id DESC";
ResultSet rs = a.executeQuery(sql, myname);
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>我的病历</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">医生工作台 > 我的病历（医生：<%=myname%>）　<a href="add_bingli.jsp" target="main">[书写新病历]</a></td></tr>
</table>
<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
<tr>
<th width="10%" nowrap class="COLLECTION">病人</th>
<th width="10%" nowrap class="COLLECTION">科别</th>
<th width="12%" nowrap class="COLLECTION">诊断</th>
<th width="48%" nowrap class="COLLECTION">病历内容</th>
<th width="12%" nowrap class="COLLECTION">日期</th>
</tr>
<%
boolean has=false;
while(rs.next()){
  has=true;
%>
<tr class="even">
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("patientname")==null?"":rs.getString("patientname"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("zhenduan")==null?"":rs.getString("zhenduan"))%></td>
<td align="left" class="padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("content")==null?"":rs.getString("content"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi")==null?"":rs.getString("riqi"))%></td>
</tr>
<%
}
if(!has){ %><tr><td colspan="5" align="center" class="even">暂无病历记录</td></tr><% }
%>
</table>
</td></tr></table>
</body>
</html>

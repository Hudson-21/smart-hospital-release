<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path;
String applicationPath = basePath + "/" + "application";
%>
<%@ page import="java.sql.*"%>
<%@ page language="java"%>
<%@ page import="java.util.*"%>
<%@ page import="com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
// 登录校验
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;
%>
<html>
	<head>
		<link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
		<title>我的档案</title>
	
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
	<body class="h-business" bgcolor="#ffffff"><br>
<%
	String sql = "SELECT * FROM doctor WHERE name=?";
	ResultSet rs = a.executeQuery(sql, myname);
	if(rs.next()){
%>
	<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
	  <tr>
		<td valign="top" align="left" class="pad5">
			<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
	          <tr>
	            <td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
	            <td width="98%" align="left" class="lan13b">医生工作台 > 我的档案</td>
	          </tr>
	        </table>
			<table width="100%" border="0" cellpadding="1" cellspacing="1" class="table-border margb5">
				<tr>
					<td width="14%" align="right" class="COLLECTION">编号：</td>
					<td width="36%" align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">姓名：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">性别：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("sex")==null?"":rs.getString("sex"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">职称：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("zhicheng")==null?"":rs.getString("zhicheng"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">职务：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("zhiwu")==null?"":rs.getString("zhiwu"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">科别：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">出生日期：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("birthtime")==null?"":rs.getString("birthtime"))%></td>
				</tr>
				<tr>
					<td align="right" class="COLLECTION">工作日期：</td>
					<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("worktime")==null?"":rs.getString("worktime"))%></td>
				</tr>
			</table>
<% } else { %>
			<p align="center">未查询到您的档案信息，请联系管理员维护。</p>
<% } %>
		</td>
	  </tr>
	</table>
	</body>
</html>

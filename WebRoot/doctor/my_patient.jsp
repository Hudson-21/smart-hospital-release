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
// 登录校验 + 数据隔离：只看自己负责的病人的数据
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;

String sql = "SELECT * FROM patient WHERE doctor=?";
ResultSet rs = a.executeQuery(sql, myname);
%>
<html>
	<head>
		<link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
		<title>我的病人</title>
	
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
	<body class="h-business" bgcolor="#ffffff"><br>
		<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
			<tr>
				<td valign="top" align="left" class="pad5">
					<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
						<tr>
							<td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
							<td width="98%" align="left" class="lan13b">医生工作台 > 我的病人（主治医生：<%=myname%>）</td>
						</tr>
					</table>
					<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
						<tr>
							<td colspan="10" align="left" class="tabbg">
								<img src="<%=path%>/images/main_pic_1.gif" align="absmiddle" width="16" height="16">
								&nbsp;<span class="lan13b"></span>
							</td>
						</tr>
						<tr>
							<th width="3%" nowrap class="COLLECTION">科别</th>
							<th width="3%" nowrap class="COLLECTION">病床号</th>
							<th width="3%" nowrap class="COLLECTION">病人姓名</th>
							<th width="5%" nowrap class="COLLECTION">性别</th>
							<th width="5%" nowrap class="COLLECTION">年龄</th>
							<th width="5%" nowrap class="COLLECTION">病症</th>
							<th width="5%" nowrap class="COLLECTION">主治医生</th>
							<th width="5%" nowrap class="COLLECTION">入院日期</th>
							<th width="5%" nowrap class="COLLECTION">出院日期</th>
							<th width="7%" nowrap class="COLLECTION">管理</th>
						</tr>
<%
	boolean has = false;
	while(rs.next()){
		has = true;
		int id = rs.getInt("id");
%>
						<tr class="even">
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("sex")==null?"":rs.getString("sex"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("age")==null?"":rs.getString("age"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("bingzheng")==null?"":rs.getString("bingzheng"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("doctor")==null?"":rs.getString("doctor"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("ruyuan")==null?"":rs.getString("ruyuan"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("chuyuan")==null?"":rs.getString("chuyuan"))%></td>
							<td nowrap align="center"><a href="my_patient_edit.jsp?id=<%=id%>">修改</a></td>
						</tr>
<%
	}
	if(!has){
%>
						<tr><td colspan="10" align="center" class="even">暂无您负责的病人</td></tr>
<%
	}
%>
					</table>
				</td>
			</tr>
		</table>
	</body>
</html>

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
// 登录校验 + 数据隔离：只看到自己负责病人的费用
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;

String sql = "SELECT * FROM cost WHERE name IN (SELECT name FROM patient WHERE doctor=?)";
ResultSet rs = a.executeQuery(sql, myname);
%>
<html>
	<head>
		<link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
		<title>我的病人费用</title>
	
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
							<td width="98%" align="left" class="lan13b">医生工作台 > 我的病人费用</td>
						</tr>
					</table>
					<table border="0" cellspacing="0" cellpadding="0" class="margb5">
						<tr>
							<td width="61" align="left" class="padr5">
								<input type="image" src="<%=path%>/images/pic-13.jpg" onClick="window.location.href='../cost/addcost.jsp'">
							</td>
						</tr>
					</table>
					<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
						<tr>
							<td colspan="9" align="left" class="tabbg">
								<img src="<%=path%>/images/main_pic_1.gif" align="absmiddle" width="16" height="16">
								&nbsp;<span class="lan13b"></span>
							</td>
						</tr>
						<tr>
							<th width="3%" nowrap class="COLLECTION">科别</th>
							<th width="3%" nowrap class="COLLECTION">病床号</th>
							<th width="3%" nowrap class="COLLECTION">病人姓名</th>
							<th width="5%" nowrap class="COLLECTION">收费项目</th>
							<th width="5%" nowrap class="COLLECTION">单价</th>
							<th width="5%" nowrap class="COLLECTION">数量</th>
							<th width="5%" nowrap class="COLLECTION">金额</th>
							<th width="5%" nowrap class="COLLECTION">日期</th>
						</tr>
<%
	boolean has = false;
	while(rs.next()){
		has = true;
%>
						<tr class="even">
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("xiangmu")==null?"":rs.getString("xiangmu"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("danjia")==null?"":rs.getString("danjia"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("shuliang")==null?"":rs.getString("shuliang"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("jine")==null?"":rs.getString("jine"))%></td>
							<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi")==null?"":rs.getString("riqi"))%></td>
						</tr>
<%
	}
	if(!has){
%>
						<tr><td colspan="9" align="center" class="even">暂无费用记录</td></tr>
<%
	}
%>
					</table>
				</td>
			</tr>
		</table>
	</body>
</html>

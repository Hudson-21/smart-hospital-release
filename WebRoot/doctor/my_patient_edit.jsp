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

String method = request.getMethod();
if("POST".equalsIgnoreCase(method)){
	// 保存：只允许修改本人负责的病人（WHERE id=? AND doctor=? 双重约束）
	String id = request.getParameter("id");
	int pid = 0;
	try{ pid = Integer.parseInt(id); }catch(Exception ignore){}
	String bingzheng = DataFormat.convert(request.getParameter("bingzheng"));
	String ruyuan = DataFormat.convert(request.getParameter("ruyuan"));
	String chuyuan = DataFormat.convert(request.getParameter("chuyuan"));
	a.executeUpdate("UPDATE patient SET bingzheng=?, ruyuan=?, chuyuan=? WHERE id=? AND doctor=?",
			bingzheng, ruyuan, chuyuan, pid, myname);
	response.sendRedirect("my_patient.jsp");
	return;
}

// GET：显示表单，并校验归属
int pid = 0;
try{ pid = Integer.parseInt(request.getParameter("id")); }catch(Exception ignore){}
ResultSet rs = a.executeQuery("SELECT * FROM patient WHERE id=? AND doctor=?", pid, myname);
if(!rs.next()){
%>
<html><body class="h-business" bgcolor="#ffffff"><br><p align="center" style="color:red">无权限访问该病人信息或记录不存在。<a href="my_patient.jsp">返回我的病人</a></p></body></html>
<%
	return;
}
%>
<html>
	<head>
		<link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
		<script type="text/javascript" src="<%=path%>/calendar/WdatePicker.js"></script>
		<title>修改病人信息</title>
	
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
	<body class="h-business" bgcolor="#ffffff"><br>
		<form action="my_patient_edit.jsp" method="post" name="editForm">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
			<input type="hidden" name="id" value="<%=pid%>">
			<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
				<tr>
					<td valign="top" align="left" class="pad5">
						<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
							<tr>
								<td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
								<td width="98%" align="left" class="lan13b">医生工作台 > 修改病人信息（<%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%>）</td>
							</tr>
						</table>
						<table width="100%" border="0" cellpadding="1" cellspacing="1" class="table-border margb5">
							<tr>
								<td width="14%" align="right" class="COLLECTION">科别：</td>
								<td width="36%" align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
							</tr>
							<tr>
								<td align="right" class="COLLECTION">病床号：</td>
								<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
							</tr>
							<tr>
								<td align="right" class="COLLECTION">病人姓名：</td>
								<td align="left" class="even padl5"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
							</tr>
							<tr>
								<td align="right" class="COLLECTION">病症：</td>
								<td align="left" class="even padl5">
									<input type="text" name="bingzheng" class="inputnormal" maxlength="200" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("bingzheng")==null?"":rs.getString("bingzheng"))%>">
								</td>
							</tr>
							<tr>
								<td align="right" class="COLLECTION">入院日期：</td>
								<td align="left" class="even padl5">
									<input class="Wdate" type="text" name="ruyuan" maxlength="32" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("ruyuan")==null?"":rs.getString("ruyuan"))%>" onfocus="WdatePicker({readOnly:true})" />
								</td>
							</tr>
							<tr>
								<td align="right" class="COLLECTION">出院日期：</td>
								<td align="left" class="even padl5">
									<input class="Wdate" type="text" name="chuyuan" maxlength="32" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("chuyuan")==null?"":rs.getString("chuyuan"))%>" onfocus="WdatePicker({readOnly:true})" />
								</td>
							</tr>
						</table>
						<table width="100%" border="0" cellspacing="0" cellpadding="0">
							<tr>
								<td width="50%" align="right" class="padr5">
									<input type="submit" name="button" value="保 存" class="button">
								</td>
								<td width="50%" align="left" class="padl5">
									<input name="button1" type="button" class="button" onClick="history.go(-1);" value="返 回">
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>
		</form>
	</body>
</html>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}

// 管理员删除挂号
String del = request.getParameter("del");
if(del!=null && !"".equals(del)){
    int did = 0;
    try{ did = Integer.parseInt(del); }catch(Exception ignore){}
    a.executeUpdate("DELETE FROM guahao WHERE id=?", did);
    response.sendRedirect("list_guahao.jsp");
    return;
}
ResultSet rs = a.executeQuery("SELECT * FROM guahao ORDER BY id DESC");
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>挂号管理</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">系统管理 > 挂号管理</td></tr>
</table>
<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
<tr>
<th width="12%" nowrap class="COLLECTION">挂号单号</th>
<th width="10%" nowrap class="COLLECTION">病人</th>
<th width="10%" nowrap class="COLLECTION">科室</th>
<th width="10%" nowrap class="COLLECTION">接诊医生</th>
<th width="12%" nowrap class="COLLECTION">就诊日期</th>
<th width="10%" nowrap class="COLLECTION">状态</th>
<th width="12%" nowrap class="COLLECTION">联系电话</th>
<th width="14%" nowrap class="COLLECTION">备注</th>
<th width="8%" nowrap class="COLLECTION">操作</th>
</tr>
<%
boolean has=false;
while(rs.next()){
  has=true;
  int id = rs.getInt("id");
%>
<tr class="even">
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie")==null?"":rs.getString("kebie"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("doctor")==null?"":rs.getString("doctor"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi")==null?"":rs.getString("riqi"))%></td>
<td align="center"><% if("已接诊".equals(rs.getString("state"))){ %><span style="color:green">已接诊</span><% } else { %><span style="color:red">待接诊</span><% } %></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("phone")==null?"":rs.getString("phone"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("beizhu")==null?"":rs.getString("beizhu"))%></td>
<td align="center"><a href="list_guahao.jsp?del=<%=id%>" onclick="return confirm('确认删除该挂号记录？')">删除</a></td>
</tr>
<%
}
if(!has){ %><tr><td colspan="9" align="center" class="even">暂无挂号记录</td></tr><% }
%>
</table>
</td></tr></table>
</body>
</html>

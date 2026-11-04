<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;

// 接诊操作：仅允许接诊"分配给本人"的挂号单
String act = request.getParameter("act");
if("jiezhen".equals(act)){
    String id = request.getParameter("id");
    if(id!=null && !"".equals(id)){
        a.executeUpdate("UPDATE guahao SET state='已接诊' WHERE id=? AND doctor=?",
                Integer.parseInt(id), myname);
        com.hospital.Audit.log(myname, "接诊挂号", "挂号单 id=" + id);
        response.sendRedirect("my_guahao.jsp");
        return;
    }
}
ResultSet rs = a.executeQuery("SELECT * FROM guahao WHERE doctor=? ORDER BY id DESC", myname);
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>我的接诊</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">医生工作台 > 我的接诊（医生：<%=myname%>）</td></tr>
</table>
<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
<tr>
<th width="14%" nowrap class="COLLECTION">挂号单号</th>
<th width="12%" nowrap class="COLLECTION">病人</th>
<th width="14%" nowrap class="COLLECTION">就诊日期</th>
<th width="14%" nowrap class="COLLECTION">联系电话</th>
<th width="12%" nowrap class="COLLECTION">状态</th>
<th width="16%" nowrap class="COLLECTION">备注</th>
<th width="10%" nowrap class="COLLECTION">操作</th>
</tr>
<%
boolean has=false;
while(rs.next()){
  has=true;
  int id = rs.getInt("id");
  String st = rs.getString("state");
%>
<tr class="even">
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi")==null?"":rs.getString("riqi"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("phone")==null?"":rs.getString("phone"))%></td>
<td align="center"><% if("已接诊".equals(st)){ %><span style="color:green">已接诊</span><% } else { %><span style="color:red">待接诊</span><% } %></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("beizhu")==null?"":rs.getString("beizhu"))%></td>
<td align="center"><% if(!"已接诊".equals(st)){ %><a href="my_guahao.jsp?act=jiezhen&id=<%=id%>" onclick="return confirm('确认接诊该病人？')">接诊</a><% } else { %>—<% } %></td>
</tr>
<%
}
if(!has){ %><tr><td colspan="7" align="center" class="even">暂无分配给您的挂号</td></tr><% }
%>
</table>
</td></tr></table>
</body>
</html>

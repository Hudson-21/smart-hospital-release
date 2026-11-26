<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"医生".equals(usertype) && !"doctor".equalsIgnoreCase(usertype)){response.sendError(403);return;}
String myname = loginname;
String act = request.getParameter("act");
if("POST".equals(request.getMethod())){
    if(!"jiezhen".equals(act)){response.sendError(400);return;}
    int id;
    try { id = Integer.parseInt(request.getParameter("id")); }
    catch(NumberFormatException ex){response.sendError(400);return;}
    if(id<=0){response.sendError(400);return;}
    int changed;
    try {
        synchronized(Dbcoon.class){
            Connection conn = a.getConnection();
            if(conn==null) throw new SQLException("Intake connection unavailable");
            try (PreparedStatement stmt = conn.prepareStatement(
                    "UPDATE guahao SET state='已接诊' WHERE id=? AND doctor=? AND state='待接诊'")) {
                stmt.setInt(1, id);
                stmt.setString(2, myname);
                changed = stmt.executeUpdate();
            }
        }
    } catch(SQLException ex) {
        application.log("接诊写入未完成（SQLState=" + ex.getSQLState() + "）");
        response.sendError(503);
        return;
    }
    if(changed==1){
        Audit.log(myname, "接诊挂号", "挂号单 id=" + id);
        session.setAttribute("intakeFeedback", "接诊成功。");
    } else {
        session.setAttribute("intakeFeedback", "未完成接诊：记录已处理、已不存在或未分配给您。");
    }
    response.setStatus(303);
    response.setHeader("Location", response.encodeRedirectURL("my_guahao.jsp"));
    return;
}
if(!"GET".equals(request.getMethod()) || act!=null){
    response.setHeader("Allow", "GET, POST"); response.sendError(405); return;
}
String feedback = (String)session.getAttribute("intakeFeedback");
if(feedback!=null) session.removeAttribute("intakeFeedback");
ResultSet rs = a.executeQuery("SELECT * FROM guahao WHERE doctor=? ORDER BY id DESC", myname);
if(rs==null){response.sendError(500);return;}
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>我的接诊</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<% if(feedback!=null){ %><p align="center" role="status"><%=WebUtil.htmlEscape(feedback)%></p><% } %>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">医生工作台 > 我的接诊（医生：<%=WebUtil.htmlEscape(myname)%>）</td></tr>
</table>
<table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
<tr>
<th width="14%" nowrap class="COLLECTION">挂号单号</th>
<th width="12%" nowrap class="COLLECTION">病人</th>
<th width="14%" nowrap class="COLLECTION">就诊日期</th>
<th nowrap class="COLLECTION">时段</th>
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
<tr class="even" id="visit-<%=id%>">
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number")==null?"":rs.getString("number"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name")==null?"":rs.getString("name"))%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi")==null?"":rs.getString("riqi"))%></td>
<td align="center"><% String shift=rs.getString("booking_shift"); %><%=shift==null||shift.isEmpty()?"时段未记录":WebUtil.htmlEscape(shift)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("phone")==null?"":rs.getString("phone"))%></td>
<td align="center"><span style="color:<%="已接诊".equals(st)?"green":"#b42318"%>"><%=WebUtil.htmlEscape(st)%></span></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("beizhu")==null?"":rs.getString("beizhu"))%></td>
<td align="center"><% if("待接诊".equals(st)){ %>
<form action="my_guahao.jsp" method="post" style="margin:0" onsubmit="return confirm('确认接诊该病人？')">
<input type="hidden" name="_csrf" value="<%=Csrf.token(session)%>">
<input type="hidden" name="act" value="jiezhen">
<input type="hidden" name="id" value="<%=id%>">
<button type="submit">接诊</button>
</form>
<% } else if("已接诊".equals(st) && rs.getObject("patient_account_id")!=null){ %><a href="add_bingli.jsp?visit_id=<%=id%>">写病历</a><% } else { %>身份未绑定，需核对<% } %></td>
</tr>
<%
}
rs.close();
if(!has){ %><tr><td colspan="8" align="center" class="even">暂无分配给您的挂号</td></tr><% }
%>
</table>
</td></tr></table>
</body>
</html>

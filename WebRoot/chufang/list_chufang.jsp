<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype) && !"医生".equals(usertype)){
    out.print("<script>alert('仅管理员/医生可查看处方');history.back();</script>"); return;
}

String where = "WHERE 1=1";
java.util.List<Object> params = new java.util.ArrayList<Object>();
// 医生只看自己开的方
if("医生".equals(usertype)){ where += " AND doctor=?"; params.add(loginname); }

ResultSet rs = a.executeQuery("SELECT id,cf_number,patient_name,doctor,kebie,zongjia,state,ctime,beizhu FROM chufang "+where+" ORDER BY id DESC", params.toArray());
int cnt = 0;
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>处方列表</title>
<style type="text/css">
  .opbtn { border:none; border-radius:4px; padding:3px 14px; font-size:12px; cursor:pointer;
           font-family:inherit; color:#fff; }
  .opbtn.dispense { background:#27ae60; }
  .opbtn.refund   { background:#e67e22; }
  .opbtn:hover { opacity:.85; }
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b"><%="医生".equals(usertype)?"医生工作台 > 我的处方 > ":""%>处方管理 > 处方列表</td></tr>
</table>

<table width="100%" border="0" cellpadding="2" cellspacing="1" class="table-border margb5">
<tr style="background:#d0e6ff;">
<th>处方号</th><th>病人</th><th>科室</th><th>开方医生</th><th>金额</th><th>状态</th><th>时间</th><th>备注</th><th>明细</th><th>操作</th>
</tr>
<%
while(rs.next()){
    String cf=rs.getString("cf_number"), pn=rs.getString("patient_name"),
           kb=rs.getString("kebie")==null?"":rs.getString("kebie"),
           doc=rs.getString("doctor")==null?"":rs.getString("doctor"),
           st=rs.getString("state")==null?"":rs.getString("state"),
           ct=rs.getString("ctime")==null?"":rs.getString("ctime"),
           bz=rs.getString("beizhu")==null?"":rs.getString("beizhu");
    double zj=rs.getDouble("zongjia");
    cnt++;
    String stateColor = "待发药".equals(st)?"#f39c12"
                      :("已发药".equals(st)?"#27ae60"
                      :("已退药".equals(st)?"#95a5a6":"#7f8c8d"));
%>
<tr>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(cf)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(pn)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(kb)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(doc)%></td>
<td align="center">¥<%=String.format("%.2f",zj)%></td>
<td align="center"><span style="color:<%=stateColor%>;font-weight:bold;"><%=com.hospital.WebUtil.htmlEscape(st)%></span></td>
<td align="center" style="font-size:12px;"><%=com.hospital.WebUtil.htmlEscape(ct)%></td>
<td align="center" style="font-size:12px;"><%=com.hospital.WebUtil.htmlEscape(bz)%></td>
<td align="center"><a href="view_chufang.jsp?cf=<%=com.hospital.WebUtil.htmlEscape(cf)%>">查看</a></td>
<td align="center">
<%
    if("待发药".equals(st)){
%>
  <form action="dispense_chufang.jsp" method="post" style="display:inline;margin:0"
        onsubmit="return confirm('确认对该处方发药？');">
    <input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
    <input type="hidden" name="cf" value="<%=com.hospital.WebUtil.htmlEscape(cf)%>">
    <input type="hidden" name="act" value="dispense">
    <button type="submit" class="opbtn dispense">发药</button>
  </form>
<%
    } else if("已发药".equals(st)){
%>
  <form action="dispense_chufang.jsp" method="post" style="display:inline;margin:0"
        onsubmit="return confirm('确认退药？该处方药品库存将自动加回。');">
    <input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
    <input type="hidden" name="cf" value="<%=com.hospital.WebUtil.htmlEscape(cf)%>">
    <input type="hidden" name="act" value="return">
    <button type="submit" class="opbtn refund">退药</button>
  </form>
<%
    } else {
%>
  <span style="color:#b0bec5;font-size:12px;">—</span>
<%
    }
%>
</td>
</tr>
<%
}
a.close();
%>
</table>
<p style="font-size:12px;color:#888;margin-left:6px;">共 <%=cnt%> 张处方</p>
</td></tr></table>
</body>
</html>
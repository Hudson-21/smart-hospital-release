<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
// 登录 + 角色校验：管理员/医生可看排班
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype) && !"医生".equals(usertype)){
    out.print("<script>alert('仅管理员/医生可查看排班');history.back();</script>"); return;
}

// 关键词搜索
String kw_kebie = request.getParameter("kebie");
String kw_doctor= request.getParameter("doctor");
String kw_date  = request.getParameter("date");

StringBuilder where = new StringBuilder("WHERE 1=1");
List<Object> params = new ArrayList<Object>();
if(kw_kebie!=null && !"".equals(kw_kebie.trim())){ where.append(" AND kebie=?"); params.add(kw_kebie.trim()); }
if(kw_doctor!=null && !"".equals(kw_doctor.trim())){ where.append(" AND doctor_name LIKE ?"); params.add("%"+kw_doctor.trim()+"%"); }
if(kw_date!=null && !"".equals(kw_date.trim())){ where.append(" AND work_date=?"); params.add(java.sql.Date.valueOf(kw_date.trim())); }

String sql = "SELECT id,doctor_code,doctor_name,kebie,work_date,shift,total,remain FROM paiban " + where + " ORDER BY work_date,doctor_name,shift";
ResultSet rs = a.executeQuery(sql, params.toArray());
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>排班查询</title>
<style>.kwsel{font-size:13px;padding:2px 4px;margin-right:6px;}</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">排班管理 > 排班查询（当前账号：<%=loginname%>）</td></tr>
</table>

<form method="get" action="list_paiban.jsp" style="margin:0 0 10px 0;">
<input type="text" name="kebie"  class="kwsel" placeholder="科室" value="<%=com.hospital.WebUtil.htmlEscape(kw_kebie)%>"/>
<input type="text" name="doctor" class="kwsel" placeholder="医生姓名" value="<%=com.hospital.WebUtil.htmlEscape(kw_doctor)%>"/>
<input type="date" name="date"   class="kwsel" value="<%=com.hospital.WebUtil.htmlEscape(kw_date)%>"/>
<input type="submit" value="搜索" style="padding:2px 12px;"/>
<%if("管理员".equals(usertype)){%>
<a href="add_paiban.jsp" style="margin-left:14px;font-size:13px;">+ 新增排班</a>
<%}%>
<a href="list_paiban.jsp" style="margin-left:6px;font-size:13px;color:#888;">重置</a>
</form>

<table width="100%" border="0" cellpadding="2" cellspacing="1" class="table-border margb5">
<tr style="background:#d0e6ff;">
<th>编号</th><th>工号</th><th>医生姓名</th><th>科室</th><th>日期</th><th>时段</th><th>总号</th><th>剩余</th><th>使用率</th><%if("管理员".equals(usertype)){%><th>操作</th><%}%>
</tr>
<%
int total = 0;
while(rs.next()){
    int id = rs.getInt("id");
    String dcode = rs.getString("doctor_code")==null?"":rs.getString("doctor_code");
    String dname = rs.getString("doctor_name")==null?"":rs.getString("doctor_name");
    String kb    = rs.getString("kebie")==null?"":rs.getString("kebie");
    java.sql.Date wd = rs.getDate("work_date");
    String shift = rs.getString("shift")==null?"":rs.getString("shift");
    int t = rs.getInt("total");
    int r = rs.getInt("remain");
    int used = t - r;
    int pct  = t > 0 ? (int)Math.round(used*100.0/t) : 0;
    total++;
    String barColor = pct>=80?"#e74c3c":(pct>=50?"#f39c12":"#27ae60");
%>
<tr>
<td align="center"><%=id%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(dcode)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(dname)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(kb)%></td>
<td align="center"><%=wd%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(shift)%></td>
<td align="center"><%=t%></td>
<td align="center"><b style="color:<%=r==0?"#c0392b":"#2c3e50"%>"><%=r%></b></td>
<td align="center">
  <div style="background:#eee;width:90px;height:14px;display:inline-block;border-radius:3px;overflow:hidden;vertical-align:middle;">
    <div style="background:<%=barColor%>;width:<%=pct%>%;height:14px;line-height:14px;color:#fff;font-size:11px;text-align:right;padding-right:3px;box-sizing:border-box;"><%=pct%>%</div>
  </div>
</td>
<%if("管理员".equals(usertype)){%>
<td align="center">
  <a href="modify_paiban.jsp?id=<%=id%>">修改</a> |
  <form action="delete_paiban.jsp" method="post" style="display:inline;margin:0" onsubmit="return confirm('确定删除该排班记录？该操作不可撤销，请确认！');">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
    <input type="hidden" name="id" value="<%=id%>"/>
    <button type="submit" style="background:none;border:none;color:#0066cc;cursor:pointer;text-decoration:underline;font-size:12pt;padding:0;font-family:inherit;">删除</button>
  </form>
</td>
<%}%>
</tr>
<%
}
a.close();
%>
</table>
<p style="font-size:12px;color:#888;margin-left:6px;">共 <%=total%> 条排班记录（数据范围：2026-09-21 ~ 2026-09-27）</p>
</td></tr></table>
</body>
</html>
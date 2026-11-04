<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype) && !"医生".equals(usertype)){
    out.print("<script>alert('仅管理员/医生可查看药品库存');history.back();</script>"); return;
}

String kw = request.getParameter("kw");
StringBuilder where = new StringBuilder("WHERE active=1");
java.util.List<Object> params = new java.util.ArrayList<Object>();
if(kw!=null && !"".equals(kw.trim())){ where.append(" AND (name LIKE ? OR code LIKE ?)"); params.add("%"+kw.trim()+"%"); params.add("%"+kw.trim()+"%"); }

ResultSet rs = a.executeQuery("SELECT id,code,name,spec,unit,price,stock,category FROM yaoku "+where+" ORDER BY category,name", params.toArray());
int totalRow = 0;
int lowStock = 0;
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>药品库存</title>
<style>.kwsel{font-size:13px;padding:2px 4px;margin-right:6px;}.low{color:#e74c3c;font-weight:bold;}</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">药品库存 > 药品字典与库存（当前账号：<%=loginname%>）</td></tr>
</table>

<form method="get" action="list_yaoku.jsp" style="margin:0 0 10px 0;">
<input type="text" name="kw" class="kwsel" placeholder="药品名称 / 编码" value="<%=com.hospital.WebUtil.htmlEscape(kw)%>"/>
<input type="submit" value="搜索" style="padding:2px 12px;"/>
<%if("管理员".equals(usertype)){%>
<a href="add_yaoku.jsp" style="margin-left:14px;font-size:13px;">+ 新增药品</a>
<%}%>
<a href="list_yaoku.jsp" style="margin-left:6px;font-size:13px;color:#888;">重置</a>
</form>

<table width="100%" border="0" cellpadding="2" cellspacing="1" class="table-border margb5">
<tr style="background:#d0e6ff;">
<th>编号</th><th>编码</th><th>药品名称</th><th>规格</th><th>单位</th><th>分类</th><th>单价</th><th>当前库存</th><%if("管理员".equals(usertype)){%><th>操作</th><%}%>
</tr>
<%
while(rs.next()){
    int id=rs.getInt("id"), stock=rs.getInt("stock");
    String code=rs.getString("code")==null?"":rs.getString("code");
    String name=rs.getString("name")==null?"":rs.getString("name");
    String spec=rs.getString("spec")==null?"":rs.getString("spec");
    String unit=rs.getString("unit")==null?"":rs.getString("unit");
    String cat =rs.getString("category")==null?"":rs.getString("category");
    double price=rs.getDouble("price");
    totalRow++;
    if(stock<20) lowStock++;
    String stockStyle = stock<=0?"low":(stock<20?"low":"");
%>
<tr>
<td align="center"><%=id%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(code)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(name)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(spec)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(unit)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(cat)%></td>
<td align="center">¥<%=String.format("%.2f",price)%></td>
<td align="center" class="<%=stockStyle%>"><%=stock%><%=stock<20?"（<20）":""%></td>
<%if("管理员".equals(usertype)){%>
<td align="center">
  <a href="modify_yaoku.jsp?id=<%=id%>">修改</a> |
  <form action="delete_yaoku.jsp" method="post" style="display:inline;margin:0" onsubmit="return confirm('确定下架该药品？该操作不可撤销，请确认！');">
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
<p style="font-size:12px;color:#888;margin-left:6px;">共 <%=totalRow%> 个药品；<%if(lowStock>0){%><b style="color:#e74c3c"><%=lowStock%> 个库存告急（&lt;20）</b><%}else{%>库存充足<%}%></p>
</td></tr></table>
</body>
</html>
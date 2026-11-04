<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可修改药品');history.back();</script>"); return;
}
int id=0; try{ id=Integer.parseInt(request.getParameter("id")); }catch(Exception e){ id=0; }
if(id<=0){ out.print("<script>alert('参数错误');history.back();</script>"); return; }

String msg="";
String code="",name="",spec="",unit="",cat="";
double price=0; int stock=0;
if("POST".equals(request.getMethod())){
    request.setCharacterEncoding("UTF-8");
    try{ price=Double.parseDouble(request.getParameter("price")); }catch(Exception e){}
    try{ stock=Integer.parseInt(request.getParameter("stock")); }catch(Exception e){}
    code=request.getParameter("code"); name=request.getParameter("name"); spec=request.getParameter("spec");
    unit=request.getParameter("unit"); cat=request.getParameter("category");
    int r = a.executeUpdate("UPDATE yaoku SET code=?,name=?,spec=?,unit=?,price=?,stock=?,category=? WHERE id=?",
            code, name, spec, unit, price, stock, cat, id);
    if(r>0){
        com.hospital.Audit.log(loginname,"修改药品","id="+id+", "+name);
        response.sendRedirect("list_yaoku.jsp"); return;
    } else msg = "<span style='color:red'>保存失败</span>";
}

ResultSet rs = a.executeQuery("SELECT code,name,spec,unit,price,stock,category FROM yaoku WHERE id=?", id);
if(rs.next()){
    code=rs.getString("code")==null?"":rs.getString("code");
    name=rs.getString("name")==null?"":rs.getString("name");
    spec=rs.getString("spec")==null?"":rs.getString("spec");
    unit=rs.getString("unit")==null?"":rs.getString("unit");
    cat =rs.getString("category")==null?"":rs.getString("category");
    price=rs.getDouble("price"); stock=rs.getInt("stock");
}
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>修改药品</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">药品库存 > 修改药品（ID=<%=id%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" style="font-size:14px"><%=msg%></p><%}%>
<form method="post" action="modify_yaoku.jsp">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<input type="hidden" name="id" value="<%=id%>"/>
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">药品编码：</td><td><input type="text" name="code" value="<%=com.hospital.WebUtil.htmlEscape(code)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">药品名称：</td><td><input type="text" name="name" value="<%=com.hospital.WebUtil.htmlEscape(name)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">规格：</td><td><input type="text" name="spec" value="<%=com.hospital.WebUtil.htmlEscape(spec)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">单位：</td><td><input type="text" name="unit" value="<%=com.hospital.WebUtil.htmlEscape(unit)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">单价（元）：</td><td><input type="number" name="price" step="0.01" value="<%=price%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">当前库存：</td><td><input type="number" name="stock" value="<%=stock%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">分类：</td><td><input type="text" name="category" value="<%=com.hospital.WebUtil.htmlEscape(cat)%>" style="width:220px"/></td></tr>
<tr><td colspan="2" align="center"><input type="submit" value="保存" style="width:120px;height:28px"/>
<input type="button" value="返回" onclick="history.go(-1)" style="width:120px;height:28px"/></td></tr>
</table>
</form>
</td></tr></table>
</body>
</html>
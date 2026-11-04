<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可保存药品');history.back();</script>"); return;
}
if(!"POST".equals(request.getMethod())){ out.print("<script>alert('请通过表单提交');history.back();</script>"); return; }
request.setCharacterEncoding("UTF-8");
String code=request.getParameter("code"), name=request.getParameter("name"), spec=request.getParameter("spec"),
       unit=request.getParameter("unit"), cat=request.getParameter("category");
double price=0; int stock=0;
try{ price=Double.parseDouble(request.getParameter("price")); }catch(Exception e){}
try{ stock=Integer.parseInt(request.getParameter("stock")); }catch(Exception e){}
if(name==null||name.trim().equals("")){ out.print("<script>alert('药品名称不能为空');history.back();</script>"); return; }

int r = a.executeUpdate("INSERT INTO yaoku(code,name,spec,unit,price,stock,category,active) VALUES(?,?,?,?,?,?,?,1)",
        code, name.trim(), spec, unit, price, stock, cat);
if(r>0) com.hospital.Audit.log(loginname,"新增药品", name.trim()+"/"+spec+"/"+unit+" 库存="+stock);
response.sendRedirect("list_yaoku.jsp");
%>
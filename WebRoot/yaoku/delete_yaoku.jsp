<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可下架药品');history.back();</script>"); return;
}
int id=0; try{ id=Integer.parseInt(request.getParameter("id")); }catch(Exception e){ id=0; }
if(id<=0){ out.print("<script>alert('参数错误');history.back();</script>"); return; }
// 软删除：保留全部商品，但 active=0（下架），防止历史处方指向已删除药品
int r = a.executeUpdate("UPDATE yaoku SET active=0 WHERE id=?", id);
if(r>0) com.hospital.Audit.log(loginname,"下架药品","id="+id);
response.sendRedirect("list_yaoku.jsp");
%>
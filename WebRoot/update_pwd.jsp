<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.hospital.*" %>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon"/>
<%
// 登录校验（AuthFilter 已在外层兜底，这里保留双保险）
String __ln=(String)session.getAttribute("loginname");
if(__ln==null||"".equals(__ln)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
int uid=(Integer)session.getAttribute("uid");

request.setCharacterEncoding("UTF-8");
String oldpwd = request.getParameter("pwd1");
String newpwd = request.getParameter("pwd2");
String repwd  = request.getParameter("pwd3");

// 1. 服务端校验原密码（密码不再明文出现在任何页面上）
ResultSet rs = a.executeQuery("SELECT loginpwd FROM loginuser WHERE id=?", uid);
String stored = null;
if(rs!=null && rs.next()) stored = rs.getString("loginpwd");

if(oldpwd==null || oldpwd.isEmpty() || !PasswordUtil.verify(oldpwd, stored)){
    a.close();
    out.print("<script>alert('原密码不正确');history.back();</script>");
    return;
}
// 2. 新密码非空 + 两次一致
if(newpwd==null || newpwd.trim().isEmpty() || !newpwd.equals(repwd)){
    out.print("<script>alert('两次输入的新密码不一致');history.back();</script>");
    return;
}
// 3. 参数化更新，且新密码哈希存储
int r = a.executeUpdate("UPDATE loginuser SET loginpwd=? WHERE id=?",
        PasswordUtil.hash(newpwd.trim()), uid);
a.close();
Audit.log(__ln, "修改密码", "修改成功");
response.sendRedirect("pwd.jsp");
%>

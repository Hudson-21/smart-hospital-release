<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page language="java" %>
<%@ page import="java.util.*,com.hospital.*" %>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>
<%
    // Tomcat 9 默认按 UTF-8 解码请求参数，注册页也是 UTF-8，
    // 直接取参数即可；不要做 ISO-8859-1→GB2312 转换（会把中文转成乱码存库）
    request.setCharacterEncoding("UTF-8");
    String user  = request.getParameter("username");
    String pwd   = request.getParameter("password");
    String repwd = request.getParameter("repassword");

    // 1. 非空校验
    if (user == null || user.trim().isEmpty()
            || pwd == null || pwd.trim().isEmpty()
            || repwd == null || repwd.trim().isEmpty()) {
        response.sendRedirect("register.jsp?error=1");
        return;
    }
    // 2. 两次密码一致性校验
    if (!pwd.equals(repwd)) {
        response.sendRedirect("register.jsp?error=2");
        return;
    }
    // 2.5 用户名格式校验：只允许中英文/数字/下划线，2-20 位（防 XSS 与脏数据）
    if (!user.trim().matches("^[\\u4e00-\\u9fa5A-Za-z0-9_]{2,20}$")) {
        response.sendRedirect("register.jsp?error=4");
        return;
    }

    // 3. 用户名查重（参数化，防注入）
    ResultSet rs = db.executeQuery("SELECT id FROM loginuser WHERE loginname=?", user);
    if (rs != null && rs.next()) {
        if (rs != null) rs.close();
        db.close();
        response.sendRedirect("register.jsp?error=3");
        return;
    }
    if (rs != null) rs.close();

    // 4. 插入新用户，默认 patient（病人）角色；密码哈希存储
    String sql2 = "INSERT INTO loginuser(loginname, loginpwd, usertype) VALUES(?,?,?)";
    PreparedStatement ps = db.preparedstatements(sql2);
    ps.setString(1, user);
    ps.setString(2, PasswordUtil.hash(pwd));
    ps.setString(3, "病人");
    ps.executeUpdate();
    ps.close();
    db.close();

    // 5. 注册成功，跳转登录页
    response.sendRedirect("login.jsp?reg=ok");
%>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>用户注册 - 智能化医院管理系统</title>
    

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-auth.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
</head>
<body class="h-auth">
<%
    String errmsg = "";
    String err = request.getParameter("error");
    if ("1".equals(err)) errmsg = "请填写完整的注册信息";
    else if ("2".equals(err)) errmsg = "两次输入的密码不一致";
    else if ("3".equals(err)) errmsg = "该用户名已被注册";
    else if ("4".equals(err)) errmsg = "用户名只能是2-20位中英文、数字或下划线";
%>
<div class="login-container">
    <div class="login-left">
        <span class="auth-mark" data-icon="hospital"></span>
        <h1>医院管理系统</h1>
        <h2>Smart Hospital Management System</h2>
        <p>创建您的个人账号，体验智能导诊、预约挂号与病历管理等便捷服务。</p>
        <div class="features">
            <div class="feature-item">智能导诊分诊</div>
            <div class="feature-item">在线预约挂号</div>
            <div class="feature-item">病历与收费管理</div>
            <div class="feature-item">患者与医护协同服务</div>
        </div>
    </div>
    <div class="login-right">
        <div class="welcome <%= "".equals(errmsg) ? "" : "err" %>"><%= "".equals(errmsg) ? "欢迎注册" : com.hospital.WebUtil.htmlEscape(errmsg) %></div>
        <h3>创建账号</h3>
        <form name="form1" method="post" action="do_register.jsp">
            <div class="form-group">
                <label for="auth-username">用户名</label>
                <input autocomplete="username" id="auth-username" name="username" type="text" placeholder="请设置登录用户名" required>
            </div>
            <div class="form-group">
                <label for="auth-password">密码</label>
                <input autocomplete="new-password" id="auth-password" name="password" type="password" placeholder="请设置登录密码" required>
            </div>
            <div class="form-group">
                <label for="auth-repassword">确认密码</label>
                <input autocomplete="new-password" id="auth-repassword" name="repassword" type="password" placeholder="请再次输入密码" required>
            </div>
            <button type="submit" class="reg-btn">注 册</button>
        </form>
        <div class="link-row">已有账号？<a href="login.jsp">立即登录</a></div>
    </div>
</div>
<div class="footer">智能化医院管理系统 &copy; 2026</div>
</body>
</html>

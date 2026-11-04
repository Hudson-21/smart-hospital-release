<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智能化医院管理系统 - 登录</title>
    

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-auth.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
</head>
<body class="h-auth">
<%
    session.removeAttribute("loginname");
    session.removeAttribute("rname");
    session.removeAttribute("uid");
    session.removeAttribute("usertype");
    session.invalidate();
%>
<div class="login-container">
    <div class="login-left">
        <span class="auth-mark" data-icon="hospital"></span>
        <h1>医院管理系统</h1>
        <h2>Smart Hospital Management System</h2>
        <div class="features">
            <div class="feature-item">智能导诊分诊</div>
            <div class="feature-item">在线预约挂号</div>
            <div class="feature-item">病历与收费管理</div>
            <div class="feature-item">患者与医护协同服务</div>
        </div>
    </div>
    <div class="login-right">
        <div class="welcome <%= request.getParameter("error") != null ? "err" : "" %>" role="status">
<%
    String err = request.getParameter("error");
    String reg = request.getParameter("reg");
    if ("1".equals(err)) out.print("验证码错误，请重新输入");
    else if ("2".equals(err)) out.print("所选角色与该账号不符，请切换角色后重试");
    else if ("3".equals(err)) out.print("账号或密码错误");
    else if ("ok".equals(reg)) out.print("注册成功，请登录");
    else out.print("欢迎回来");
%>
        </div>
        <h3>账号登录</h3>
        <form name="form1" method="post" action="check_login.jsp">
            <div class="form-group">
                <label for="auth-username">用户名</label>
                <input autocomplete="username" id="auth-username" name="username" type="text" placeholder="请输入用户名" required>
            </div>
            <div class="form-group">
                <label for="auth-password">密码</label>
                <input autocomplete="current-password" id="auth-password" name="password" type="password" placeholder="请输入密码" required>
            </div>
            <div class="form-group">
                <label>登录角色</label>
                <div class="role-group" id="roleGroup">
                    <button type="button" class="role-item" data-role="管理员" aria-pressed="false"><span class="ico" data-icon="shield"></span>管理员</button>
                    <button type="button" class="role-item" data-role="医生" aria-pressed="false"><span class="ico" data-icon="hospital"></span>医生</button>
                    <button type="button" class="role-item selected" data-role="病人" aria-pressed="true"><span class="ico" data-icon="user"></span>病人</button>
                </div>
                <input type="hidden" name="role" id="roleInput" value="病人">
            </div>
            <div class="form-group">
                <label for="auth-checkcode">验证码</label>
                <div style="display:flex; gap:10px; align-items:center;">
                    <input id="auth-checkcode" name="checkcode" type="text" placeholder="请输入右侧验证码" maxlength="4" required style="flex:1;">
                    <img alt="验证码，点击刷新" src="captcha.jsp" onclick="this.src='captcha.jsp?'+Math.random()" title="点击刷新验证码" style="height:46px; border-radius:8px; cursor:pointer;">
                </div>
            </div>
            <button type="submit" class="login-btn">登 录</button>
        </form>
        <script>
        (function(){
            var g=document.getElementById("roleGroup"), h=document.getElementById("roleInput");
            g.addEventListener("click",function(e){
                var it=e.target.closest(".role-item"); if(!it) return;
                g.querySelectorAll(".role-item").forEach(function(x){x.classList.remove("selected");x.setAttribute("aria-pressed","false");});
                it.classList.add("selected");it.setAttribute("aria-pressed","true");
                h.value=it.getAttribute("data-role");
            });
        })();
        </script>
        <div class="link-row">还没有账号？<a href="register.jsp">立即注册</a></div>
    </div>
</div>
<div class="footer">智能化医院管理系统 &copy; 2026</div>
</body>
</html>

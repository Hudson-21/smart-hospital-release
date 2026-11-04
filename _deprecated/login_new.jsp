<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>智能化医院管理系统 - 登录</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: "Microsoft YaHei", "PingFang SC", "Helvetica Neue", Arial, sans-serif;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 50%, #90caf9 100%);
            position: relative;
            overflow: hidden;
        }
        /* 背景装饰 */
        body::before {
            content: "";
            position: absolute;
            width: 600px;
            height: 600px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.25);
            top: -200px;
            right: -200px;
        }
        body::after {
            content: "";
            position: absolute;
            width: 400px;
            height: 400px;
            border-radius: 50%;
            background: rgba(255, 255, 255, 0.2);
            bottom: -100px;
            left: -100px;
        }
        .login-container {
            position: relative;
            z-index: 1;
            width: 90%;
            max-width: 980px;
            min-height: 540px;
            background: #ffffff;
            border-radius: 20px;
            box-shadow: 0 25px 80px rgba(25, 118, 210, 0.25);
            display: flex;
            overflow: hidden;
        }
        .login-left {
            flex: 1;
            background: linear-gradient(160deg, #1976d2 0%, #2196f3 60%, #42a5f5 100%);
            color: #fff;
            padding: 60px 50px;
            display: flex;
            flex-direction: column;
            justify-content: center;
            position: relative;
            overflow: hidden;
        }
        .login-left::before {
            content: "";
            position: absolute;
            width: 300px;
            height: 300px;
            border: 2px solid rgba(255,255,255,0.15);
            border-radius: 50%;
            top: -80px;
            left: -80px;
        }
        .login-left::after {
            content: "";
            position: absolute;
            width: 200px;
            height: 200px;
            border: 2px solid rgba(255,255,255,0.1);
            border-radius: 50%;
            bottom: -50px;
            right: -50px;
        }
        .login-left h1 {
            font-size: 38px;
            font-weight: 600;
            margin-bottom: 20px;
            letter-spacing: 2px;
        }
        .login-left h2 {
            font-size: 22px;
            font-weight: 400;
            margin-bottom: 30px;
            opacity: 0.95;
        }
        .login-left p {
            font-size: 15px;
            line-height: 1.8;
            opacity: 0.9;
            max-width: 320px;
        }
        .login-left .features {
            margin-top: 40px;
        }
        .login-left .feature-item {
            display: flex;
            align-items: center;
            margin-bottom: 14px;
            font-size: 14px;
            opacity: 0.9;
        }
        .login-left .feature-item::before {
            content: "✓";
            display: inline-flex;
            align-items: center;
            justify-content: center;
            width: 20px;
            height: 20px;
            background: rgba(255,255,255,0.25);
            border-radius: 50%;
            margin-right: 10px;
            font-size: 12px;
        }
        .login-right {
            flex: 1;
            padding: 60px 55px;
            display: flex;
            flex-direction: column;
            justify-content: center;
        }
        .login-right .welcome {
            font-size: 14px;
            color: #78909c;
            margin-bottom: 8px;
        }
        .login-right h3 {
            font-size: 28px;
            color: #263238;
            margin-bottom: 35px;
            font-weight: 600;
        }
        .form-group {
            margin-bottom: 24px;
        }
        .form-group label {
            display: block;
            font-size: 14px;
            color: #546e7a;
            margin-bottom: 8px;
            font-weight: 500;
        }
        .form-group input {
            width: 100%;
            height: 46px;
            padding: 0 16px;
            border: 1px solid #e0e0e0;
            border-radius: 10px;
            font-size: 15px;
            color: #37474f;
            transition: all 0.3s ease;
            outline: none;
        }
        .form-group input:focus {
            border-color: #2196f3;
            box-shadow: 0 0 0 3px rgba(33, 150, 243, 0.1);
        }
        .form-group input::placeholder {
            color: #b0bec5;
        }
        .login-btn {
            width: 100%;
            height: 48px;
            margin-top: 10px;
            background: linear-gradient(135deg, #1976d2 0%, #2196f3 100%);
            border: none;
            border-radius: 10px;
            color: #fff;
            font-size: 16px;
            font-weight: 500;
            cursor: pointer;
            transition: all 0.3s ease;
            letter-spacing: 2px;
        }
        .login-btn:hover {
            background: linear-gradient(135deg, #1565c0 0%, #1e88e5 100%);
            box-shadow: 0 8px 20px rgba(33, 150, 243, 0.35);
            transform: translateY(-1px);
        }
        /* 登录角色选择 */
        .role-group { display:flex; gap:10px; }
        .role-item { flex:1; height:52px; border:1.5px solid #e0e0e0; border-radius:10px;
            display:flex; align-items:center; justify-content:center; gap:7px;
            font-size:14px; color:#546e7a; cursor:pointer; user-select:none;
            transition:all .2s ease; background:#fafbfc; }
        .role-item:hover { border-color:#90caf9; }
        .role-item.selected { border-color:#2196f3; background:#e3f2fd; color:#1565c0; font-weight:600;
            box-shadow:0 2px 8px rgba(33,150,243,.15); }
        .role-item .ico { font-size:18px; }
        .link-row { margin-top:16px; text-align:center; font-size:14px; color:#78909c; }
        .link-row a { color:#2196f3; text-decoration:none; }
        .link-row a:hover { text-decoration:underline; }
        .footer {
            position: absolute;
            bottom: 25px;
            left: 0;
            width: 100%;
            text-align: center;
            color: #607d8b;
            font-size: 13px;
            z-index: 2;
        }
        @media (max-width: 768px) {
            .login-left {
                display: none;
            }
            .login-right {
                padding: 40px 30px;
            }
        }
    </style>
</head>
<body>
<%
    session.removeAttribute("loginname");
    session.removeAttribute("rname");
    session.removeAttribute("uid");
    session.removeAttribute("usertype");
    session.invalidate();
%>
<div class="login-container">
    <div class="login-left">
        <h1>智能化医院管理系统</h1>
        <h2>Smart Hospital Management System</h2>
        <div class="features">
            <div class="feature-item">智能导诊分诊</div>
            <div class="feature-item">在线预约挂号</div>
            <div class="feature-item">病历与收费管理</div>
            <div class="feature-item">多角色权限控制</div>
        </div>
    </div>
    <div class="login-right">
        <div class="welcome" style="color:#e53935; min-height:20px;">
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
                <label>用户名</label>
                <input name="username" type="text" placeholder="请输入用户名" required>
            </div>
            <div class="form-group">
                <label>密码</label>
                <input name="password" type="password" placeholder="请输入密码" required>
            </div>
            <div class="form-group">
                <label>登录角色</label>
                <div class="role-group" id="roleGroup">
                    <div class="role-item" data-role="管理员"><span class="ico">🛡️</span>管理员</div>
                    <div class="role-item" data-role="医生"><span class="ico">🩺</span>医生</div>
                    <div class="role-item selected" data-role="病人"><span class="ico">🧑</span>病人</div>
                </div>
                <input type="hidden" name="role" id="roleInput" value="病人">
            </div>
            <div class="form-group">
                <label>验证码</label>
                <div style="display:flex; gap:10px; align-items:center;">
                    <input name="checkcode" type="text" placeholder="请输入右侧验证码" maxlength="4" required style="flex:1;">
                    <img src="captcha.jsp" onclick="this.src='captcha.jsp?'+Math.random()" title="点击刷新验证码" style="height:46px; border-radius:8px; cursor:pointer;">
                </div>
            </div>
            <button type="submit" class="login-btn">登 录</button>
        </form>
        <script>
        (function(){
            var g=document.getElementById("roleGroup"), h=document.getElementById("roleInput");
            g.addEventListener("click",function(e){
                var it=e.target.closest(".role-item"); if(!it) return;
                g.querySelectorAll(".role-item").forEach(function(x){x.classList.remove("selected");});
                it.classList.add("selected");
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

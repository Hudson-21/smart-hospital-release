<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page language="java" %>
<%@ page import="java.util.*,com.hospital.*" %>

<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>
<html>
<head>
<title>登录验证</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff">
<%
	// 关键：必须在所有 getParameter 之前设置请求编码，否则对 POST 参数不生效
	request.setCharacterEncoding("UTF-8");

	// 验证码校验（一次性使用：无论成功失败都立刻作废，防止重放）
	String inputCode = request.getParameter("checkcode");
	String realCode = (String) session.getAttribute("checkcode");
	session.removeAttribute("checkcode");
	boolean codeOk = inputCode != null && realCode != null
			&& inputCode.trim().equalsIgnoreCase(realCode);
	if (!codeOk) {
		Audit.log(null, "登录失败", "验证码错误");
		response.sendRedirect("login.jsp?error=1");
		return;
	}

	// 直接取参数（Tomcat 9 + UTF-8 页面，无需再做 ISO-8859-1→GB2312 旧转换）
	String user = request.getParameter("username");
	String pwd = request.getParameter("password");
	String role = request.getParameter("role");   // 登录页选择的角色：管理员/医生/病人
	if (role == null) role = "";
	if (user != null) user = user.trim();
	if (pwd != null) pwd = pwd.trim();
	if (user == null || user.isEmpty() || pwd == null || pwd.isEmpty()) {
		Audit.log(user, "登录失败", "用户名或密码为空");
		response.sendRedirect("login.jsp?error=3");
		return;
	}

	// 参数化查询：只按用户名取账号，密码用 PBKDF2 校验，杜绝 SQL 注入
	ResultSet rs = db.executeQuery("SELECT * FROM loginuser WHERE loginname=?", user);
	if (rs != null && rs.next()) {
		String loginname = rs.getString("loginname");
		int uid = rs.getInt("id");
		String usertype = rs.getString("usertype");
		String storedPwd = rs.getString("loginpwd");

		if (!PasswordUtil.verify(pwd, storedPwd)) {
			Audit.log(loginname, "登录失败", "密码错误");
			response.sendRedirect("login.jsp?error=3");
			return;
		}
		// 旧明文口令登录成功：立即回写为哈希（平滑迁移）
		if (!PasswordUtil.isHashed(storedPwd)) {
			db.executeUpdate("UPDATE loginuser SET loginpwd=? WHERE id=?",
					PasswordUtil.hash(pwd), uid);
		}

		// 角色一致性校验：登录页所选角色必须与账号实际角色匹配，防止角色错位进入系统
		boolean roleOk;
		if ("管理员".equals(role)) {
			roleOk = "管理员".equals(usertype) || "admin".equalsIgnoreCase(usertype);
		} else if ("医生".equals(role)) {
			roleOk = "医生".equals(usertype) || "doctor".equalsIgnoreCase(usertype);
		} else if ("病人".equals(role)) {
			roleOk = "病人".equals(usertype) || "patient".equalsIgnoreCase(usertype);
		} else {
			roleOk = true;   // 未传角色时保持旧行为（兼容老入口）
		}
		if (!roleOk) {
			Audit.log(loginname, "登录失败", "角色不匹配，选择了 " + role);
			response.sendRedirect("login.jsp?error=2");
			return;
		}

		request.getSession(true);
		session.setAttribute("loginname", loginname);
		session.setAttribute("uid", uid);
		session.setAttribute("usertype", usertype);
		Audit.log(loginname, "登录成功", "角色：" + usertype);
		response.sendRedirect("index.jsp");
	} else {
		Audit.log(user, "登录失败", "账号不存在");
		response.sendRedirect("login.jsp?error=3");
	}

%>

</body>
</html>

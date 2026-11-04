package com.hospital;

import java.io.IOException;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * 全局鉴权过滤器（2026-09-22 新增，2026-09-23 升级为角色级访问控制）。
 *
 * 职责分两层：
 *   1) 认证：未登录一律拦截，页面跳登录页、AJAX/接口返回 401；
 *   2) 授权：已登录但角色无权访问该路径时拦截，页面返回 403 提示页、接口返回 403 JSON。
 *
 * 角色矩阵与 left.jsp 中各角色的菜单完全一致：
 *   管理员 —— 全部功能
 *   医生   —— 仅本人工作台（我的档案/病人/费用/接诊/病历）+ AI 病历助手 + 智能导诊
 *   病人   —— 仅本人信息/费用/挂号/病历 + 智能导诊
 *
 * 设计原则：白名单之外一律拒绝（default deny），
 * 避免"新增页面忘记配置就默认可访问"。
 */
public class AuthFilter implements Filter {

	/** 无需登录即可访问（登录/注册流程、统一错误页与静态资源） */
	private static final String[] PUBLIC_PAGES = {
		"/login.jsp", "/check_login.jsp", "/captcha.jsp",
		"/register.jsp", "/do_register.jsp", "/error.jsp", "/error_page.jsp", "/favicon.ico"
	};
	private static final String[] PUBLIC_PREFIXES = {
		"/images/", "/calendar/", "/css/", "/js/", "/META-INF/"
	};

	/** 登录后任何角色都可访问（框架页、改密、AI 对话入口、AI 统一网关） */
	private static final String[] COMMON_PAGES = {
		"/index.jsp", "/top.jsp", "/left.jsp", "/right.jsp",
		"/pwd.jsp", "/update_pwd.jsp", "/error.jsp",
		"/ai/ask.jsp", "/ai/history.jsp", "/ai/api.jsp",
		/* ai/llm.jsp 是统一 AI 网关：病人端"病历大白话解读"也要调它。
		 * 放这里不会越权——该 JSP 内部按 task 做了二次角色校验：
		 *   bingli_draft / bingli_qc -> 仅医生；stats_query -> 仅管理员/医生；
		 *   bingli_explain -> 患者/医生均可（设计如此）。 */
		"/ai/llm.jsp"
	};

	/** 仅管理员：整目录独占 */
	private static final String[] ADMIN_PREFIXES = {
		"/bed/", "/cost/", "/query/", "/stats/"
	};
	/** 仅管理员：散落在共享目录里的管理端页面 */
	private static final String[] ADMIN_PAGES = {
		"/guahao/list_guahao.jsp",
		"/doctor/list_user.jsp", "/doctor/adduser.jsp", "/doctor/saveadd.jsp",
		"/doctor/deleteuser.jsp", "/doctor/modifyuser.jsp",
		"/doctor/role_manage.jsp",
		"/patient/list_patient.jsp", "/patient/addpatient.jsp", "/patient/savepatient.jsp",
		"/patient/modifypatient.jsp", "/patient/deletepatient.jsp"
	};

	/** 医生本人工作台 */
	private static final String[] DOCTOR_PAGES = {
		"/doctor/my_info.jsp", "/doctor/my_patient.jsp", "/doctor/my_cost.jsp",
		"/doctor/my_guahao.jsp", "/doctor/my_bingli.jsp", "/doctor/my_patient_edit.jsp",
		"/doctor/add_bingli.jsp", "/doctor/add_chufang.jsp", "/doctor/save_chufang.jsp"
	};

	/** 病人本人自助 */
	private static final String[] PATIENT_PAGES = {
		"/patient/my_info.jsp", "/patient/my_cost.jsp", "/patient/my_guahao.jsp",
		"/patient/my_bingli.jsp", "/patient/guahao.jsp", "/patient/paiban_shift_api.jsp"
	};

	/** 排班/药品库存/处方 目录：所有角色都能访问，页内做角色二次判断 */
	private static final String[] SHARED_DIRS = {
		"/paiban/", "/yaoku/", "/chufang/"
	};

	/**
	 * CSRF 校验豁免名单：这些 POST 端点不要求 _csrf token。
	 *  - 登录/注册：此时会话刚被 login.jsp 主动 invalidate，token 无法可靠携带；
	 *    且二者已有验证码 + 口令双重保护。
	 *  - AI 接口：由前端 fetch 调用，写入的只是调用者自己的对话审计，无敏感副作用。
	 * 其余所有 POST（增删改、开方、挂号等写操作）一律要求有效 token。
	 */
	private static final String[] CSRF_EXEMPT = {
		"/check_login.jsp", "/do_register.jsp",
		"/ai/api.jsp", "/ai/llm.jsp"
	};

	@Override
	public void init(FilterConfig cfg) { }

	@Override
	public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
			throws IOException, ServletException {
		HttpServletRequest request = (HttpServletRequest) req;
		HttpServletResponse response = (HttpServletResponse) res;

		// ⚠ 必须在任何 getParameter 之前设置请求编码。
		// 下面第三层的 CSRF 校验会读 _csrf 参数，一旦先读了参数，
		// Servlet 容器就按默认编码解析了整个请求体，JSP 里那句
		// request.setCharacterEncoding("UTF-8") 将不再生效，
		// 表现就是"表单里提交的中文全变成 ? 或乱码"（从库里读的中文却正常）。
		try { request.setCharacterEncoding("UTF-8"); } catch (Exception ignore) { }

		String uri = request.getRequestURI();
		String ctx = request.getContextPath();
		String path = uri.startsWith(ctx) ? uri.substring(ctx.length()) : uri;

		// 根路径（浏览器直接打开 http://host/应用名/ 或 http://host/应用名）：
		// 容器会把它交给 welcome-file(login.jsp)，但 filter 拿到的是 "/"，
		// 而 "/" 不在任何角色白名单里，default deny 会把它误判成 403。
		// 这里显式分流：已登录进首页，未登录交登录页。
		// ⚠ 不能让已登录用户落到 login.jsp —— 那个页面开头会 session.invalidate()。
		if (path.isEmpty() || "/".equals(path)) {
			HttpSession rootSession = request.getSession(false);
			String rootUser = rootSession == null ? null : (String) rootSession.getAttribute("loginname");
			if (rootUser != null && !rootUser.trim().isEmpty()) {
				response.sendRedirect(ctx + "/index.jsp");
			} else {
				response.sendRedirect(ctx + "/login.jsp");
			}
			return;
		}

		// 静态资源 / 登录注册入口：直接放行
		if (isPublic(path)) {
			chain.doFilter(req, res);
			return;
		}

		// ---- 第一层：认证 ----
		HttpSession session = request.getSession(false);
		String loginname = session == null ? null : (String) session.getAttribute("loginname");
		if (loginname == null || loginname.trim().isEmpty()) {
			unauthorized(request, response, ctx);
			return;
		}

		// ---- 第二层：授权 ----
		String usertype = (String) session.getAttribute("usertype");
		int role = normalizeRole(usertype);
		if (!isAllowed(path, role)) {
			forbidden(request, response, usertype, path);
			return;
		}

		// ---- 第三层：CSRF 防护 ----
		// 所有写操作（POST）必须携带与会话一致的 _csrf token；
		// 攻击者站点读不到受害者会话里的 token，构造不出合法请求。
		if ("POST".equalsIgnoreCase(request.getMethod()) && !contains(CSRF_EXEMPT, path)) {
			if (!Csrf.verify(request)) {
				forbiddenCsrf(request, response);
				return;
			}
		}

		chain.doFilter(req, res);
	}

	/** 角色归一化：兼容库里的中文取值与英文取值 */
	private static int normalizeRole(String usertype) {
		if (usertype == null) return ROLE_UNKNOWN;
		String t = usertype.trim();
		if ("管理员".equals(t) || "admin".equalsIgnoreCase(t)) return ROLE_ADMIN;
		if ("医生".equals(t)   || "doctor".equalsIgnoreCase(t)) return ROLE_DOCTOR;
		if ("病人".equals(t)   || "patient".equalsIgnoreCase(t)) return ROLE_PATIENT;
		return ROLE_UNKNOWN;
	}

	private static final int ROLE_ADMIN = 1;
	private static final int ROLE_DOCTOR = 2;
	private static final int ROLE_PATIENT = 3;
	private static final int ROLE_UNKNOWN = 0;

	/** 白名单判定（default deny：不在任何名单里的路径一律拒绝） */
	private boolean isAllowed(String path, int role) {
		if (path == null || path.isEmpty()) return false;
		if (contains(COMMON_PAGES, path)) return true;
		if (startsWith(SHARED_DIRS, path)) return true;       // 共享目录，页内做角色二次判断

		switch (role) {
			case ROLE_ADMIN:
				return true;                       // 管理员：全部功能
			case ROLE_DOCTOR:
				if (startsWith(ADMIN_PREFIXES, path)) return false;
				if (contains(ADMIN_PAGES, path)) return false;
				return contains(DOCTOR_PAGES, path);
			case ROLE_PATIENT:
				if (startsWith(ADMIN_PREFIXES, path)) return false;
				if (contains(ADMIN_PAGES, path)) return false;
				if (contains(DOCTOR_PAGES, path)) return false;
				return contains(PATIENT_PAGES, path);
			default:
				return false;                      // 未识别角色：一律拒绝
		}
	}

	private boolean isPublic(String path) {
		if (path == null || path.isEmpty() || "/".equals(path)) return false;
		if (contains(PUBLIC_PAGES, path)) return true;
		return startsWith(PUBLIC_PREFIXES, path);
	}

	private static boolean contains(String[] arr, String path) {
		for (String s : arr) if (s.equals(path)) return true;
		return false;
	}

	private static boolean startsWith(String[] arr, String path) {
		for (String s : arr) if (path.startsWith(s)) return true;
		return false;
	}

	private void unauthorized(HttpServletRequest request, HttpServletResponse response, String ctx)
			throws IOException {
		if (isAjax(request)) {
			response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
			response.setContentType("application/json; charset=UTF-8");
			response.getWriter().print("{\"ok\":false,\"error\":\"未登录或会话已过期，请重新登录\"}");
		} else {
			response.sendRedirect(ctx + "/login.jsp");
		}
	}

	private void forbidden(HttpServletRequest request, HttpServletResponse response,
	                       String usertype, String path) throws IOException {
		if (isAjax(request)) {
			response.setStatus(HttpServletResponse.SC_FORBIDDEN);
			response.setContentType("application/json; charset=UTF-8");
			response.getWriter().print("{\"ok\":false,\"error\":\"当前角色无权访问该资源\"}");
			return;
		}
		response.setStatus(HttpServletResponse.SC_FORBIDDEN);
		response.setContentType("text/html; charset=UTF-8");
		response.getWriter().print(
			"<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>无访问权限</title>"
			+ "<style>body{font-family:'Microsoft YaHei',sans-serif;background:#f5f6f8;"
			+ "display:flex;align-items:center;justify-content:center;height:100vh;margin:0;color:#4a4d55}"
			+ ".box{background:#fff;border:1px solid #e3e5ea;border-radius:10px;padding:32px 40px;"
			+ "box-shadow:0 4px 18px rgba(0,0,0,.06);text-align:center}"
			+ "h2{margin:0 0 10px;font-size:20px;color:#e0483d;font-weight:600}"
			+ "p{margin:6px 0;font-size:14px;line-height:1.7}"
			+ "code{background:#f2f3f6;padding:2px 6px;border-radius:4px;font-size:13px}"
			+ "a{display:inline-block;margin-top:16px;color:#03A8F6;text-decoration:none}"
			+ "</style></head><body><div class=\"box\">"
			+ "<h2>403 · 无访问权限</h2>"
			+ "<p>当前角色：<code>" + esc(usertype) + "</code></p>"
			+ "<p>该页面仅对有权限的角色开放。</p>"
			+ "<a href=\"javascript:history.back()\">返回上一页</a>"
			+ "</div></body></html>");
	}

	private boolean isAjax(HttpServletRequest request) {
		String accept = request.getHeader("Accept");
		String xReq = request.getHeader("X-Requested-With");
		return (accept != null && accept.contains("application/json"))
				|| "XMLHttpRequest".equals(xReq);
	}

	/** CSRF 校验失败：拒绝本次写操作（返回 403，不执行任何业务逻辑） */
	private void forbiddenCsrf(HttpServletRequest request, HttpServletResponse response)
			throws IOException {
		if (isAjax(request)) {
			response.setStatus(HttpServletResponse.SC_FORBIDDEN);
			response.setContentType("application/json; charset=UTF-8");
			response.getWriter().print("{\"ok\":false,\"error\":\"请求校验失败，请刷新页面后重试\"}");
			return;
		}
		response.setStatus(HttpServletResponse.SC_FORBIDDEN);
		response.setContentType("text/html; charset=UTF-8");
		response.getWriter().print(
			"<!DOCTYPE html><html><head><meta charset=\"UTF-8\"><title>请求已拒绝</title>"
			+ "<style>body{font-family:'Microsoft YaHei',sans-serif;background:#f5f6f8;"
			+ "display:flex;align-items:center;justify-content:center;height:100vh;margin:0;color:#4a4d55}"
			+ ".box{background:#fff;border:1px solid #e3e5ea;border-radius:10px;padding:32px 40px;"
			+ "box-shadow:0 4px 18px rgba(0,0,0,.06);text-align:center}"
			+ "h2{margin:0 0 10px;font-size:20px;color:#e0483d;font-weight:600}"
			+ "p{margin:6px 0;font-size:14px;line-height:1.7}"
			+ "a{display:inline-block;margin-top:16px;color:#03A8F6;text-decoration:none}"
			+ "</style></head><body><div class=\"box\">"
			+ "<h2>403 · 请求校验失败</h2>"
			+ "<p>本次提交缺少有效的安全令牌，已被拦截。</p>"
			+ "<p>常见原因：页面停留过久导致会话刷新，或从其他站点直接提交表单。</p>"
			+ "<a href=\"javascript:history.back()\">返回上一页重试</a>"
			+ "</div></body></html>");
	}

	/** 403 页面里的角色值回显做 HTML 转义，避免反射型 XSS */
	private String esc(String s) {
		if (s == null) return "";
		return s.replace("&", "&amp;").replace("<", "&lt;")
				.replace(">", "&gt;").replace("\"", "&quot;");
	}

	@Override
	public void destroy() { }
}

package com.hospital;

import java.security.SecureRandom;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

/**
 * CSRF（跨站请求伪造）防护工具：会话级随机 token。
 *
 * 原理：登录后为每个会话生成一个不可预测的随机串，写操作表单必须带上它；
 *       服务端比对通过才执行。攻击者站点无法读取受害者会话里的 token，
 *       因此构造不出合法请求，其自动提交的表单会被拒。
 *
 * 用法：
 *   表单页：&lt;input type="hidden" name="_csrf" value="&lt;%=Csrf.token(session)%&gt;"&gt;
 *   校验：  if (!Csrf.verify(request)) 则拒绝本次请求
 *
 * 说明：token 存 session，会话建立即生成，整场会话复用（避免多标签页互相失效）。
 *       AuthFilter 已对全站 POST 统一校验，业务页面无需重复写校验代码。
 */
public class Csrf {

	/** 表单隐藏字段名 */
	public static final String FIELD = "_csrf";
	/** session 属性名 */
	private static final String ATTR = "csrfToken";

	private static final SecureRandom RNG = new SecureRandom();

	/** 取得（必要时生成）当前会话的 CSRF token；会话不可用时返回空串 */
	public static String token(HttpSession session) {
		if (session == null) return "";
		try {
			Object t = session.getAttribute(ATTR);
			if (t instanceof String && ((String) t).length() > 0) {
				return (String) t;
			}
			byte[] buf = new byte[16];
			RNG.nextBytes(buf);
			StringBuilder sb = new StringBuilder(32);
			for (byte b : buf) sb.append(String.format("%02x", b));
			String v = sb.toString();
			session.setAttribute(ATTR, v);
			return v;
		} catch (IllegalStateException e) {
			// 会话已失效（如登录页主动 invalidate 之后）
			return "";
		}
	}

	/** 校验本次请求携带的 token 是否与会话中的一致 */
	public static boolean verify(HttpServletRequest req) {
		if (req == null) return false;
		HttpSession session = req.getSession(false);
		if (session == null) return false;
		String expect;
		try {
			Object t = session.getAttribute(ATTR);
			if (!(t instanceof String) || ((String) t).length() == 0) return false;
			expect = (String) t;
		} catch (IllegalStateException e) {
			return false;
		}
		String got = req.getParameter(FIELD);
		if (got == null || got.length() == 0) return false;
		return constantTimeEquals(expect, got);
	}

	/** 常量时间比较，避免通过响应时间猜测 token */
	private static boolean constantTimeEquals(String a, String b) {
		if (a == null || b == null || a.length() != b.length()) return false;
		int diff = 0;
		for (int i = 0; i < a.length(); i++) {
			diff |= a.charAt(i) ^ b.charAt(i);
		}
		return diff == 0;
	}
}

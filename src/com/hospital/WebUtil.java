package com.hospital;

/** 前端输出转义工具：防止把用户输入原样回显进 HTML 造成 XSS。 */
public class WebUtil {

	/** HTML 属性/正文安全转义 */
	public static String htmlEscape(String s) {
		if (s == null) return "";
		StringBuilder sb = new StringBuilder(s.length() + 16);
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			switch (c) {
				case '<':  sb.append("&lt;");   break;
				case '>':  sb.append("&gt;");   break;
				case '"':  sb.append("&quot;"); break;
				case '\'': sb.append("&#39;");  break;
				case '&':  sb.append("&amp;");  break;
				default:
					if (c < 0x20 && c != '\n' && c != '\r' && c != '\t') {
						// 控制字符丢弃
					} else {
						sb.append(c);
					}
			}
		}
		return sb.toString();
	}

	/** JS 字符串字面量安全转义（用于 var x = '<%=...%>'; 场景） */
	public static String jsEscape(String s) {
		if (s == null) return "";
		StringBuilder sb = new StringBuilder(s.length() + 16);
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			switch (c) {
				case '\\': sb.append("\\\\"); break;
				case '"':  sb.append("\\\""); break;
				case '\'': sb.append("\\'"); break;
				case '\n': sb.append("\\n"); break;
				case '\r': sb.append("");    break;
				case '<':  sb.append("\\u003c"); break; // 防 </script> 逃逸
				case '>':  sb.append("\\u003e"); break;
				default:   sb.append(c);
			}
		}
		return sb.toString();
	}
}

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.io.*,com.hospital.*" %>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>
<html>
<head><meta charset="UTF-8"><title>登录问题诊断</title></head>
<body style="font-family:'Microsoft YaHei';font-size:14px;line-height:2;padding:20px;">
<h2>登录问题自动诊断</h2>

<h3>① 检查 Tomcat 里实际运行的 check_login.jsp 是新是旧</h3>
<%
String path = application.getRealPath("/check_login.jsp");
out.print("实际文件路径：" + path + "<br>");
boolean hasConvert = false;
try {
    BufferedReader br = new BufferedReader(new InputStreamReader(new FileInputStream(path), "UTF-8"));
    String line;
    while ((line = br.readLine()) != null) {
        if (line.contains("DataFormat")) { hasConvert = true; break; }
    }
    br.close();
} catch (Exception e) {
    out.print("<span style='color:red'>读取失败：" + e.getMessage() + "</span><br>");
}
if (hasConvert) {
    out.print("<span style='color:red;font-weight:bold'>❌ 还包含旧编码转换 DataFormat → Tomcat 里跑的是旧版！请重新下载 check_login.jsp 覆盖到 WebRoot，再 xcopy 部署。</span><br>");
} else {
    out.print("<span style='color:green;font-weight:bold'>✓ 已是新版（不含 DataFormat），继续看下面</span><br>");
}
%>

<h3>② 检查数据库实际存的账号数据（JDBC 读出来的）</h3>
<%
ResultSet rs = db.executeQuery("SELECT id, loginname, HEX(loginname), loginpwd, usertype FROM loginuser");
while (rs != null && rs.next()) {
    out.print("id=" + rs.getInt(1)
        + " | loginname=" + rs.getString(2)
        + " | HEX=" + rs.getString(3)
        + " | pwd=" + rs.getString(4)
        + " | " + rs.getString(5) + "<br>");
}
if (rs != null) rs.close();
%>
<p style="color:#888">说明：HEX 应为 61646D696E(admin)、D5C5D2BDC9FA(张医生)、C0EEB2A1C8CB(李病人)。</p>

<h3>③ 用 JDBC 实际模拟一次登录查询</h3>
<%
String sql = "SELECT id, usertype FROM loginuser WHERE loginname='李病人' AND loginpwd='123456'";
ResultSet rs2 = db.executeQuery(sql);
boolean ok = (rs2 != null && rs2.next());
if (ok) {
    out.print("<span style='color:green;font-weight:bold'>✓ 查询成功！数据库和 JDBC 链路完全正常。</span><br>");
    out.print("→ 问题只剩浏览器表单提交或部署缓存：请用 Ctrl+F5 强刷登录页重试，或换一个浏览器试。<br>");
    out.print("→ 另外请确认登录时输入的验证码正确（验证码错误会跳到另一个提示）。<br>");
} else {
    out.print("<span style='color:red;font-weight:bold'>❌ JDBC 查询不到！说明连接编码与表不匹配。</span><br>");
    out.print("→ 把本页完整截图发给客服，需要检查 Dbcoon.java 的 characterEncoding 参数与数据库字符集。<br>");
}
if (rs2 != null) rs2.close();
db.close();
%>

<hr>
<p style="color:#888">诊断完毕后可删除本文件（diagnose.jsp）。</p>
</body>
</html>

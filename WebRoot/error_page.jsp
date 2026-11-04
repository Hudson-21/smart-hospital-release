<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%
    /* 统一错误页：web.xml 的 error-page 指向本页。
       注意：绝不把 exception 的堆栈/消息输出到页面，避免泄露路径与实现细节。 */
    String code = "500";
    Object sc = request.getAttribute("javax.servlet.error.status_code");
    if (sc != null) code = String.valueOf(sc);

    String title = "服务暂时不可用";
    String hint  = "请稍后重试；若持续出现，请联系系统管理员。";

    if ("404".equals(code)) {
        title = "页面不存在";
        hint  = "您访问的地址可能已失效或输入有误，请检查后重试。";
    } else if ("403".equals(code)) {
        title = "无访问权限";
        hint  = "当前登录账号没有查看该内容的权限。";
    } else if ("400".equals(code)) {
        title = "请求格式有误";
        hint  = "提交的数据不完整或格式不正确，请返回后重新操作。";
    } else if ("405".equals(code)) {
        title = "请求方式不被支持";
        hint  = "请通过页面上的正常入口进行操作。";
    }

    String ctx = request.getContextPath();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%=code%> · <%=title%></title>
<style>
    * { margin:0; padding:0; box-sizing:border-box; }
    body {
        font-family:"Microsoft YaHei","PingFang SC",Arial,sans-serif;
        min-height:100vh; display:flex; align-items:center; justify-content:center;
        background:#f3f6fb; color:#4a4d55;
    }
    .box {
        background:#fff; border-radius:14px; padding:44px 52px; text-align:center;
        box-shadow:0 6px 28px rgba(25,118,210,.10); max-width:520px;
    }
    .code { font-size:56px; font-weight:600; color:#03A8F6; line-height:1; }
    h1 { font-size:20px; font-weight:600; margin:16px 0 10px; color:#263238; }
    p  { font-size:14px; line-height:1.8; color:#78909c; }
    .acts { margin-top:26px; display:flex; gap:12px; justify-content:center; }
    a,button {
        font-size:14px; padding:9px 22px; border-radius:8px; cursor:pointer;
        text-decoration:none; border:1px solid #d5dde6; background:#fff; color:#546e7a;
        font-family:inherit;
    }
    a.primary { background:#03A8F6; border-color:#03A8F6; color:#fff; }
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
</head>
<body class="h-business">
<div class="box">
    <div class="code"><%=code%></div>
    <h1><%=title%></h1>
    <p><%=hint%></p>
    <div class="acts">
        <a class="primary" href="<%=ctx%>/index.jsp">返回首页</a>
        <a href="javascript:history.back()">返回上一页</a>
    </div>
</div>
</body>
</html>

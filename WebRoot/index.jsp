<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
/* 禁止浏览器缓存主框架页：
   左侧菜单是在本页 JS 里按角色动态生成的，浏览器一旦缓存旧版本，
   即使改了菜单代码页面也不会变（"改了没生效"的假象多源于此）。 */
response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);

// ============ 登录校验 ============
String loginname = (String) session.getAttribute("loginname");
String usertype  = (String) session.getAttribute("usertype");
if (loginname == null || "".equals(loginname)) {
    response.sendRedirect("login.jsp");
    return;
}
// ============ 角色归一化（兼容中英文） ============
String role = "admin";
if ("医生".equals(usertype) || "doctor".equalsIgnoreCase(usertype)) role = "doctor";
else if ("病人".equals(usertype) || "patient".equalsIgnoreCase(usertype)) role = "patient";
String roleCn = "admin".equals(role) ? "管理员" : ("doctor".equals(role) ? "医生" : "病人");
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>智能化医院管理系统</title>


<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-shell.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<script src="<%=request.getContextPath()%>/js/hospital-shell.js?v=20261103" defer></script>
</head>
<body class="h-shell">

<!-- ============ 左侧菜单 ============ -->
<div class="sidebar" id="sidebar">
    <div class="logo">
        <span class="icon" data-icon="hospital"></span>
        <span class="txt">医院管理系统<small>HOSPITAL MANAGEMENT</small></span>
    </div>
    <div class="nav" id="nav"></div>
    <div class="side-footer"><span data-icon="shield"></span>医院业务管理平台</div>
</div>

<!-- ============ 右侧主体 ============ -->
<div class="main">
    <div class="topbar">
        <button class="btn-fold" id="btnFold" title="收起/展开菜单" aria-label="收起或展开导航" type="button"><span data-icon="menu"></span></button>
        <span class="page-title" id="pageTitle">工作台</span>
        <span class="spacer"></span>
        <div class="user-box">
            <div class="avatar" data-icon="user"></div>
            <span class="user-name"><%= com.hospital.WebUtil.htmlEscape(loginname) %></span>
            <span class="role-badge role-<%= role %>"><%= roleCn %></span>
            <a class="btn-logout" href="login.jsp">退出登录</a>
        </div>
    </div>
    <div class="content">
        <iframe name="main" id="mainFrame" title="业务内容" src="right.jsp"></iframe>
    </div>
</div>

<script>
/* ============ 按角色生成菜单（与原 left.jsp 功能一致） ============ */
var MENUS = [
<% if ("admin".equals(role)) { %>
    { name:'医生管理', icon:'👨‍⚕️', items:[
        { n:'医生信息查询', u:'doctor/list_user.jsp' },
        { n:'医生信息添加', u:'doctor/adduser.jsp' }
    ]},
    { name:'病床管理', icon:'🛏️', items:[
        { n:'病床信息查询', u:'bed/list_bed.jsp' },
        { n:'病床信息添加', u:'bed/addbed.jsp' }
    ]},
    { name:'病人管理', icon:'🧑‍🤝‍🧑', items:[
        { n:'病人信息查询', u:'patient/list_patient.jsp' },
        { n:'病人信息添加', u:'patient/addpatient.jsp' }
    ]},
    { name:'收费管理', icon:'💰', items:[
        { n:'收费信息查询', u:'cost/list_cost.jsp' },
        { n:'收费信息添加', u:'cost/addcost.jsp' }
    ]},
    { name:'挂号管理', icon:'📋', items:[
        { n:'挂号记录管理', u:'guahao/list_guahao.jsp' }
    ]},
    { name:'处方管理', icon:'💊', items:[
        { n:'处方列表', u:'chufang/list_chufang.jsp' }
    ]},
    { name:'统计分析', icon:'📊', items:[
        { n:'病床利用率查询', u:'query/list_bedinfo.jsp' },
        { n:'收费明细查询', u:'query/list_costinfo.jsp' },
        { n:'数据看板', u:'stats/dashboard.jsp' }
    ]},
    { name:'智能服务', icon:'🤖', items:[
        { n:'智能导诊', u:'ai/ask.jsp' }
    ]},
<% } else if ("doctor".equals(role)) { %>
    { name:'我的工作台', icon:'🩺', items:[
        { n:'我的档案', u:'doctor/my_info.jsp' },
        { n:'我的病人', u:'doctor/my_patient.jsp' },
        { n:'我的病人费用', u:'doctor/my_cost.jsp' },
        { n:'我的接诊', u:'doctor/my_guahao.jsp' },
        { n:'我的病历', u:'doctor/my_bingli.jsp' }
    ]},
    { name:'处方管理', icon:'💊', items:[
        { n:'开方开药', u:'doctor/add_chufang.jsp' },
        { n:'我的处方', u:'chufang/list_chufang.jsp' }
    ]},
    { name:'智能服务', icon:'🤖', items:[
        { n:'智能导诊', u:'ai/ask.jsp' }
    ]},
<% } else { %>
    { name:'个人中心', icon:'🏠', items:[
        { n:'我的信息', u:'patient/my_info.jsp' },
        { n:'我的费用', u:'patient/my_cost.jsp' },
        { n:'我要挂号', u:'patient/guahao.jsp' },
        { n:'我的挂号', u:'patient/my_guahao.jsp' },
        { n:'我的病历', u:'patient/my_bingli.jsp' },
        { n:'智能导诊', u:'ai/ask.jsp' }
    ]},
<% } %>
    { name:'系统管理', icon:'⚙️', items:[
<% if ("admin".equals(role)) { %>
        { n:'账号权限管理', u:'doctor/role_manage.jsp' },
<% } %>
        { n:'修改密码', u:'pwd.jsp' }
    ]}
];

</script>
</body>
</html>

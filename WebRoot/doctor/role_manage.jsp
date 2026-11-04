<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
/* ============================================================================
 *  账号权限管理（仅管理员）
 * ----------------------------------------------------------------------------
 *  原先角色是直接写在 loginuser.usertype 里、没有任何界面，改权限只能进数据库。
 *  本页提供：查看全部账号 / 修改角色 / 重置密码。
 *  安全约束：
 *    1. 仅管理员可访问（AuthFilter 白名单 + 本页二次校验）
 *    2. 不允许修改自己的角色（防止管理员误操作把自己踢出管理端）
 *    3. 不允许把系统里最后一个管理员降级（防止管理端彻底锁死）
 *    4. 角色取值走白名单，非法值一律忽略
 * ========================================================================== */
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可管理账号权限');history.back();</script>"); return;
}
request.setCharacterEncoding("UTF-8");

String msg = "", msgColor = "green";
/* 系统实际只支持这三种角色，与 AuthFilter.normalizeRole 的白名单严格一致。
   不要在这里加"普通用户"之类的自造角色 —— normalizeRole 认不出会返回 ROLE_UNKNOWN，
   该账号登录后将看不到任何菜单、访问业务页一律 403。 */
String[] ROLES = {"管理员", "医生", "病人"};

// ---------------- 处理提交 ----------------
if("POST".equals(request.getMethod())){
    String act = request.getParameter("act");
    String sid = request.getParameter("id");
    int id = 0;
    try{ id = Integer.parseInt(sid); }catch(Exception ignore){}

    if(id <= 0){
        msg = "参数不合法"; msgColor = "#c0392b";
    } else if("setrole".equals(act)){
        String role = request.getParameter("role");
        boolean roleOk = false;
        for(String r : ROLES){ if(r.equals(role)) roleOk = true; }
        if(!roleOk){
            msg = "角色取值不合法"; msgColor = "#c0392b";
        } else {
            // 取目标账号
            String targetName = null, targetRole = null;
            ResultSet rsT = a.executeQuery("SELECT loginname, usertype FROM loginuser WHERE id=?", id);
            if(rsT.next()){
                targetName = rsT.getString("loginname");
                targetRole = rsT.getString("usertype");
            }
            rsT.close();

            if(targetName == null){
                msg = "账号不存在"; msgColor = "#c0392b";
            } else if(targetName.equals(loginname)){
                msg = "不能修改自己的角色"; msgColor = "#c0392b";
            } else if("管理员".equals(targetRole) && !"管理员".equals(role)){
                // 最后一个管理员保护
                int adminCnt = 0;
                ResultSet rsC = a.executeQuery("SELECT COUNT(*) c FROM loginuser WHERE usertype='管理员'");
                if(rsC.next()) adminCnt = rsC.getInt("c");
                rsC.close();
                if(adminCnt <= 1){
                    msg = "系统必须至少保留一个管理员，操作已拒绝"; msgColor = "#c0392b";
                }
            }
            if("".equals(msg)){
                int n = a.executeUpdate("UPDATE loginuser SET usertype=? WHERE id=?", role, id);
                if(n > 0){
                    com.hospital.Audit.log(loginname, "修改角色", "账号 " + targetName + "：" + targetRole + " -> " + role);
                    msg = "账号「" + targetName + "」的角色已改为：" + role;
                } else {
                    msg = "更新失败"; msgColor = "#c0392b";
                }
            }
        }
    } else if("resetpwd".equals(act)){
        String targetName = null;
        ResultSet rsT = a.executeQuery("SELECT loginname FROM loginuser WHERE id=?", id);
        if(rsT.next()) targetName = rsT.getString("loginname");
        rsT.close();
        if(targetName == null){
            msg = "账号不存在"; msgColor = "#c0392b";
        } else {
            a.executeUpdate("UPDATE loginuser SET loginpwd=? WHERE id=?",
                            com.hospital.PasswordUtil.hash("123456"), id);
            com.hospital.Audit.log(loginname, "重置密码", "账号 " + targetName);
            msg = "账号「" + targetName + "」的密码已重置为 123456";
        }
    }
}

// ---------------- 读取账号列表 ----------------
ResultSet rs = a.executeQuery("SELECT id, loginname, loginpwd, usertype FROM loginuser ORDER BY id");
%>
<html>
<head>
<meta charset="UTF-8">
<link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" />
<title>账号权限管理</title>
<style type="text/css">
  .role-sel { font-size:13px; padding:2px 6px; }
  .btn { border:none; border-radius:4px; padding:3px 12px; font-size:12px; cursor:pointer;
         font-family:inherit; color:#fff; background:#03A8F6; }
  .btn.warn { background:#e67e22; }
  .btn:hover { opacity:.85; }
  .tag { display:inline-block; padding:1px 8px; border-radius:9px; font-size:12px; }
  .tag.admin   { background:#eaf3ff; color:#0c447c; }
  .tag.doctor  { background:#e6f7ef; color:#0f6e56; }
  .tag.patient { background:#fff4e5; color:#8a5300; }
  .tag.other   { background:#f1f1f1; color:#616161; }
  .msgbox { margin:0 0 12px 6px; font-size:13px; font-weight:bold; }
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">系统管理 &gt; 账号权限管理（当前账号：<%=com.hospital.WebUtil.htmlEscape(loginname)%>）</td></tr>
</table>

<% if(!"".equals(msg)){ %>
<div class="msgbox" style="color:<%=msgColor%>;">ℹ <%=com.hospital.WebUtil.htmlEscape(msg)%></div>
<% } %>

<table width="90%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5">
<tr style="background:#d0e6ff;">
<th width="8%">ID</th><th width="22%">登录账号</th><th width="16%">当前角色</th>
<th width="12%">密码状态</th><th width="42%">操作</th>
</tr>
<%
while(rs.next()){
    int rid = rs.getInt("id");
    String rname = rs.getString("loginname");
    String rpwd  = rs.getString("loginpwd");
    String rtype = rs.getString("usertype")==null?"":rs.getString("usertype");

    String tagCls = "other";
    if("管理员".equals(rtype))      tagCls = "admin";
    else if("医生".equals(rtype))   tagCls = "doctor";
    else if("病人".equals(rtype) || "patient".equalsIgnoreCase(rtype)) tagCls = "patient";

    boolean hashed = com.hospital.PasswordUtil.isHashed(rpwd);
    boolean isSelf = rname != null && rname.equals(loginname);
%>
<tr>
<td align="center"><%=rid%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(rname)%><% if(isSelf){ %> <span style="color:#95a5a6;font-size:12px;">(当前登录)</span><% } %></td>
<td align="center"><span class="tag <%=tagCls%>"><%=com.hospital.WebUtil.htmlEscape(rtype)%></span></td>
<td align="center">
    <span style="font-size:12px;color:<%=hashed?"#27ae60":"#e67e22"%>;">
        <%=hashed?"已哈希 ✓":"明文（待迁移）"%>
    </span>
</td>
<td align="center">
<% if(isSelf){ %>
    <span style="color:#b0bec5;font-size:12px;">不能修改自己的角色</span>
<% } else { %>
    <form action="role_manage.jsp" method="post" style="display:inline;margin:0"
          onsubmit="return confirm('确认修改该账号的角色？');">
        <input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
        <input type="hidden" name="act" value="setrole">
        <input type="hidden" name="id" value="<%=rid%>">
        <select name="role" class="role-sel">
<%
    // 若当前角色不在白名单内（历史脏数据），先给出一个只读提示项，
    // 避免下拉默认落到"管理员"、管理员一点就把人改成管理员。
    boolean known = false;
    for(String r : ROLES){ if(r.equals(rtype)){ known = true; break; } }
    if(!known){
%>
            <option value="" selected><%=com.hospital.WebUtil.htmlEscape(rtype)%>（当前值 · 系统未识别）</option>
<%
    }
    for(String r : ROLES){
        String sel = r.equals(rtype) ? " selected" : "";
%>
            <option value="<%=r%>"<%=sel%>><%=r%></option>
<%
    }
%>
        </select>
        <button type="submit" class="btn">改角色</button>
    </form>
<% } %>
    <form action="role_manage.jsp" method="post" style="display:inline;margin-left:8px;"
          onsubmit="return confirm('确认把该账号密码重置为 123456？');">
        <input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
        <input type="hidden" name="act" value="resetpwd">
        <input type="hidden" name="id" value="<%=rid%>">
        <button type="submit" class="btn warn">重置密码</button>
    </form>
</td>
</tr>
<%
}
a.close();
%>
</table>
<p style="font-size:12px;color:#888;margin-left:6px;">
    说明：重置密码后统一为 <b>123456</b>，请提醒用户首次登录后立即修改。角色变更即时生效，对方下次访问时按新角色鉴权。
</p>
</td></tr></table>
</body>
</html>

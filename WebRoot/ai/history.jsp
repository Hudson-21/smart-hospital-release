<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
request.setCharacterEncoding("UTF-8");
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}

// ===== 角色权限分层 =====
// 病人：只能看自己的（隐私保护）
// 医生：可查看全部用户的记录（接诊参考：病人描述过什么症状、被推荐过什么科室）
// 管理员：可查看全部用户的记录 + 按用户/类型筛选（审计）
boolean isAdmin = "管理员".equals(usertype) || "admin".equalsIgnoreCase(usertype);
boolean isDoctor = "医生".equals(usertype) || "doctor".equalsIgnoreCase(usertype);
boolean canSeeAll = isAdmin || isDoctor;

// ===== 筛选参数（仅医生/管理员可用） =====
String q = request.getParameter("q");            // 按用户名筛选
if(q==null) q="";
q = q.trim();
String type = request.getParameter("type");      // 记录类型筛选
if(type==null) type="all";

// ===== 组装查询条件（参数化，防注入） =====
StringBuilder where = new StringBuilder();
java.util.List<Object> cnd = new java.util.ArrayList<Object>();
if(canSeeAll){
    if(!q.isEmpty()){
        where.append(" AND loginname LIKE ?");
        cnd.add("%" + q + "%");
    }
    if("chat".equals(type)){
        where.append(" AND role IN ('user','assistant')");
    } else if("aihelper".equals(type)){
        where.append(" AND role IN ('病历草稿','病历质控')");
    } else if("explain".equals(type)){
        where.append(" AND role = '病历解读'");
    } else if("stats".equals(type)){
        where.append(" AND role = '统计查询'");
    }
    where.insert(0," WHERE 1=1 ");
} else {
    where.append(" WHERE loginname=?");
    cnd.add(loginname);
}
String sql = "SELECT loginname,role,content,dept,ctime FROM ai_chat" + where.toString()
           + " ORDER BY ctime DESC, id DESC LIMIT 200";
ResultSet rs = a.executeQuery(sql, cnd.toArray());
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title><%=canSeeAll?(isAdmin?"问诊记录审计":"问诊记录（全科可见）"):"我的问诊记录"%></title>
<style>
  body{font-family:"PingFang SC","Microsoft YaHei",sans-serif;background:#f5f7fa;margin:0;padding:24px;color:#1f2023;}
  h2{font-size:18px;margin:0 0 4px;}
  .sub{color:#8b8fa3;font-size:13px;margin-bottom:14px;}
  .rec{max-width:760px;margin:0 auto;}
  .item{background:#fff;border:1px solid #ececf1;border-radius:12px;padding:12px 16px;margin-bottom:12px;}
  .item .meta{font-size:12px;color:#9aa0b0;margin-bottom:6px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
  .item.user .content{color:#1d4ed8;}
  .item.assistant .content{color:#1f2023;white-space:pre-wrap;line-height:1.7;}
  .item.other .content{color:#6d28d9;white-space:pre-wrap;line-height:1.7;}
  .tag{background:#eaf2ff;color:#2563eb;padding:1px 8px;border-radius:6px;}
  .who{background:#fff7ed;color:#ea580c;padding:1px 8px;border-radius:6px;font-weight:bold;}
  .back{display:inline-block;margin-bottom:14px;color:#2563eb;cursor:pointer;font-size:13px;text-decoration:none;}
  /* 筛选条（医生/管理员） */
  .filter{max-width:760px;margin:0 auto 16px;background:#fff;border:1px solid #ececf1;border-radius:12px;
    padding:12px 16px;display:flex;gap:10px;align-items:center;flex-wrap:wrap;}
  .filter .cap{font-size:13px;color:#666;}
  .filter input{border:1px solid #d9dce6;border-radius:8px;padding:7px 12px;font-size:13px;outline:none;width:180px;}
  .filter input:focus{border-color:#2563eb;}
  .filter select{border:1px solid #d9dce6;border-radius:8px;padding:7px 10px;font-size:13px;background:#fff;outline:none;}
  .filter button{background:#2563eb;color:#fff;border:none;border-radius:8px;padding:8px 20px;
    font-size:13px;cursor:pointer;}
  .filter button:hover{opacity:.9;}
  .filter .reset{color:#8b8fa3;font-size:13px;text-decoration:none;}
  .role-tag{padding:1px 8px;border-radius:6px;font-size:12px;}
  .role-chat{background:#eaf2ff;color:#2563eb;}
  .role-aihelper{background:#f3e8ff;color:#7c3aed;}
  .role-explain{background:#ecfdf5;color:#059669;}
  .role-stats{background:#fff7ed;color:#ea580c;}
  .limit-tip{max-width:760px;margin:0 auto;font-size:12px;color:#b0b3bd;text-align:center;padding:6px 0 20px;}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
</head>
<body class="h-business">
<a class="back" href="javascript:history.back()">← 返回</a>
<h2><%=canSeeAll?(isAdmin?"问诊记录审计（全员）":"问诊记录（全员，接诊参考）"):"我的问诊记录"%></h2>
<%if(canSeeAll){%>
<div class="sub">当前角色：<%=isAdmin?"管理员（审计视角）":"医生（接诊参考视角）"%> · 可查看全体用户的 AI 记录，含导诊对话、病历助手、病历解读、统计查询</div>
<%}else{%>
<div class="sub">账户：<%=loginname%> · 以下为「小医」智能导诊的问答留存（服务端存储，可追溯）</div>
<%}%>

<%if(canSeeAll){%>
<form class="filter" method="get" action="history.jsp">
  <span class="cap">按用户筛选：</span>
  <input type="text" name="q" value="<%=q.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\"","&quot;")%>" placeholder="输入登录名，如：李病人"/>
  <span class="cap">类型：</span>
  <select name="type">
    <option value="all" <%="all".equals(type)?"selected":""%>>全部类型</option>
    <option value="chat" <%="chat".equals(type)?"selected":""%>>导诊对话</option>
    <option value="aihelper" <%="aihelper".equals(type)?"selected":""%>>病历助手（草稿/质控）</option>
    <option value="explain" <%="explain".equals(type)?"selected":""%>>病历解读</option>
    <option value="stats" <%="stats".equals(type)?"selected":""%>>统计查询</option>
  </select>
  <button type="submit">筛选</button>
  <a class="reset" href="history.jsp">重置</a>
</form>
<%}%>

<div class="rec">
<%
boolean has=false;
while(rs!=null && rs.next()){
  has=true;
  String who = rs.getString("loginname");
  if(who==null) who="";
  String role=rs.getString("role");
  String content=rs.getString("content"); if(content==null) content="";
  content = content.replace("&","&amp;").replace("<","&lt;").replace(">","&gt;").replace("\n","<br>");
  String dept=rs.getString("dept");
  String ctime=rs.getString("ctime");

  // 记录类型归类：user/assistant 为导诊对话，其余为 AI 任务记录
  boolean isChat = "user".equals(role) || "assistant".equals(role);
  String cls = isChat ? ("user".equals(role)?"user":"assistant") : "other";
  String label = "user".equals(role)?(canSeeAll?who+"（患者提问）":"我")
              : ("assistant".equals(role)?"小医":role);
  // 类型徽标
  String tagCls = isChat?"role-chat":("统计查询".equals(role)?"role-stats":("病历解读".equals(role)?"role-explain":"role-aihelper"));
%>
  <div class="item <%=cls%>">
    <div class="meta">
      <span><%=com.hospital.WebUtil.htmlEscape(label)%></span>
      <span><%=com.hospital.WebUtil.htmlEscape(ctime)%></span>
      <span class="role-tag <%=tagCls%>"><%=isChat?"导诊对话":com.hospital.WebUtil.htmlEscape(role)%></span>
      <%if(dept!=null&&!dept.isEmpty()){%><span class="tag">推荐科室：<%=com.hospital.WebUtil.htmlEscape(dept)%></span><%}%>
      <%if(canSeeAll && isChat && "assistant".equals(role)){%><span class="who">用户：<%=com.hospital.WebUtil.htmlEscape(who)%></span><%}%>
    </div>
    <div class="content"><%=content%></div>
  </div>
<%
}
if(!has){
%>
  <div class="item"><div class="content" style="color:#9aa0b0">没有符合条件的记录。</div></div>
<%
}
a.close();
%>
</div>
<%if(canSeeAll){%><div class="limit-tip">最多显示最近 200 条，可用上方筛选缩小范围</div><%}%>
</body>
</html>

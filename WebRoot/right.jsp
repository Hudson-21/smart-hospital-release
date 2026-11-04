<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,com.hospital.*" %>
<%!
private String homeText(String value) { return WebUtil.htmlEscape(value == null ? "" : value); }
private String homeCount(Connection con, String sql, String name) throws SQLException {
    try (PreparedStatement statement = con.prepareStatement(sql)) {
        if (name != null) statement.setString(1, name);
        try (ResultSet result = statement.executeQuery()) { return result.next() ? result.getString(1) : "0"; }
    }
}
%>
<%
String loginname = (String)session.getAttribute("loginname");
String usertype = (String)session.getAttribute("usertype");
if(loginname == null || loginname.isEmpty()) { response.sendRedirect("login.jsp"); return; }
if(!"管理员".equals(usertype) && !"admin".equalsIgnoreCase(usertype) &&
   !"医生".equals(usertype) && !"doctor".equalsIgnoreCase(usertype) &&
   !"病人".equals(usertype) && !"patient".equalsIgnoreCase(usertype)) {
    response.sendError(403); return;
}
String role = ("医生".equals(usertype) || "doctor".equalsIgnoreCase(usertype)) ? "doctor" :
    (("病人".equals(usertype) || "patient".equalsIgnoreCase(usertype)) ? "patient" : "admin");
boolean admin = "admin".equals(role), doctor = "doctor".equals(role);
String roleCn = admin ? "管理员" : (doctor ? "医生" : "患者");
SimpleDateFormat dayFormat = new SimpleDateFormat("yyyy-MM-dd");
dayFormat.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
String today = dayFormat.format(new java.util.Date());
SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy年M月d日 · EEEE",Locale.CHINA);
dateFormat.setTimeZone(TimeZone.getTimeZone("Asia/Shanghai"));
String dateLabel = dateFormat.format(new java.util.Date());
String[] labels = admin ? new String[]{"今日挂号","今日待接诊","可用床位","在册患者"} :
    (doctor ? new String[]{"今日预约","今日待接诊","我的患者","我的病历"} : new String[]{"我的预约","待就诊预约","我的病历","费用记录"});
String[] notes = admin ? new String[]{"按就诊日期统计","今日尚未接诊","状态为空闲的床位","全院患者档案"} :
    (doctor ? new String[]{"分配给您的今日预约","今日尚未接诊","由您负责的患者","您已书写的病历"} : new String[]{"全部挂号记录","今日及以后的待接诊记录","医生为您书写的病历","您的收费明细记录"});
String[] values = new String[]{"—","—","—","—"};
String[] metricIcons = new String[]{"calendar","clock",admin?"bed":(doctor?"users":"file"),admin?"users":(doctor?"file":"wallet")};
String listUrl = admin ? "guahao/list_guahao.jsp" : (doctor ? "doctor/my_guahao.jsp" : "patient/my_guahao.jsp");
String scope = admin ? "" : (doctor ? " WHERE doctor=?" : " WHERE name=?");
String owner = admin ? null : loginname;
List<String[]> recent = new ArrayList<String[]>();
List<String[]> departments = new ArrayList<String[]>();
int departmentMax = 1;
boolean dataAvailable = true;
try {
    Dbcoon db = new Dbcoon();
    synchronized(Dbcoon.class) {
        Connection con = db.getConnection();
        if(con == null) throw new SQLException("Connection unavailable");
        String dateFilter = (admin ? " WHERE " : " AND ") + "riqi='"+today+"'";
        if(admin || doctor) {
            values[0] = homeCount(con,"SELECT COUNT(*) FROM guahao"+scope+dateFilter,owner);
            values[1] = homeCount(con,"SELECT COUNT(*) FROM guahao"+scope+dateFilter+" AND state='待接诊'",owner);
            values[2] = admin ? homeCount(con,"SELECT COUNT(*) FROM bed WHERE state IN ('空','空闲')",null) : homeCount(con,"SELECT COUNT(*) FROM patient WHERE doctor=?",loginname);
            values[3] = admin ? homeCount(con,"SELECT COUNT(*) FROM patient",null) : homeCount(con,"SELECT COUNT(*) FROM bingli WHERE doctor=?",loginname);
        } else {
            values[0] = homeCount(con,"SELECT COUNT(*) FROM guahao WHERE name=?",loginname);
            values[1] = homeCount(con,"SELECT COUNT(*) FROM guahao WHERE name=? AND riqi>='"+today+"' AND state='待接诊'",loginname);
            values[2] = homeCount(con,"SELECT COUNT(*) FROM bingli WHERE patientname=?",loginname);
            values[3] = homeCount(con,"SELECT COUNT(*) FROM cost WHERE name=?",loginname);
        }
        try(PreparedStatement statement = con.prepareStatement("SELECT number,name,kebie,doctor,riqi,state FROM guahao"+scope+" ORDER BY id DESC LIMIT 6")) {
            if(owner != null) statement.setString(1,owner);
            try(ResultSet rs = statement.executeQuery()) {
                while(rs.next()) recent.add(new String[]{rs.getString(1),rs.getString(2),rs.getString(3),rs.getString(4),rs.getString(5),rs.getString(6)});
            }
        }
        if(admin) {
            try(PreparedStatement statement = con.prepareStatement("SELECT COALESCE(kebie,'未分科'),COUNT(*) AS amount FROM guahao GROUP BY kebie ORDER BY amount DESC LIMIT 4"); ResultSet rs = statement.executeQuery()) {
                while(rs.next()) { int count=rs.getInt(2); departmentMax=Math.max(departmentMax,count); departments.add(new String[]{rs.getString(1),String.valueOf(count)}); }
            }
        }
    }
} catch(Exception error) {
    dataAvailable=false; Arrays.fill(values,"—"); recent.clear(); departments.clear();
    application.log("Unable to load homepage summary",error);
}
String[][] actions = admin ? new String[][]{
    {"users","患者查询","查询与维护患者档案","patient/list_patient.jsp"},
    {"hospital","医生管理","医生信息与人员档案","doctor/list_user.jsp"},
    {"bed","床位管理","查看床位与使用状态","bed/list_bed.jsp"},
    {"wallet","收费查询","核对收费明细记录","cost/list_cost.jsp"}
} : (doctor ? new String[][]{
    {"users","我的患者","查看您负责的患者","doctor/my_patient.jsp"},
    {"calendar","我的接诊","查看预约与接诊记录","doctor/my_guahao.jsp"},
    {"file","病历管理","查看与书写电子病历","doctor/my_bingli.jsp"},
    {"file","开方开药","为患者开具处方","doctor/add_chufang.jsp"}
} : new String[][]{
    {"calendar","预约挂号","选择科室、医生与日期","patient/guahao.jsp"},
    {"file","我的病历","查看诊断与就诊记录","patient/my_bingli.jsp"},
    {"wallet","我的费用","查看个人收费明细","patient/my_cost.jsp"},
    {"chat","智能导诊","根据症状了解就诊科室","ai/ask.jsp"}
});
%>
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>工作台</title>
<link rel="stylesheet" href="css/hospital-ui.css?v=20261104"><link rel="stylesheet" href="css/hospital-home.css?v=20261104"><script src="js/hospital-ui.js?v=20261103" defer></script>
</head><body class="h-home"><main class="home">
<div class="home-head"><div><h1><%=admin?"工作台":(doctor?"医生工作台":"就诊服务")%></h1><p><%=homeText(loginname)%>，<%=admin?"及时掌握接诊与资源使用情况。":(doctor?"查看今日预约，开始您的诊疗工作。":"在这里管理您的预约、病历与费用。")%></p></div><div class="home-date"><span data-icon="calendar"></span><%=homeText(dateLabel)%></div></div>
<% if(!dataAvailable) { %><div class="home-error" role="status">暂时无法读取业务数据，请稍后刷新。您仍可通过下方入口使用各项功能。</div><% } %>
<section class="metrics" aria-label="业务数据概览"><% for(int i=0;i<4;i++) { %><div class="metric"><div class="metric-label"><%=labels[i]%><span data-icon="<%=metricIcons[i]%>"></span></div><div class="metric-value"><%=homeText(values[i])%></div><div class="metric-note"><%=notes[i]%></div></div><% } %></section>
<div class="home-columns"><section class="home-panel"><div class="home-panel-header"><div><h2><%=admin?"最近挂号":(doctor?"最近接诊预约":"我的最近预约")%></h2><p class="home-subtitle">按挂号记录创建顺序展示</p></div><a class="home-link" href="<%=listUrl%>" data-navigate>全部记录 →</a></div>
<div class="home-scroll" tabindex="0" role="region" aria-label="挂号记录，可横向滚动"><table class="home-table"><thead><tr><th>挂号编号</th><th>患者</th><th>科室</th><th>接诊医生</th><th>就诊日期</th><th>状态</th></tr></thead><tbody>
<% for(String[] row:recent) { String statusClass="已接诊".equals(row[5])?"done":("待接诊".equals(row[5])?"waiting":""); %><tr><% for(int i=0;i<5;i++) { %><td><%=homeText(row[i])%></td><% } %><td><span class="home-status <%=statusClass%>"><%=homeText(row[5])%></span></td></tr><% } %>
<% if(recent.isEmpty()) { %><tr><td colspan="6" class="home-empty"><strong><%=dataAvailable?"暂无挂号记录":"数据暂不可用"%></strong><%=dataAvailable?"新的预约会显示在这里。":"请稍后刷新，或进入记录页面查看。"%></td></tr><% } %>
</tbody></table></div><div class="home-table-footer"><span>最近 <%=recent.size()%> 条记录</span><a class="home-link" href="<%=listUrl%>" data-navigate><%=doctor?"进入接诊管理":"查看挂号记录"%> →</a></div></section>
<section class="home-panel"><div class="home-panel-header"><h2>常用操作</h2><span class="home-subtitle">快捷入口</span></div><div class="home-actions"><% for(String[] action:actions) { %><a class="home-action" href="<%=action[3]%>" data-navigate><span data-icon="<%=action[0]%>"></span><div><strong><%=action[1]%></strong><small><%=action[2]%></small></div><span class="home-arrow">›</span></a><% } %></div><div class="home-note"><%=admin?"统计信息根据现有业务记录实时读取，今日数据按就诊日期计算。":(doctor?"工作台仅展示分配给您的预约，以及由您负责的患者信息。":"请按预约日期就诊。智能导诊仅提供就诊参考，不能替代医生诊断。")%></div></section></div>
<section class="home-panel home-bottom"><div class="home-panel-header"><h2><%=admin?"科室挂号概览":"就诊与诊疗服务"%></h2><% if(admin) { %><a class="home-link" href="stats/dashboard.jsp" data-navigate>详细统计 →</a><% } else { %><a class="home-link" href="ai/ask.jsp" data-navigate>智能导诊 →</a><% } %></div>
<% if(admin) { %><div class="home-depts"><% for(String[] dept:departments) { int width=(int)Math.round(Integer.parseInt(dept[1])*100.0/departmentMax); %><div><div class="home-dept-label"><span><%=homeText(dept[0])%></span><span><%=homeText(dept[1])%> 人次</span></div><div class="home-track"><div class="home-fill" style="width:<%=width%>%"></div></div></div><% } %><% if(departments.isEmpty()) { %><div class="home-subtitle">暂无科室统计数据</div><% } %></div><% } else { %><div class="home-flow"><% for(int i=0;i<3;i++) { %><a href="<%=actions[i][3]%>" data-navigate><span><%=i+1%></span><%=actions[i][1]%></a><% } %></div><% } %>
</section><footer class="home-footer"><span>医院管理系统 · <%=roleCn%>工作台</span><span><%=admin?"科室概览为累计挂号量，展示前四个科室":"个人信息仅用于本系统就诊与诊疗服务"%></span></footer>
</main><script>
document.addEventListener('click',function(event){
    var link=event.target.closest('a[data-navigate]');
    if(!link || event.ctrlKey || event.metaKey || event.shiftKey || event.altKey || event.button!==0)return;
    try{if(parent!==window && typeof parent.HospitalNavigate==='function' && parent.HospitalNavigate(link.getAttribute('href')))event.preventDefault();}catch(e){}
});
</script></body></html>

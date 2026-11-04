<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,java.text.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
// 登录 + 角色校验：只有病人能挂号
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"病人".equals(usertype) && !"patient".equalsIgnoreCase(usertype)){out.print("<script>alert('只有病人角色可以挂号');history.back();</script>");return;}

String presetDept = request.getParameter("dept");

String msg = "";
if("POST".equals(request.getMethod())){
    request.setCharacterEncoding("UTF-8");
    String kebie = request.getParameter("kebie");
    String doctor= request.getParameter("doctor");
    String riqi  = request.getParameter("riqi");
    String shift = request.getParameter("shift");
    String phone = request.getParameter("phone");
    String beizhu= request.getParameter("beizhu");
    if(kebie==null||"".equals(kebie)||doctor==null||"".equals(doctor)
            ||riqi==null||"".equals(riqi.trim())||shift==null||"".equals(shift)){
        msg = "<span style='color:red'>请选择科室、医生、就诊日期与时段</span>";
    } else {
        java.sql.Date wd = null;
        try{ wd = java.sql.Date.valueOf(riqi.trim()); }catch(Exception ex){}
        if(wd == null){
            msg = "<span style='color:red'>就诊日期格式不正确</span>";
        } else {
            // ===== 号源闭环：按 doctor+date+shift 三维扣号，杜绝跨时段抢号 =====
            try{
                synchronized(com.hospital.Dbcoon.class){
                    java.sql.Connection cn = a.getConnection();
                    cn.setAutoCommit(false);
                    try{
                        java.sql.PreparedStatement ps1 = cn.prepareStatement(
                            "UPDATE paiban SET remain=remain-1 WHERE doctor_name=? AND work_date=? AND shift=? AND remain>0");
                        ps1.setString(1, doctor);
                        ps1.setDate(2, wd);
                        ps1.setString(3, shift);
                        int up = ps1.executeUpdate();
                        ps1.close();
                        if(up == 0){
                            cn.rollback();
                            // 扣号失败有两种原因，必须分开提示，否则用户会误以为"号满了"
                            boolean hasSched = false;
                            java.sql.PreparedStatement psC = cn.prepareStatement(
                                "SELECT COUNT(*) FROM paiban WHERE doctor_name=? AND work_date=? AND shift=?");
                            psC.setString(1, doctor);
                            psC.setDate(2, wd);
                            psC.setString(3, shift);
                            java.sql.ResultSet rsC = psC.executeQuery();
                            if(rsC.next() && rsC.getInt(1) > 0) hasSched = true;
                            rsC.close(); psC.close();
                            String shEsc = com.hospital.WebUtil.htmlEscape(shift);
                            msg = hasSched
                                ? "<span style='color:red'>该医生 "+shEsc+" 号源已约满，请更换时段或医生</span>"
                                : "<span style='color:red'>该医生在 "+com.hospital.WebUtil.htmlEscape(riqi.trim())+" "+shEsc
                                  +" 暂未排班，请更换日期或医生</span>";
                        } else {
                            String number = "GH" + System.currentTimeMillis();
                            java.sql.PreparedStatement ps2 = cn.prepareStatement(
                                "INSERT INTO guahao(number,name,kebie,doctor,riqi,state,phone,beizhu) VALUES(?,?,?,?,?,?,?,?)");
                            ps2.setString(1, number);
                            ps2.setString(2, loginname);
                            ps2.setString(3, kebie);
                            ps2.setString(4, doctor);
                            ps2.setString(5, riqi.trim());
                            ps2.setString(6, "待接诊");
                            ps2.setString(7, phone);
                            ps2.setString(8, beizhu);
                            ps2.executeUpdate();
                            ps2.close();
                            cn.commit();
                            msg = "<span style='color:green'>挂号成功（"+shift+"）！号源信息：流水号 " + number + "</span>";
                        }
                    }catch(Exception ex){
                        try{ cn.rollback(); }catch(Exception ignore){}
                        msg = "<span style='color:red'>挂号失败，请重试</span>";
                    }finally{
                        try{ cn.setAutoCommit(true); }catch(Exception ignore){}
                    }
                }
            }catch(Exception ex){
                msg = "<span style='color:red'>挂号失败，请重试</span>";
            }
        }
    }
}

// 读取医生列表
ResultSet rsd = a.executeQuery("SELECT name,kebie FROM doctor");
StringBuilder js = new StringBuilder();
while(rsd.next()){
    js.append("['").append(rsd.getString("name")==null?"":rsd.getString("name"))
      .append("','").append(rsd.getString("kebie")==null?"":rsd.getString("kebie")).append("'],");
}
if(js.length()>0) js.setLength(js.length()-1);
a.close();

// 给前端一个 paiban 字典：[医生, 日期, 时段, 剩余]，JS 用来按 doctor+date 查时段余量
// 由于实时性，我们直接给 JS 一个轻量字典：仅查未来 14 天
java.util.Date todayD = new java.util.Date();
SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
String fromDate = sdf.format(todayD);
// 暂存供下方 JSON
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>我要挂号</title>
<style>
.shift-cell{display:inline-block;padding:8px 14px;margin:3px;border:1px solid #ccc;border-radius:5px;cursor:pointer;background:#fff;}
.shift-cell.sel{background:#1976d2;color:#fff;border-color:#1976d2;}
.shift-cell.disabled{background:#f5f5f5;color:#aaa;cursor:not-allowed;}
.shift-cell .num{font-size:11px;display:block;margin-top:2px;}
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
<td width="98%" align="left" class="lan13b">个人中心 > 我要挂号（就诊人：<%=loginname%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" style="font-size:14px"><%=msg%></p><%}%>
<form method="post" action="guahao.jsp" name="f1" id="f1">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<input type="hidden" name="shift" id="shiftInp" value=""/>
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="28%" align="right" class="COLLECTION">选择科室：</td>
<td><select name="kebie" id="kebie" onchange="fillDoctor()" style="width:200px">
<option value="">--请选择--</option></select></td></tr>
<tr><td align="right" class="COLLECTION">选择医生：</td>
<td><select name="doctor" id="doctor" onchange="loadShift()" style="width:200px"><option value="">--请先选科室--</option></select></td></tr>
<tr><td align="right" class="COLLECTION">就诊日期：</td>
<td><input type="date" name="riqi" id="riqi" onchange="loadShift()" style="width:200px"/></td></tr>
<tr><td align="right" class="COLLECTION">选择时段：</td>
<td><span id="shiftBox" style="display:inline-block;color:#888;">请先选医生与日期</span></td></tr>
<tr><td align="right" class="COLLECTION">联系电话：</td>
<td><input type="text" name="phone" style="width:200px"/></td></tr>
<tr><td align="right" class="COLLECTION">备注：</td>
<td><input type="text" name="beizhu" style="width:200px"/></td></tr>
<tr><td colspan="2" align="center"><input type="submit" value="确认挂号" id="submitBtn" style="width:120px;height:28px"/></td></tr>
</table>
</form>
</td></tr></table>

<!-- 异步拉号源余量：医生+日期变化时由 JS 调用本 JSP，GET 参数 fetch=shift -->
<iframe name="dataframe" style="display:none"></iframe>

<script type="text/javascript">
var doctors = [<%=js.toString()%>];
var kebieSel = document.getElementById("kebie");
var doctorSel= document.getElementById("doctor");
var kb = [];
doctors.forEach(function(d){ if(kb.indexOf(d[1])<0) kb.push(d[1]); });
kb.forEach(function(k){ var o=document.createElement("option"); o.value=k; o.text=k; kebieSel.appendChild(o); });

var presetDept = "<%=com.hospital.WebUtil.jsEscape(presetDept)%>";
if(presetDept){ kebieSel.value = presetDept; fillDoctor(); }

function fillDoctor(){
  doctorSel.innerHTML = '<option value="">--请选择--</option>';
  doctors.forEach(function(d){
    if(d[1]==kebieSel.value){ var o=document.createElement("option"); o.value=d[0]; o.text=d[0]; doctorSel.appendChild(o); }
  });
  loadShift();
}

// 异步拉医生+日期对应的两个时段剩余号
function loadShift(){
  var doctor=doctorSel.value, date=document.getElementById("riqi").value;
  var box=document.getElementById("shiftBox");
  if(!doctor || !date){ box.innerHTML='<span style="color:#888;">请先选医生与日期</span>'; return; }
  box.innerHTML='<span style="color:#888;">查询中…</span>';
  var url="paiban_shift_api.jsp?doctor="+encodeURIComponent(doctor)+"&date="+encodeURIComponent(date)+"&t="+Date.now();
  var x=new XMLHttpRequest();
  x.open("GET",url,true);
  x.onreadystatechange=function(){
    if(x.readyState===4 && x.status===200){
      try{
        var data=JSON.parse(x.responseText);
        var html='';
        ['上午','下午'].forEach(function(sh){
          var item=data.shifts.find(function(s){return s.shift===sh;});
          // 三种状态要分清：① 该时段当天没排班 ② 有排班但号源约满 ③ 有号可约
          // 之前把「查不到排班」也算成 remain=0，于是显示成"已约满"，会让人以为全满
          var has    = !!item;
          var remain = has ? item.remain : 0;
          var total  = has ? item.total  : 0;
          var disabled = !has || remain <= 0;
          var label, reason = '';
          if(!has){ label='未排班'; reason='该时段当天未排班，请更换日期或医生'; }
          else if(remain<=0){ label='已约满'; reason='该时段号源已约满，请选其他时段'; }
          else { label='余 '+remain; }
          html+='<div class="shift-cell '+(disabled?'disabled':'')+'" data-shift="'+sh+'" '
               +(disabled?('data-disabled="1" data-reason="'+reason+'"'):'')
               +' onclick="pickShift(this, \''+sh+'\')">'
               + sh + '<span class="num">'+label+' / '+total+'</span></div>';
        });
        box.innerHTML=html;
      }catch(e){ box.innerHTML='<span style="color:red;">解析失败</span>'; }
    }
  };
  x.send();
}

function pickShift(el, sh){
  if(el.getAttribute("data-disabled")){
    alert(el.getAttribute("data-reason") || "该时段不可选");
    return;
  }
  document.querySelectorAll('.shift-cell').forEach(function(x){x.classList.remove("sel");});
  el.classList.add("sel");
  document.getElementById("shiftInp").value = sh;
}

// 默认日期=今天
document.getElementById("riqi").value = "<%=fromDate%>";

// 提交前校验：必须选了时段
document.getElementById("f1").addEventListener("submit", function(e){
  if(!document.getElementById("shiftInp").value){ alert("请选择时段（上午/下午）"); e.preventDefault(); return false; }
});
</script>
</body>
</html>
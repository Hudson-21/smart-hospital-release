<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.time.LocalDate,java.util.UUID,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype = (String)session.getAttribute("usertype");
if(loginname==null||loginname.isEmpty()){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"病人".equals(usertype) && !"patient".equalsIgnoreCase(usertype)){response.sendError(403);return;}

if(!(session.getAttribute("uid") instanceof Integer)){response.sendError(403);return;}
String requestedId = request.getParameter("booking_request_id");
String requestId = UUID.randomUUID().toString().replace("-", "");
String presetDept = request.getParameter("dept");
String presetDoctor = "";
String dateValue = LocalDate.now().toString();
String phone = "", beizhu = "", msg = "";
if("POST".equals(request.getMethod())){
    presetDept = request.getParameter("kebie");
    presetDoctor = request.getParameter("doctor");
    dateValue = request.getParameter("riqi");
    String shift = request.getParameter("shift");
    phone = request.getParameter("phone");
    beizhu = request.getParameter("beizhu");
    if(!AppointmentBooking.validRequestId(requestedId)){
        msg = "预约表单已失效，请重新选择时段后提交。";
    } else {
        requestId = requestedId;
        if(presetDept==null||presetDept.isEmpty()||presetDoctor==null||presetDoctor.isEmpty()
                ||dateValue==null||!AppointmentBooking.validShift(shift)){
            msg = "请选择科室、医生、就诊日期与时段。";
        } else {
            try {
                java.sql.Date day = java.sql.Date.valueOf(LocalDate.parse(dateValue));
                AppointmentBooking.Result result = AppointmentBooking.book(a, (Integer)session.getAttribute("uid"), loginname, presetDept, presetDoctor,
                    day, shift, phone, beizhu, requestId);
                if(result == AppointmentBooking.Result.BOOKED){
                    session.setAttribute("bookingSuccess", Boolean.TRUE);
                    response.setStatus(303);
                    response.setHeader("Location", response.encodeRedirectURL("my_guahao.jsp"));
                    return;
                }
                msg = result == AppointmentBooking.Result.FULL
                    ? "该医生所选时段已约满，请更换时段或医生。"
                    : "该医生在所选日期及时段未排班，请更换日期或医生。";
            } catch(java.time.format.DateTimeParseException ex){
                msg = "就诊日期不正确，请重新选择。";
            } catch(SQLException ex){
                application.log("预约写入未完成（SQLState=" + ex.getSQLState() + "）");
                msg = "挂号失败，请核对号源后重试。";
            }
        }
    }
}

StringBuilder js = new StringBuilder();
ResultSet rsd = a.executeQuery("SELECT name,kebie FROM doctor");
if(rsd==null){response.sendError(500);return;}
try (ResultSet doctors = rsd){
    while(doctors.next()){
        if(js.length()>0) js.append(',');
        js.append("['").append(WebUtil.jsEscape(doctors.getString("name")))
          .append("','").append(WebUtil.jsEscape(doctors.getString("kebie"))).append("']");
    }
}
a.close();
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
<td width="98%" align="left" class="lan13b">个人中心 > 我要挂号（就诊人：<%=WebUtil.htmlEscape(loginname)%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" role="alert" style="font-size:14px;color:#b42318"><%=WebUtil.htmlEscape(msg)%></p><%}%>
<form method="post" action="guahao.jsp" name="f1" id="f1">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<input type="hidden" name="booking_request_id" value="<%=requestId%>">
<input type="hidden" name="shift" id="shiftInp" value=""/>
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="28%" align="right" class="COLLECTION">选择科室：</td>
<td><select name="kebie" id="kebie" style="width:200px">
<option value="">--请选择--</option></select></td></tr>
<tr><td align="right" class="COLLECTION">选择医生：</td>
<td><select name="doctor" id="doctor" style="width:200px"><option value="">--请先选科室--</option></select></td></tr>
<tr><td align="right" class="COLLECTION">就诊日期：</td>
<td><input type="date" name="riqi" id="riqi" value="<%=WebUtil.htmlEscape(dateValue)%>" style="width:200px"/></td></tr>
<tr><td align="right" class="COLLECTION">选择时段：</td>
<td><span id="shiftBox" aria-live="polite" style="display:inline-block;color:#888;">请先选医生与日期</span></td></tr>
<tr><td align="right" class="COLLECTION">联系电话：</td>
<td><input type="text" name="phone" value="<%=WebUtil.htmlEscape(phone)%>" style="width:200px"/></td></tr>
<tr><td align="right" class="COLLECTION">备注：</td>
<td><input type="text" name="beizhu" value="<%=WebUtil.htmlEscape(beizhu)%>" style="width:200px"/></td></tr>
<tr><td colspan="2" align="center"><input type="submit" value="确认挂号" id="submitBtn" disabled style="width:120px;height:28px"/></td></tr>
</table>
</form>
</td></tr></table>

<script type="text/javascript">
window.hospitalBookingDoctors = [<%=js.toString()%>];
window.hospitalBookingPreset = ['<%=WebUtil.jsEscape(presetDept)%>', '<%=WebUtil.jsEscape(presetDoctor)%>'];
</script>
<script src="<%=request.getContextPath()%>/js/hospital-booking.js?v=20261125"></script>
</body>
</html>

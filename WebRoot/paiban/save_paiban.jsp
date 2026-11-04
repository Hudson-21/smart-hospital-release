<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可保存排班');history.back();</script>"); return;
}

if(!"POST".equals(request.getMethod())){
    out.print("<script>alert('请通过表单提交');history.back();</script>"); return;
}
request.setCharacterEncoding("UTF-8");
String sname = request.getParameter("doctor_name");
String scode = request.getParameter("doctor_code");
String skb   = request.getParameter("kebie");
String sdate = request.getParameter("work_date");
String sshift= request.getParameter("shift");
int sTotal   = 0; try{ sTotal=Integer.parseInt(request.getParameter("total")); }catch(Exception e){}

if(sname==null||sname.trim().equals("")||sdate==null||"".equals(sdate.trim())||sshift==null||sTotal<=0){
    out.print("<script>alert('请填写完整：医生、日期、时段、号源');history.back();</script>"); return;
}
java.sql.Date sWD=null; try{ sWD=java.sql.Date.valueOf(sdate); }catch(Exception ex){
    out.print("<script>alert('日期格式不正确');history.back();</script>"); return;
}

// 查重：同一医生+日期+时段只允许一条
ResultSet chk = a.executeQuery("SELECT id FROM paiban WHERE doctor_name=? AND work_date=? AND shift=?",
        sname.trim(), sWD, sshift);
if(chk.next()){
    out.print("<script>alert('该医生当日该时段已有排班，请勿重复添加');history.back();</script>"); return;
}

int r = a.executeUpdate("INSERT INTO paiban(doctor_code,doctor_name,kebie,work_date,shift,total,remain) VALUES(?,?,?,?,?,?,?)",
        scode, sname.trim(), skb, sWD, sshift, sTotal, sTotal);
if(r>0){
    com.hospital.Audit.log(loginname,"新增排班", sname.trim()+"/"+skb+"/"+sWD+"/"+sshift+", total="+sTotal);
}
response.sendRedirect("list_paiban.jsp");
%>
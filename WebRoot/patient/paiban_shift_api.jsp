<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*" %>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String doctor = request.getParameter("doctor");
String date   = request.getParameter("date");
if(doctor==null || "".equals(doctor) || date==null || "".equals(date)){
    out.print("{\"shifts\":[]}");
    return;
}
java.sql.Date wd=null;
try{ wd=java.sql.Date.valueOf(date); }catch(Exception e){ out.print("{\"shifts\":[]}"); return; }

StringBuilder sb = new StringBuilder("{\"shifts\":[");
ResultSet rs = a.executeQuery("SELECT shift,total,remain FROM paiban WHERE doctor_name=? AND work_date=? ORDER BY shift", doctor, wd);
boolean first=true;
while(rs.next()){
    if(!first) sb.append(",");
    first=false;
    sb.append("{\"shift\":\"").append(rs.getString("shift")==null?"":rs.getString("shift"))
      .append("\",\"total\":").append(rs.getInt("total"))
      .append(",\"remain\":").append(rs.getInt("remain"))
      .append("}");
}
sb.append("]}");
a.close();
out.print(sb.toString());
%>
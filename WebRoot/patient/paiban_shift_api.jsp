<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.time.LocalDate,com.hospital.*" %>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
response.setHeader("Cache-Control", "no-store");
String role = (String)session.getAttribute("usertype");
if(!"病人".equals(role) && !"patient".equalsIgnoreCase(role)){
    response.setStatus(403); out.print("{\"error\":\"forbidden\"}"); return;
}
String doctor = request.getParameter("doctor");
String department = request.getParameter("kebie");
String date = request.getParameter("date");
if(doctor==null || doctor.isEmpty() || date==null || date.isEmpty()){
    response.setStatus(400); out.print("{\"error\":\"missing_fields\"}"); return;
}
java.sql.Date day;
try { day = java.sql.Date.valueOf(LocalDate.parse(date)); }
catch(java.time.format.DateTimeParseException ex){
    response.setStatus(400); out.print("{\"error\":\"invalid_date\"}"); return;
}

String query = "SELECT shift,total,remain FROM paiban WHERE doctor_name=? AND work_date=?";
ResultSet results = department==null || department.isEmpty()
    ? a.executeQuery(query + " ORDER BY shift", doctor, day)
    : a.executeQuery(query + " AND kebie=? ORDER BY shift", doctor, day, department);
if(results==null){ response.setStatus(503); out.print("{\"error\":\"unavailable\"}"); return; }
StringBuilder json = new StringBuilder("{\"shifts\":[");
boolean first = true;
try (ResultSet rs = results){
    while(rs.next()){
        String shift = rs.getString("shift");
        if(!AppointmentBooking.validShift(shift)) continue;
        if(!first) json.append(',');
        first = false;
        json.append("{\"shift\":\"").append(shift)
            .append("\",\"total\":").append(rs.getInt("total"))
            .append(",\"remain\":").append(rs.getInt("remain")).append('}');
    }
} catch(SQLException ex){
    response.setStatus(503); out.print("{\"error\":\"unavailable\"}"); return;
}
out.print(json.append("]}").toString());
%>

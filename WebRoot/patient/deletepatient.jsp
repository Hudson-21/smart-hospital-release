<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>

<%@ page import="com.hospital.DataFormat" %>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
     int id = 0;
     try{ id = Integer.parseInt(request.getParameter("id")); }catch(Exception ignore){}
     int result = db.executeUpdate("delete from patient where id=?", id);
     com.hospital.Audit.log((String)session.getAttribute("loginname"), "删除病人", "id=" + id);

  %>
 
   <%			 
   response.sendRedirect("list_patient.jsp");
  %>

  </body>
  </html>

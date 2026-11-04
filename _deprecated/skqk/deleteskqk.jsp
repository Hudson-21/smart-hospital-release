<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.hospital.*" %>
<%@ page import="com.hospital.DataFormat" %>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
     int id = request.getParameter("id")==null?0:Integer.parseInt(request.getParameter("id")); 
     int result = db.executeUpdate("delete from skqk where id=" + id);

  %>
 
   <%			 
   response.sendRedirect("list_skqk.jsp");
  %>

  </body>
  </html>

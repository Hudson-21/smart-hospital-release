<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.hospital.*" %>
<%@ page import="com.hospital.DataFormat" %>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
	 String jsmc = DataFormat.convert(request.getParameter("jsmc"));
     String sksj = DataFormat.convert(request.getParameter("sksj"));
	 String kss = DataFormat.convert(request.getParameter("kss"));
	 String lb = DataFormat.convert(request.getParameter("lb"));
	 String xslb = DataFormat.convert(request.getParameter("xslb"));
	 String pgzysl = DataFormat.convert(request.getParameter("pgzysl"));
     int id = request.getParameter("id")==null?0:Integer.parseInt(request.getParameter("id")); 
   

  %>
  <%
 
   if(id!=0){
      String sql = "update skqk set jsmc='"+jsmc+"', sksj='"+sksj+"', kss="+kss+",lb='"+lb+"',xslb='"+xslb+"',pgzysl="+pgzysl+"  where id="+id;
      db.executeUpdate(sql);
   }else{
       int result = db.executeUpdate("insert into skqk(jsmc,sksj,kss,lb,xslb,pgzysl) values('"+jsmc+"','"+sksj+"',"+kss+", '"+lb+"', '"+xslb+"', "+pgzysl+")");
   }
 
   
  %>
   <%			 
   response.sendRedirect("list_skqk.jsp");
  %>

  </body>
  </html>

<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.hospital.*" %>

<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
	 String number = DataFormat.convert(request.getParameter("number"));
	 String kebie = DataFormat.convert(request.getParameter("kebie"));
	 String cost = DataFormat.convert(request.getParameter("cost"));
	 String state = DataFormat.convert(request.getParameter("state"));   
     int id = request.getParameter("id")==null?0:Integer.parseInt(request.getParameter("id")); 
   

  %>
  <%
 
   if(id!=0){
      db.executeUpdate("update bed set number=?, kebie=?, cost=?, state=? where id=?",
              number, kebie, cost, state, id);
   }else{
       db.executeUpdate("insert into bed(number,kebie,cost,state) values(?,?,?,?)",
              number, kebie, cost, state);
   }
   // —— 操作审计（增改均留痕；删除已 audit，本处补齐对称）——
   String detail = "id=" + id + ", 科别=" + kebie + ", 床号=" + number + ", 状态=" + state;
   com.hospital.Audit.log((String)session.getAttribute("loginname"),
       id!=0 ? "修改病床" : "新增病床", detail);
%>
   <%
   response.sendRedirect("list_bed.jsp");
  %>

  </body>
  </html>

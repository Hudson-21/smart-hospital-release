<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.hospital.*" %>

<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
	 String number = DataFormat.convert(request.getParameter("number"));
	 String name = DataFormat.convert(request.getParameter("name"));
	 String sex = DataFormat.convert(request.getParameter("sex"));
	 String zhicheng = DataFormat.convert(request.getParameter("zhicheng"));
	 String zhiwu = DataFormat.convert(request.getParameter("zhiwu"));
	 String kebie = DataFormat.convert(request.getParameter("kebie"));
	 String birthtime = DataFormat.convert(request.getParameter("birthtime"));
	 String worktime = DataFormat.convert(request.getParameter("worktime"));
     
     int id = request.getParameter("id")==null?0:Integer.parseInt(request.getParameter("id")); 
   

  %>
  <%
 
   if(id!=0){
      db.executeUpdate("update doctor set number=?, name=?, sex=?, zhicheng=?, zhiwu=?, kebie=?, birthtime=?, worktime=? where id=?",
              number, name, sex, zhicheng, zhiwu, kebie, birthtime, worktime, id);
   }else{
       db.executeUpdate("insert into doctor(number,name,sex,zhicheng,zhiwu,kebie,birthtime,worktime) values(?,?,?,?,?,?,?,?)",
              number, name, sex, zhicheng, zhiwu, kebie, birthtime, worktime);
   }
   // —— 操作审计 ——
   String detail = "id=" + id + ", 工号=" + number + ", 姓名=" + name + ", 科别=" + kebie;
   com.hospital.Audit.log((String)session.getAttribute("loginname"),
       id!=0 ? "修改医生" : "新增医生", detail);
%>
   <%
   response.sendRedirect("list_user.jsp");
  %>

  </body>
  </html>

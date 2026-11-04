<%@page contentType="text/html; charset=gb2312"%>
<%@ page import="java.sql.*" %>
<%@ page import="com.hospital.*" %>

<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>


<html>
<body>


<%
	String number = DataFormat.convert(request.getParameter("number"));
	String kebie = DataFormat.convert(request.getParameter("kebie"));
	String name = DataFormat.convert(request.getParameter("name"));
	String sex = DataFormat.convert(request.getParameter("sex"));
	String chuyuan = DataFormat.convert(request.getParameter("chuyuan"));
	String age = DataFormat.convert(request.getParameter("age"));
	String bingzheng = DataFormat.convert(request.getParameter("bingzheng"));
	String doctor = DataFormat.convert(request.getParameter("doctor"));
	String ruyuan = DataFormat.convert(request.getParameter("ruyuan"));
	int id = request.getParameter("id") == null ? 0 : Integer.parseInt(request.getParameter("id"));
%>
  <%
  	if(id != 0) {
  		db.executeUpdate("update patient set number=?, kebie=?, chuyuan=?, age=?, bingzheng=?, doctor=?, ruyuan=?, name=?, sex=? where id=?",
  				number, kebie, chuyuan, age, bingzheng, doctor, ruyuan, name, sex, id);
  	} else {
  		db.executeUpdate("insert into patient(number,kebie,name,sex,chuyuan,age,bingzheng,doctor,ruyuan) values(?,?,?,?,?,?,?,?,?)",
  				number, kebie, name, sex, chuyuan, age, bingzheng, doctor, ruyuan);
  	}
  	// —— 操作审计（病人主档敏感，留痕便于医疗纠纷溯源）——
  	String detail = "id=" + id + ", 住院号=" + number + ", 姓名=" + name + ", 性别=" + sex
  	    + ", 年龄=" + age + ", 科别=" + kebie + ", 主治=" + doctor;
  	com.hospital.Audit.log((String)session.getAttribute("loginname"),
  	    id != 0 ? "修改病人" : "新增病人", detail);
  %>
   <%
   	response.sendRedirect("list_patient.jsp");
   %>

  </body>
  </html>

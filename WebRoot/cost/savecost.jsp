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
	String xiangmu = DataFormat.convert(request.getParameter("xiangmu"));
	String danjia = DataFormat.convert(request.getParameter("danjia"));
	String shuliang = DataFormat.convert(request.getParameter("shuliang"));
	String jine = DataFormat.convert(request.getParameter("jine"));
	String riqi = DataFormat.convert(request.getParameter("riqi"));
	int id = request.getParameter("id") == null ? 0 : Integer.parseInt(request.getParameter("id"));
%>
  <%
  	if(id != 0) {
  		db.executeUpdate("update cost set number=?, kebie=?, name=?, xiangmu=?, danjia=?, shuliang=?, jine=?, riqi=? where id=?",
  				number, kebie, name, xiangmu, danjia, shuliang, jine, riqi, id);
  	} else {
  		db.executeUpdate("insert into cost(number,kebie,name,xiangmu,danjia,shuliang,jine,riqi) values(?,?,?,?,?,?,?,?)",
  				number, kebie, name, xiangmu, danjia, shuliang, jine, riqi);
  	}
  	// —— 操作审计（财务流水必须留痕，含金额字段便于追溯）——
  	String detail = "id=" + id + ", 科别=" + kebie + ", 床号=" + number + ", 姓名=" + name
  	    + ", 项目=" + xiangmu + ", 金额=" + jine + ", 日期=" + riqi;
  	com.hospital.Audit.log((String)session.getAttribute("loginname"),
  	    id != 0 ? "修改收费" : "新增收费", detail);
  %>
   <%
   	response.sendRedirect("list_cost.jsp");
   %>

  </body>
  </html>

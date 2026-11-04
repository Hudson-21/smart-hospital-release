<%@page contentType="text/html; charset=gb2312"%>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon"/>

<%
String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path;
String applicationPath = basePath + "/" + "application";
%>
<%@ page import="java.sql.*" %>
<html>
<body>
    <script language="javascript">
 function checkform() {
	if (document.addForm.name.value=="" || document.addForm.rnrs.value==""){
		alert("请输入完整信息！");
		return false;
	}
	else {
		alert("修改成功！");
		return true;
	}
  }
</script>



 <link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
 <script type="text/javascript" src="<%=path%>/calendar/WdatePicker.js"></script>
  <% request.setCharacterEncoding("gb2312"); %>
  
  
<head>
<title>
修改上课情况信息
</title>
</head>

<FORM Action="saveadd.jsp" Method="post" name="addForm">
 
<%
  String id=request.getParameter("id");

  String sql="select * from skqk where id="+id;
  ResultSet rs = db.executeQuery(sql);
  while(rs.next()) { %>
  <input type="hidden" name="id"  maxlength="32" class=inputnormal value="<%=rs.getString("id")%>">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
  <tr>
	<td valign="top" align="left" class="pad5">
	    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
          <tr>
            <td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
            <td width="98%" align="left" class="lan13b">上课情况管理 > 修改上课情况信息</td>
          </tr>
        </table>
		<table width="100%" border="0" cellpadding="1" cellspacing="1" class="table-border margb5">
		  <tr>
			<td width="14%" align="right" class="COLLECTION">教师姓名：</td>
		    <td width="36%" align="left" class="even padl5">
      <select   name="jsmc">
             
             <%
 

  String sql1="select * from users where usertype='教师'";
  ResultSet rs1 = db.executeQuery(sql1);
  while(rs1.next()) { %>
		        <option <% if(rs.getString("jsmc").equals(rs1.getString("rname"))){ %>selected="true"<%
		        } %>  ><%=rs1.getString("rname")==null?"":rs1.getString("rname")%></option>
		      
		          <% } rs1.close();%>
	          </select>	





			 </td>
		   

		  </tr>
		  
		  
		     <tr>
 
		    <td width="14%" align="right" class="COLLECTION">上课时间：</td>
		    <td width="36%" align="left" class="even padl5">	    <input class="Wdate" type="text" name="sksj"  value="<%=rs.getDate("sksj")%>" maxlength="32"
					onfocus="WdatePicker({readOnly:true})" /> </td>
		    
	
		  </tr>
		   <tr>
 
		    <td width="14%" align="right" class="COLLECTION">课时数：</td>
		    <td width="36%" align="left" class="even padl5"><input type=text name="kss" value="<%=rs.getInt("kss")%>"  maxlength="32" class="inputnormal" value=""></td>
		  </tr>
          <tr>
		    <td align="right" class="COLLECTION">类别：</td>
		    <td   align="left" class="even padl5">
		    <%  
		       String lb =  rs.getString("lb"); 
		    %>
		      <select   name="lb">
		        <option  <% if("理论".equals(lb)){ %>selected="true"<%
		        } %> >理论</option>
		        <option  <% if("实验".equals(lb)){ %>selected="true"<%
		        } %> >实验</option>
	          </select>		    </td>
	      </tr>
		  <tr>
		    <td align="right" class="COLLECTION">学生类别：</td>
		    <td   align="left" class="even padl5">
		    <%  
		       String xslb =  rs.getString("xslb"); 
		    %>
		      <select   name="xslb">
		        <option  <% if("自考".equals(xslb)){ %>selected="true"<%
		        } %> >自考</option>
		        <option  <% if("成教".equals(xslb)){ %>selected="true"<%
		        } %> >成教</option>
		        <option  <% if("统招".equals(xslb)){ %>selected="true"<%
		        } %> > 统招</option>
	          </select>		    </td>
	      </tr>
	      		   <tr>
 
		    <td width="14%" align="right" class="COLLECTION">批改作业数量：</td>
		    <td width="36%" align="left" class="even padl5"><input type=text name="pgzysl" value="<%=rs.getInt("pgzysl")%>"   maxlength="32" class="inputnormal" value=""></td>
		  </tr>
		  
	 
	  </table>
		<table width="100%" border="0" cellspacing="0" cellpadding="0">
          <tr>
		    <td width="50%" align="right" class="padr5"><input type="submit" onclick="javascript:return(checkform());" name="button" value="保 存" class="button"></td>
		    <td width="50%" align="left" class="padl5"><input name="button1" type="button" class="button" onClick="history.go(-1);" value="返 回"></td>
          </tr>
        </table>
    </td>
  </tr>
</table>

  <% } rs.close();%>






</form>


<br>
<br>
<br>
<br>
 
</body>
</html>

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
<script type="text/javascript" src="<%=path%>/calendar/WdatePicker.js"></script>
    <script language="javascript">
 function checkform() {
	if (document.addForm.kss.value=="" || document.addForm.sksj.value==""){
		alert("请输入上课时间、课时数！");
		return false;
	}
	else {
		alert("添加成功！");
		return true;
	}
  }
</script>



 <link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
  <% request.setCharacterEncoding("gb2312"); %>
<head>
<title>
添加上课情况信息
</title>
</head>

<FORM Action="saveadd.jsp" Method="post" name="addForm">
 

<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
  <tr>
	<td valign="top" align="left" class="pad5">
	    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
          <tr>
            <td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
            <td width="98%" align="left" class="lan13b">上课情况管理 > 添加上课情况信息</td>
          </tr>
        </table>
		<table width="100%" border="0" cellpadding="1" cellspacing="1" class="table-border margb5">
		  <tr>
			<td width="14%" align="right" class="COLLECTION">教师姓名：</td>
		    <td width="36%" align="left" class="even padl5">

             <select   name="jsmc">
             
             <%
 

  String sql="select * from users where usertype='教师'";
  ResultSet rs = db.executeQuery(sql);
  while(rs.next()) { %>
		        <option><%=rs.getString("rname")==null?"":rs.getString("rname")%></option>
		      
		          <% } rs.close();%>
	          </select>	


           </td>
		   

		  </tr>
		  		   <tr>
 
		    <td width="14%" align="right" class="COLLECTION">上课时间：</td>
		    <td width="36%" align="left" class="even padl5">	    <input class="Wdate" type="text" name="sksj"  maxlength="32"
					onfocus="WdatePicker({readOnly:true})" /> </td>
		    
	
		  </tr>
		   <tr>
 
		    <td width="14%" align="right" class="COLLECTION">课时数：</td>
		    <td width="36%" align="left" class="even padl5"><input type=text name="kss"   maxlength="32" class="inputnormal" value=""></td>
		  </tr>
          <tr>
		    <td align="right" class="COLLECTION">类别：</td>
		    <td   align="left" class="even padl5">
		      <select   name="lb">
		        <option>理论</option>
		        <option>实验</option>
	          </select>		    </td>
	      </tr>
		  <tr>
		    <td align="right" class="COLLECTION">学生类别：</td>
		    <td   align="left" class="even padl5">
		      <select   name="xslb">
		        <option>自考</option>
		        <option>成教</option>
		        <option>统招</option>
	          </select>		    </td>
	      </tr>
	      		   <tr>
 
		    <td width="14%" align="right" class="COLLECTION">批改作业数量：</td>
		    <td width="36%" align="left" class="even padl5"><input type=text name="pgzysl"   maxlength="32" class="inputnormal" value=""></td>
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







</form>


<br>
<br>
<br>
<br>
 
</body>
</html>

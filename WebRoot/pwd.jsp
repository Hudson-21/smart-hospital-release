<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>
<%@ page import="com.hospital.*" %>
<%
String path = request.getContextPath();
String __ln=(String)session.getAttribute("loginname");
if(__ln==null||"".equals(__ln)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon"/>
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8";>
<title>change</title>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff">

<SCRIPT LANGUAGE="javascript" >
 function checkform(){
         // 原密码正确性改由服务端校验（不再把真实密码渲染到页面源码里）
           if(form2.pwd1.value=="")
           {
                alert("请输入原密码");
                form2.pwd1.focus();
                return false;
           }
           if(form2.pwd2.value=="")
           {
                   alert("请输入新密码");
                   form2.pwd2.focus();
                 return false;
                  }


            else if(form2.pwd2.value!=form2.pwd3.value)
              {
                 alert("两次输入的新密码不同，请重新输入");
                 form2.pwd3.focus();
                 return false;
              }
             return true;
 }
</SCRIPT>

 <link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />

 <center>
 <form action="update_pwd.jsp" method="POST" name="form2">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">

<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
  <tr>
	<td valign="top" align="left" class="pad5">
	    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
          <tr>
            <td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
            <td width="98%" align="left" class="lan13b">密码修改</td>
          </tr>
        </table>
		<table width="100%" border="0" cellpadding="1" cellspacing="1" class="table-border margb5">

		  		   <tr>

		    <td width="14%" align="right" class="COLLECTION">请输入原密码：</td>
		    <td width="36%" align="left" class="even padl5">	    <input  type=password name="pwd1"  maxlength="32"
					onfocus="WdatePicker({readOnly:true})" /> </td>


		  </tr>
		   <tr>

		    <td width="14%" align="right" class="COLLECTION">请输入新密码：</td>
		    <td width="36%" align="left" class="even padl5"><input type=password name="pwd2"   maxlength="32" class="inputnormal" value=""></td>
		  </tr>

	      		   <tr>

		    <td width="14%" align="right" class="COLLECTION">确认新密码：</td>
		    <td width="36%" align="left" class="even padl5"><input type=password name="pwd3"  maxlength="32" class="inputnormal" value=""></td>
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
 </center>
</body>
</html>

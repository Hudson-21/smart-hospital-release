<%@ page contentType="text/html; charset=GBK" %>
<%
	String path = request.getContextPath();
String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path;
String applicationPath = basePath + "/" + "application";
%>
<%@ page import="java.sql.*" %>
<%@ page language="java" %>
<%@ page import="java.util.*" %>
<%@ page import="com.hospital.*" %>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon"/>
<html>
<head>
  <style type="TEXT/CSS">
  A:LINK{COLOR:blue;FONT-SIZE:12PT;TEXT-DECORATION:NONE}
  A:VISITED{COLOR:blue;FONT-SIZE:12PT;TEXT-DECORATION:NONE}
   A:HOVER{COLOR:red;FONT-SIZE:12PT;TEXT-DECORATION:UNDERLINE}
    
   </STYLE>

   <link rel="stylesheet" type="text/css" media="all" href="<%=path%>/images/css1/ioa.css" />
     
<title>
上课情况信息列表
</title>
</head>
<body bgcolor="#ffffff"><br>
 
<%
int PageSize = 6;
int Page = 1;
int totalPage = 1;
int totalrecord = 0;
 

String sql = null;
ResultSet rs = null;


    //算出总行数
	sql = "SELECT count(*) as recordcount  FROM skqk";
	rs = a.executeQuery(sql);
   
	if (rs!=null && rs.next()){
	   totalrecord = rs.getInt("recordcount");
	}
	//输出记录
	sql = "SELECT * FROM skqk";
    rs = a.executeQuery(sql);
%>


<p align="center">


<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
  <tr>
	<td valign="top" align="left" class="pad5">
	    <table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
          <tr>
            <td width="2%" align="right" class="pad05"><img src="<%=path%>/images/img2.gif" width="16" height="16"></td>
            <td width="98%" align="left" class="lan13b">上课情况管理 > 上课情况信息管理</td>
          </tr>
        </table>
		<table border="0" cellspacing="0" cellpadding="0" class="margb5">
          <tr>
            <td width="61" align="left" class="padr5"><input type="image" src="<%=path%>/images/pic-13.jpg" onClick="window.location.href='addskqk.jsp'"></td>
           
          </tr>
        </table>
	    <table width="100%" border="0" cellspacing="1" cellpadding="0" class="table-border margb5">
		  <tr>
			<td colspan="11" align="left" class="tabbg"><img src="<%=path%>/images/main_pic_1.gif" align="absmiddle" width="16" height="16">&nbsp;<span class="lan13b"></span></td>
	      </tr>
		  <tr>
 
                  <th width="3%" nowrap class="COLLECTION"> 
                    教师名称</th>
                  <th width="5%" nowrap class="COLLECTION">上课时间</th>
                  <th width="7%" nowrap class="COLLECTION"> 
                   课时数</th>
                  <th width="7%" nowrap class="COLLECTION"> 
                   类别</th>
                                <th width="7%" nowrap class="COLLECTION"> 
                  学生类别</th>   
             <th width="7%" nowrap class="COLLECTION"> 
                 批改作业数量</th>  
                              <th width="7%" nowrap class="COLLECTION"> 
                管理</th>  
		  </tr>

<%
if(totalrecord % PageSize ==0)// 如果是当前页码的整数倍
		totalPage = totalrecord / PageSize;
	else  // 如果最后还空余一页
		totalPage = (int) Math.floor( totalrecord / PageSize ) + 1;
	if(totalPage == 0) totalPage = 1;
	if(request.getParameter("Page")==null || request.getParameter("Page").equals(""))
		Page = 1;
	else
	try {
		Page = Integer.parseInt(request.getParameter("Page"));
	}
    catch(java.lang.NumberFormatException e){
		// 捕获用户从浏览器地址拦直接输入Page=sdfsdfsdf所造成的异常
		Page = 1;
	}
	if(Page < 1)  Page = 1;
	if(Page > totalPage) Page = totalPage;
	
		if (rs!=null && rs.next()){
	   
	rs.absolute((Page-1) * PageSize + 1);
	
	for(int iPage=1; iPage<=PageSize; iPage++) {
	 
          int id=rs.getInt("id");
  
     %>
		<div align="right"></div> </td>
    </tr>

   <tr class="even"> 

	   <td nowrap align="center"><%=rs.getString("jsmc")%></td>
           <td nowrap align="center"><%=rs.getDate("sksj")%></td>
	   <td nowrap align="center"><%=rs.getInt("kss")%></td>
	   	   <td nowrap align="center"><%=rs.getString("lb")%></td>
	   	   	   <td nowrap align="center"><%=rs.getString("xslb")%></td>
	   	   	   	   <td nowrap align="center"><%=rs.getInt("pgzysl")%></td>
 
         <td nowrap align="center"><a href="modifyskqk.jsp?id=<%=id%>">修改</a> | <a href="deleteskqk.jsp?id=<%=id%>">删除</a></td>

	     </tr>
		<% if(!rs.next()) break;
	}
	}
%>

<FORM Action="list_skqk.jsp" Method="GET">

 <tr>
		    <td colspan="11" align="right" class="tabbg hei12">


<%
   if(Page != 1) {
      out.print("   <A HREF=list_kecheng.jsp?Page=1> 第一页 </A>");
      out.print("   <A HREF=list_kecheng.jsp?Page=" + (Page-1) + "> 上一页 </A>");
   }
   if(Page != totalPage) {
      out.print("   <A HREF=list_kecheng.jsp?Page=" + (Page+1) + "> 下一页 </A>");
      out.print("   <A HREF=list_kecheng.jsp?Page=" + totalPage + "> 最后一页 </A>");
   }
%>
&nbsp;输入页数：<input TYPE="TEXT" Name="Page" SIZE="3">
页数:<font COLOR="Red"><%=Page%>/<%=totalPage%></font>
<INPUT TYPE="submit" value="提交">



              </td>
	      </tr>
		</table>
		 
	</td>
  </tr>
</table>

</FORM>




</body>













</html>

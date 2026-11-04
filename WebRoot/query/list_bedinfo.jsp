<%@ page contentType="text/html; charset=GBK"%>
<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + path;
	String applicationPath = basePath + "/" + "application";
%>
<%@ page import="java.sql.*"%>
<%@ page language="java"%>
<%@ page import="java.util.*"%>
<%@ page import="com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<html>
	<head>
		<style type="TEXT/CSS">
A:LINK {
	COLOR: blue;
	FONT-SIZE: 12PT;
	TEXT-DECORATION: NONE
}

A:VISITED {
	COLOR: blue;
	FONT-SIZE: 12PT;
	TEXT-DECORATION: NONE
}

A:HOVER {
	COLOR: red;
	FONT-SIZE: 12PT;
	TEXT-DECORATION: UNDERLINE
}
</STYLE>

		<link rel="stylesheet" type="text/css" media="all"
			href="<%=path%>/images/css1/ioa.css" />
		<script type="text/javascript" src="<%=path%>/calendar/WdatePicker.js">
</script>


		<title>病床利用率查询</title>
	
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
	<body class="h-business" bgcolor="#ffffff">
		<br>

		<%
			int PageSize = 6;
			int Page = 1;
			int totalPage = 1;
			int totalrecord = 0;

			String sql = null;
			ResultSet rs = null;
			String brxm = DataFormat.convert(request.getParameter("kebie"));
			String doctor=DataFormat.convert(request.getParameter("doctor"));

			 String startdate = request.getParameter("sksjs")==null?"":request.getParameter("sksjs");
    String enddate = request.getParameter("sksje")==null?"":request.getParameter("sksje");

			//动态条件 + 参数化（防 SQL 注入）：一次拼好条件与占位参数，计数与查询共用
			java.util.List<Object> cnd = new java.util.ArrayList<Object>();
			StringBuilder sqlb = new StringBuilder(" FROM patient where 1=1");
			if(brxm != null && brxm.trim().length()>0) {
				sqlb.append(" and kebie like ?");
				cnd.add("%" + brxm.trim() + "%");
			}
			if(startdate != null && startdate.trim().length()>2) {
				sqlb.append(" and ruyuan > ?");
				cnd.add(startdate.trim());
			}
			if(enddate != null && enddate.trim().length()>2) {
				sqlb.append(" and ruyuan < ?");
				cnd.add(enddate.trim());
			}
			if(doctor != null && doctor.trim().length()>0) {
				sqlb.append(" and doctor like ?");
				cnd.add("%" + doctor.trim() + "%");
			}

			//算出总行数
			rs = a.executeQuery("SELECT count(*) as recordcount" + sqlb.toString(), cnd.toArray());

			if(rs!=null && rs.next())
				totalrecord = rs.getInt("recordcount");
			//输出记录
			rs = a.executeQuery("SELECT *" + sqlb.toString(), cnd.toArray());
		%>


		<p align="center">


			<table width="100%" border="0" cellspacing="0" cellpadding="0"
				class="pad5">
				<tr>
					<td valign="top" align="left" class="pad5">
						<table width="100%" border="0" cellspacing="0" cellpadding="0"
							class="dqbg margb5">
							<tr>
								<td width="2%" align="right" class="pad05">
									<img src="<%=path%>/images/img2.gif" width="16" height="16">
								</td>
								<td width="98%" align="left" class="lan13b">
									统计查询 > 病床利用率查询
								</td>
							</tr>
						</table>

						<form action="list_bedinfo.jsp" method="post">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
							<table width="100%" border="0" cellspacing="0" cellpadding="0"
								class="dqbg margb5">
								<tr>
									<td align="center" class="lan13b">
										科别：
										<input name="kebie" value="" maxlength="32" />
										医师：
										<input name="doctor" value="" maxlength="32" />
										日期：
										<input class="Wdate" type="text" name="sksjs"
											value="<%=com.hospital.WebUtil.htmlEscape(startdate)%>" maxlength="32"
											onfocus="WdatePicker({readOnly:true})" />
										--
										<input class="Wdate" type="text" name="sksje" maxlength="32"
											onfocus="WdatePicker({readOnly:true})" value="<%=com.hospital.WebUtil.htmlEscape(enddate)%>" />
										<input type="submit" name="button" value="查询" class="button">
										<a href="export.jsp?type=bed" style="margin-left:14px;font-size:13px;">导出 CSV（Excel 可打开）</a>

									</td>

								</tr>
							</table>
						</form>



						<table width="100%" border="0" cellspacing="1" cellpadding="0"
							class="table-border margb5">
							<tr>
								<td colspan="11" align="left" class="tabbg">
									<img src="<%=path%>/images/main_pic_1.gif" align="absmiddle"
										width="16" height="16">
									&nbsp;
									<span class="lan13b"></span>
								</td>
							</tr>
							<tr>

								<th width="3%" nowrap class="COLLECTION">
									科别
								</th>
								<th width="3%" nowrap class="COLLECTION">
									病床号
								</th>
								<th width="3%" nowrap class="COLLECTION">
									病人姓名
								</th>
								<th width="5%" nowrap class="COLLECTION">
									病人性别
								</th>
								<th width="5%" nowrap class="COLLECTION">
									病人年龄
								</th>
								<th width="5%" nowrap class="COLLECTION">
									病症
								</th>
								<th width="5%" nowrap class="COLLECTION">
									主治医生
								</th>
								<th width="5%" nowrap class="COLLECTION">
									入院日期
								</th>
								<th width="5%" nowrap class="COLLECTION">
									出院日期
								</th>


							</tr>

							<%
								if(totalrecord % PageSize == 0)// 如果是当前页码的整数倍
									totalPage = totalrecord / PageSize;
								else
									// 如果最后还空余一页
									totalPage = (int) Math.floor(totalrecord / PageSize) + 1;
								if(totalPage == 0)
									totalPage = 1;
								if(request.getParameter("Page") == null || request.getParameter("Page").equals(""))
									Page = 1;
								else
									try {
										Page = Integer.parseInt(request.getParameter("Page"));
									}
									catch(java.lang.NumberFormatException e) {
										// 捕获用户从浏览器地址拦直接输入Page=sdfsdfsdf所造成的异常
										Page = 1;
									}
								if(Page < 1)
									Page = 1;
								if(Page > totalPage)
									Page = totalPage;
								rs.absolute((Page - 1) * PageSize + 1);
							%>
							<%
								for(int iPage = 1; iPage <= PageSize; iPage++) {
									if(totalrecord == 0)
										break;
									int id = rs.getInt("id");
							%>
							<div align="right"></div>
							</td>
							</tr>

							<tr class="even">
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("number"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("name") == null ? "" : rs.getString("name"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("sex") == null ? "" : rs.getString("sex"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("age") == null ? "" : rs.getString("age"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("bingzheng") == null ? "" : rs.getString("bingzheng"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("doctor") == null ? "" : rs.getString("doctor"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("ruyuan") == null ? "" : rs.getString("ruyuan"))%></td>
								<td nowrap align="center"><%=com.hospital.WebUtil.htmlEscape(rs.getString("chuyuan") == null ? "" : rs.getString("chuyuan"))%></td>




							</tr>
							<%
								if(!rs.next())
										break;
								}
							%>

							<FORM Action="list_patient.jsp" Method="GET">

								<tr>
									<td colspan="11" align="right" class="tabbg hei12">


										<%
											if(Page != 1) {
												out.print("   <A HREF=list_kecheng.jsp?Page=1> 第一页 </A>");
												out.print("   <A HREF=list_kecheng.jsp?Page=" + (Page - 1) + "> 上一页 </A>");
											}
											if(Page != totalPage) {
												out.print("   <A HREF=list_kecheng.jsp?Page=" + (Page + 1) + "> 下一页 </A>");
												out.print("   <A HREF=list_kecheng.jsp?Page=" + totalPage + "> 最后一页 </A>");
											}
										%>
										&nbsp;输入页数：
										<input TYPE="TEXT" Name="Page" SIZE="3">
										页数:
										<font COLOR="Red"><%=Page%>/<%=totalPage%></font>
										<INPUT TYPE="submit" value="提交">



									</td>
								</tr>
						</table>

					</td>
				</tr>
			</table>

			</FORM>

			<table align="center">
				<tr>
					<td align="center">
						<input type="submit" onclick="javascript:window.print();"
							name="button" value="打印" class="button">
					</td>
				</tr>
			</table>
	</body>













</html>

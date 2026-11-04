<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
/* 禁止浏览器缓存左侧菜单：
   本页是按角色动态生成的框架页，且随权限调整而变化。
   浏览器（尤其框架页）会顽固缓存旧版本，导致"代码改了菜单却不变"的假象。 */
response.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
response.setHeader("Pragma", "no-cache");
response.setDateHeader("Expires", 0);
%>
<head>
	<title>医院管理系统</title>
	<link href="images/css1/left_css.css" rel="stylesheet" type="text/css">
</head>
<SCRIPT language=JavaScript>
function showsubmenu(sid)
{
whichEl = eval("submenu" + sid);
if (whichEl.style.display == "none")
{
eval("submenu" + sid + ".style.display=\"\";");
}
else
{
eval("submenu" + sid + ".style.display=\"none\";");
}
}

function loginout(){
   parent.window.location.href = "login.jsp";
}
</SCRIPT>
<body bgcolor="16ACFF">

	<%
		String usertype = (String) session.getAttribute("usertype");
	%>
	<table width="98%" border="0" cellpadding="0" cellspacing="0"
		background="images/tablemde.jpg">

<%
	if ("管理员".equals(usertype)) {
%>
		<!-- ============ 管理员：全部功能 ============ -->
		<tr>
			<td height="5" background="images/tableline_top.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(4);
											height=25>
											医生信息管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu4 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/list_user.jsp" target=main>医生信息查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/adduser.jsp" target=main>医生信息添加</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(16);
											height=25>
											病床信息管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu16 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="bed/list_bed.jsp" target=main>病床信息查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="bed/addbed.jsp" target=main>病床信息添加</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(7);
											height=25>
											病人信息管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu7 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/list_patient.jsp" target=main>病人信息查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/addpatient.jsp" target=main>病人信息添加</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(19);
											height=25>
											收费信息管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu19 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="cost/list_cost.jsp" target=main>收费信息查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="cost/addcost.jsp" target=main>收费信息添加</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(20);
											height=25>
											挂号管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu20 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="guahao/list_guahao.jsp" target=main>挂号记录管理</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="paiban/list_paiban.jsp" target=main>排班管理</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="paiban/add_paiban.jsp" target=main>新增排班</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(9);
											height=25>
											统计分析
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu9 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="query/list_bedinfo.jsp" target=main>病床利用率查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="query/list_costinfo.jsp" target=main>收费明细查询</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="stats/dashboard.jsp" target=main>数据看板</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(21);
											height=25>
											智能服务
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu21 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="ai/ask.jsp" target="_blank">智能导诊</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 style="CURSOR: hand" onclick=showsubmenu(5);
											height=25>
											系统管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE id=submenu5 cellSpacing=0 cellPadding=0 width="100%"
									border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/role_manage.jsp" target=main>账号权限管理</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="pwd.jsp" target=main>修改密码</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="#" onclick="loginout();" target=main>退出系统</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

<%
	} else if ("医生".equals(usertype)) {
%>
		<!-- ============ 医生：只看自己负责的病人的数据 ============ -->
		<tr>
			<td height="5" background="images/tableline_top.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 height=25>
											我的工作台
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/my_info.jsp" target=main>我的档案</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/my_patient.jsp" target=main>我的病人</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/my_cost.jsp" target=main>我的病人费用</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/my_guahao.jsp" target=main>我的接诊</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/my_bingli.jsp" target=main>我的病历</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="paiban/list_paiban.jsp" target=main>我的排班</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="yaoku/list_yaoku.jsp" target=main>药品库存</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="doctor/add_chufang.jsp" target=main>开方开药</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="chufang/list_chufang.jsp" target=main>我的处方</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 height=25>
											系统管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="pwd.jsp" target=main>修改密码</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="#" onclick="loginout();" target=main>退出系统</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

<%
	} else if ("病人".equals(usertype) || "patient".equalsIgnoreCase(usertype)) {
%>
		<!-- ============ 病人：只看自己的信息、费用，可用智能导诊 ============ -->
		<tr>
			<td height="5" background="images/tableline_top.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 height=25>
											个人中心
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/my_info.jsp" target=main>我的信息</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/my_cost.jsp" target=main>我的费用</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/guahao.jsp" target=main>我要挂号</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/my_guahao.jsp" target=main>我的挂号</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="patient/my_bingli.jsp" target=main>我的病历</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="ai/ask.jsp" target="_blank">智能导诊</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 height=25>
											系统管理
										</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="pwd.jsp" target=main>修改密码</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="#" onclick="loginout();" target=main>退出系统</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>

<%
	} else {
%>
		<!-- ============ 未识别角色：默认给管理员菜单 ============ -->
		<tr>
			<td height="5" background="images/tableline_top.jpg"
				bgcolor="#9BC2ED"></td>
		</tr>
		<tr>
			<td>
				<TABLE class=leftframetable cellSpacing=0 cellPadding=0 width="97%"
					align=right border=0>
					<TBODY>
						<TR>
							<TD height="25"
								style="background: url(images/left_tt.gif) no-repeat">
								<table width="100%" border="0" cellspacing="0" cellpadding="0">
									<tr>
										<TD width="20"></TD>
										<TD class=STYLE1 height=25>系统管理</TD>
									</tr>
								</table>
							</TD>
						</TR>
						<TR>
							<TD>
								<TABLE cellSpacing=0 cellPadding=0 width="100%" border=0>
									<TBODY>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="pwd.jsp" target=main>修改密码</A></TD>
										</TR>
										<TR>
											<TD width="2%"><IMG src="images/closed.gif"></TD>
											<TD height=23><A href="#" onclick="loginout();" target=main>退出系统</A></TD>
										</TR>
									</TBODY>
								</TABLE>
							</TD>
						</TR>
					</TBODY>
				</TABLE>
			</td>
		</tr>
<%
	}
%>

		<tr>
			<td height="5" background="images/tableline_bottom.jpg"></td>
		</tr>
	</table>
</body>
</html>

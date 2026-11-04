<%@page contentType="text/html; charset=gb2312"%>
<jsp:useBean id="db" scope="page" class="com.hospital.Dbcoon" />

<%
	String path = request.getContextPath();
	String basePath = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + path;
	String applicationPath = basePath + "/" + "application";
%>
<%@ page import="java.sql.*"%>
<html>
	<body class="h-business">
		<script language="javascript">
function checkform() {
	if (document.addForm.kebie.value == ""
			|| document.addForm.number.value == "") {
		alert("请输入完整信息！");
		return false;
	} else {
		alert("修改成功！");
		return true;
	}
}
</script>



		<link rel="stylesheet" type="text/css" media="all"
			href="<%=path%>/images/css1/ioa.css" />
		<script type="text/javascript" src="<%=path%>/calendar/WdatePicker.js"></script>		
		<%
			request.setCharacterEncoding("gb2312");
		%>


		<head>
			<title>修改病人信息</title>
		
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>

		<FORM Action="savecost.jsp" Method="post" name="addForm">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">

			<%
				int id = 0;
				try{ id = Integer.parseInt(request.getParameter("id")); }catch(Exception ignore){}
				ResultSet rs = db.executeQuery("select * from cost where id=?", id);
				while (rs != null && rs.next()) {
			%>
			<input type="hidden" name="id" maxlength="32" class=inputnormal
				value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("id"))%>">
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
									收费管理 > 修改收费信息
								</td>
							</tr>
						</table>
						<table width="100%" border="0" cellpadding="1" cellspacing="1"
							class="table-border margb5">
							<tr>
								<td width="14%" align="right" class="COLLECTION">
									科别：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="kebie" maxlength="32" class=inputnormal
										value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("kebie"))%>">
									<font color="red">*</font>
								</td>


							</tr>

							<tr>

								<td width="14%" align="right" class="COLLECTION">
									病床号：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="number" maxlength="32" class="inputnormal"
										value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("number"))%>">
									<font color="red">*</font>
								</td>

							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									病人姓名：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="name" maxlength="32" class="inputnormal"
										value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("name"))%>">
								</td>
							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									收费项目：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="xiangmu" maxlength="32"
										class="inputnormal" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("xiangmu"))%>">
								</td>
							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									单价：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="danjia" maxlength="32"
										class="inputnormal" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("danjia"))%>">
								</td>
							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									数量：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="shuliang" maxlength="32"
										class="inputnormal" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("shuliang"))%>">
								</td>
							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									金额：
								</td>
								<td width="36%" align="left" class="even padl5">
									<input type=text name="jine" maxlength="32"
										class="inputnormal" value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("jine"))%>">
								</td>
							</tr>
							<tr>

								<td width="14%" align="right" class="COLLECTION">
									日期：
								</td>
								<td width="36%" align="left" class="even padl5">
									 
									<input class="Wdate" type="text" name="riqi"  maxlength="32"
					onfocus="WdatePicker({readOnly:true})"  value="<%=com.hospital.WebUtil.htmlEscape(rs.getString("riqi"))%>"/>
								</td>
							</tr>
							
						</table>
						<table width="100%" border="0" cellspacing="0" cellpadding="0">
							<tr>
								<td width="50%" align="right" class="padr5">
									<input type="submit" onclick="javascript:return(checkform());"
										name="button" value="保 存" class="button">
								</td>
								<td width="50%" align="left" class="padl5">
									<input name="button1" type="button" class="button"
										onClick="history.go(-1);" value="返 回">
								</td>
							</tr>
						</table>
					</td>
				</tr>
			</table>

			<%
				}
				rs.close();
			%>






		</form>


		<br>
		<br>
		<br>
		<br>

	</body>
</html>

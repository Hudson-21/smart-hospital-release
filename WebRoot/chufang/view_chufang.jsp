<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}

String cf = request.getParameter("cf");
if(cf==null || "".equals(cf.trim())){ out.print("参数缺失"); return; }

ResultSet rsH = a.executeQuery("SELECT cf_number,patient_name,doctor,kebie,zongjia,state,ctime,beizhu FROM chufang WHERE cf_number=?", cf.trim());
String patient="", doctor="", kb="", state="", ctime="", beizhu="";
double zongjia=0;
if(rsH.next()){
    patient=rsH.getString("patient_name")==null?"":rsH.getString("patient_name");
    doctor =rsH.getString("doctor")==null?"":rsH.getString("doctor");
    kb     =rsH.getString("kebie")==null?"":rsH.getString("kebie");
    state  =rsH.getString("state")==null?"":rsH.getString("state");
    ctime  =rsH.getString("ctime")==null?"":rsH.getString("ctime");
    beizhu =rsH.getString("beizhu")==null?"":rsH.getString("beizhu");
    zongjia=rsH.getDouble("zongjia");
}
ResultSet rsD = a.executeQuery("SELECT yao_code,yao_name,price,shuliang,jine,usage_note FROM cf_item WHERE cf_number=? ORDER BY id", cf.trim());
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>处方详情 <%=com.hospital.WebUtil.htmlEscape(cf)%></title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="80%" border="0" cellspacing="0" cellpadding="0" class="pad5" align="center">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">处方详情</td></tr>
</table>

<table width="100%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5">
<tr><td width="20%" align="right" class="COLLECTION">处方号：</td><td><%=com.hospital.WebUtil.htmlEscape(cf)%></td></tr>
<tr><td align="right" class="COLLECTION">病人：</td><td><%=com.hospital.WebUtil.htmlEscape(patient)%>（<%=com.hospital.WebUtil.htmlEscape(kb)%>）</td></tr>
<tr><td align="right" class="COLLECTION">开方医生：</td><td><%=com.hospital.WebUtil.htmlEscape(doctor)%></td></tr>
<tr><td align="right" class="COLLECTION">开方时间：</td><td><%=com.hospital.WebUtil.htmlEscape(ctime)%></td></tr>
<tr><td align="right" class="COLLECTION">状态：</td><td><b><%=com.hospital.WebUtil.htmlEscape(state)%></b></td></tr>
<tr><td align="right" class="COLLECTION">备注：</td><td><%=com.hospital.WebUtil.htmlEscape(beizhu)%></td></tr>
</table>

<table width="100%" border="0" cellpadding="2" cellspacing="1" class="table-border margb5">
<tr style="background:#d0e6ff;">
<th>#</th><th>药品编码</th><th>药品名称</th><th>单价</th><th>数量</th><th>金额</th><th>用法用量</th>
</tr>
<%
double tot=0; int idxNo=0;
while(rsD.next()){
    idxNo++;
    String yc=rsD.getString("yao_code"), yn=rsD.getString("yao_name"),
           ug=rsD.getString("usage_note")==null?"":rsD.getString("usage_note");
    double pr=rsD.getDouble("price"); int q=rsD.getInt("shuliang"); double je=rsD.getDouble("jine");
    tot+=je;
%>
<tr>
<td align="center"><%=idxNo%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(yc)%></td>
<td align="center"><%=com.hospital.WebUtil.htmlEscape(yn)%></td>
<td align="center">¥<%=String.format("%.2f",pr)%></td>
<td align="center"><%=q%></td>
<td align="center">¥<%=String.format("%.2f",je)%></td>
<td align="center" style="font-size:12px;"><%=com.hospital.WebUtil.htmlEscape(ug)%></td>
</tr>
<%
}
a.close();
%>
<tr style="background:#fff8dc;font-weight:bold;">
<td colspan="5" align="right">合计：</td>
<td align="center">¥<%=String.format("%.2f",tot)%></td>
<td></td>
</tr>
</table>
</td></tr></table>
</body>
</html>
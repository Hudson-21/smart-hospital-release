<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可修改排班');history.back();</script>"); return;
}

String idS = request.getParameter("id");
int id = 0; try{ id=Integer.parseInt(idS); }catch(Exception e){ id=0; }
if(id<=0){ out.print("<script>alert('参数错误');history.back();</script>"); return; }

String msg = "";
String dcode="",dname="",kb="",shift="";
java.sql.Date wd=null;
int total=20,remain=20;

if("POST".equals(request.getMethod())){
    request.setCharacterEncoding("UTF-8");
    String sname = request.getParameter("doctor_name");
    String scode = request.getParameter("doctor_code");
    String skb   = request.getParameter("kebie");
    String sdate = request.getParameter("work_date");
    String sshift= request.getParameter("shift");
    int sTotal   = 0; try{ sTotal=Integer.parseInt(request.getParameter("total")); }catch(Exception e){}
    int sRemain  = 0; try{ sRemain=Integer.parseInt(request.getParameter("remain")); }catch(Exception e){}
    java.sql.Date sWD=null; try{ sWD=java.sql.Date.valueOf(sdate); }catch(Exception ex){}
    if(sname==null||sname.trim().equals("")||sWD==null||sTotal<=0||sRemain<0||sRemain>sTotal){
        msg = "<span style='color:red'>请检查输入（日期合法、号源非负且不超过总数）</span>";
    } else {
        int r = a.executeUpdate("UPDATE paiban SET doctor_code=?,doctor_name=?,kebie=?,work_date=?,shift=?,total=?,remain=? WHERE id=?",
                scode,sname.trim(),skb,sWD,sshift,sTotal,sRemain,id);
        if(r>0){
            // 审计
            com.hospital.Audit.log(loginname,"修改排班","id="+id+", "+sname.trim()+"/"+skb+"/"+sWD+"/"+sshift+", total="+sTotal+", remain="+sRemain);
            response.sendRedirect("list_paiban.jsp");
            return;
        } else {
            msg = "<span style='color:red'>保存失败，请重试</span>";
        }
    }
}

// GET 或失败回填
ResultSet rs = a.executeQuery("SELECT doctor_code,doctor_name,kebie,work_date,shift,total,remain FROM paiban WHERE id=?", id);
if(rs.next()){
    dcode = rs.getString("doctor_code")==null?"":rs.getString("doctor_code");
    dname = rs.getString("doctor_name")==null?"":rs.getString("doctor_name");
    kb    = rs.getString("kebie")==null?"":rs.getString("kebie");
    wd    = rs.getDate("work_date");
    shift = rs.getString("shift")==null?"":rs.getString("shift");
    total = rs.getInt("total");
    remain= rs.getInt("remain");
}
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>修改排班</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">排班管理 > 修改排班（ID=<%=id%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" style="font-size:14px"><%=msg%></p><%}%>
<form method="post" action="modify_paiban.jsp" name="modForm" onsubmit="return check();">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<input type="hidden" name="id" value="<%=id%>"/>
<table width="60%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">医生姓名：</td>
<td><input type="text" name="doctor_name" value="<%=com.hospital.WebUtil.htmlEscape(dname)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">工号：</td>
<td><input type="text" name="doctor_code" value="<%=com.hospital.WebUtil.htmlEscape(dcode)%>" style="width:220px" readonly/></td></tr>
<tr><td align="right" class="COLLECTION">科室：</td>
<td><input type="text" name="kebie" value="<%=com.hospital.WebUtil.htmlEscape(kb)%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">出诊日期：</td>
<td><input type="date" name="work_date" value="<%=wd%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">时段：</td>
<td><select name="shift" style="width:220px">
<option value="上午" <%=shift.equals("上午")?"selected":""%>>上午</option>
<option value="下午" <%=shift.equals("下午")?"selected":""%>>下午</option>
</select></td></tr>
<tr><td align="right" class="COLLECTION">总号源：</td>
<td><input type="number" name="total" min="1" max="500" value="<%=total%>" style="width:220px"/></td></tr>
<tr><td align="right" class="COLLECTION">剩余号源：</td>
<td><input type="number" name="remain" min="0" max="<%=total%>" value="<%=remain%>" style="width:220px"/></td></tr>
<tr><td colspan="2" align="center">
<input type="submit" value="保存" style="width:120px;height:28px"/>
<input type="button" value="返回" onclick="history.go(-1)" style="width:120px;height:28px"/>
</td></tr>
</table>
</form>
</td></tr></table>
<script type="text/javascript">
function check(){
  var t=parseInt(document.forms["modForm"].total.value);
  var r=parseInt(document.forms["modForm"].remain.value);
  if(!(t>0)){ alert("总号源必须为正整数"); return false; }
  if(r<0 || r>t){ alert("剩余号源必须在 0~总号 之间"); return false; }
  return true;
}
</script>
</body>
</html>
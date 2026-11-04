<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype)){
    out.print("<script>alert('仅管理员可删除排班');history.back();</script>"); return;
}
int id = 0; try{ id=Integer.parseInt(request.getParameter("id")); }catch(Exception e){ id=0; }
if(id<=0){
    out.print("<script>alert('参数错误');history.back();</script>"); return;
}

// 校验：已有人挂号的排班不允许删除（防历史数据黑洞）
ResultSet rs = a.executeQuery("SELECT COUNT(*) AS cnt FROM guahao WHERE doctor=(SELECT doctor_name FROM paiban WHERE id=?) AND riqi=(SELECT DATE_FORMAT(work_date,'%Y-%m-%d') FROM paiban WHERE id=?)",
        id, id);
int cnt = 0; if(rs.next()) cnt = rs.getInt("cnt");
if(cnt > 0){
    out.print("<script>alert('该排班已有 "+cnt+" 条挂号记录，不能删除');history.back();</script>"); return;
}

int r = a.executeUpdate("DELETE FROM paiban WHERE id=?", id);
if(r>0){
    com.hospital.Audit.log(loginname,"删除排班","id="+id);
}
response.sendRedirect("list_paiban.jsp");
%>
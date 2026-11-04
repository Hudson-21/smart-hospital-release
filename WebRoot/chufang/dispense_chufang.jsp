<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
/* ============================================================================
 *  处方流转：发药 / 退药
 * ----------------------------------------------------------------------------
 *  act=dispense  待发药 -> 已发药
 *  act=return    已发药 -> 已退药（同时把药品库存加回去）
 *
 *  状态机：待发药 --发药--> 已发药 --退药--> 已退药
 *  约束：每一步都带 WHERE state=? 条件，靠 UPDATE 影响行数判断是否合法流转，
 *        避免并发下重复发药/重复退药导致库存错乱；全程单事务。
 * ========================================================================== */
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"管理员".equals(usertype) && !"医生".equals(usertype)){
    out.print("<script>alert('仅管理员/医生可操作处方流转');history.back();</script>"); return;
}
if(!"POST".equals(request.getMethod())){ out.print("<script>alert('请通过页面按钮操作');history.back();</script>"); return; }
request.setCharacterEncoding("UTF-8");

String cf  = request.getParameter("cf");
String act = request.getParameter("act");
if(cf==null || cf.trim().isEmpty() || act==null){ out.print("<script>alert('参数缺失');history.back();</script>"); return; }
if(!"dispense".equals(act) && !"return".equals(act)){ out.print("<script>alert('不支持的操作');history.back();</script>"); return; }
cf = cf.trim();

String msg = "";
String msgColor = "green";

try{
    synchronized(com.hospital.Dbcoon.class){
        Connection cn = a.getConnection();
        cn.setAutoCommit(false);
        try{
            if("dispense".equals(act)){
                // ---- 发药：只有「待发药」能发 ----
                java.sql.PreparedStatement ps = cn.prepareStatement(
                    "UPDATE chufang SET state='已发药' WHERE cf_number=? AND state='待发药'");
                ps.setString(1, cf);
                int n = ps.executeUpdate();
                ps.close();
                if(n == 0){
                    throw new RuntimeException("该处方当前不是「待发药」状态，无法发药");
                }
                cn.commit();
                com.hospital.Audit.log(loginname, "处方发药", "处方号 " + cf);
                msg = "处方 " + cf + " 已发药完成。";

            } else {
                // ---- 退药：只有「已发药」能退，且要回滚库存 ----
                java.sql.PreparedStatement ps = cn.prepareStatement(
                    "UPDATE chufang SET state='已退药' WHERE cf_number=? AND state='已发药'");
                ps.setString(1, cf);
                int n = ps.executeUpdate();
                ps.close();
                if(n == 0){
                    throw new RuntimeException("只有「已发药」的处方才能退药");
                }

                // 把该处方每种药的数量加回库存
                java.sql.PreparedStatement psD = cn.prepareStatement(
                    "SELECT yao_code, shuliang FROM cf_item WHERE cf_number=?");
                psD.setString(1, cf);
                ResultSet rsD = psD.executeQuery();
                List<Object[]> back = new ArrayList<Object[]>();
                while(rsD.next()){
                    back.add(new Object[]{ rsD.getString("yao_code"), rsD.getInt("shuliang") });
                }
                rsD.close(); psD.close();

                java.sql.PreparedStatement psB = cn.prepareStatement(
                    "UPDATE yaoku SET stock = stock + ? WHERE code = ?");
                for(Object[] r : back){
                    psB.setInt(1, (Integer) r[1]);
                    psB.setString(2, (String) r[0]);
                    psB.executeUpdate();
                }
                psB.close();

                cn.commit();
                com.hospital.Audit.log(loginname, "处方退药", "处方号 " + cf + " 回滚药品种类=" + back.size());
                msg = "处方 " + cf + " 已退药，并已回滚 " + back.size() + " 种药品库存。";
            }
        }catch(Exception ex){
            try{ cn.rollback(); }catch(Exception ignore){}
            msg = "操作失败：" + ex.getMessage() + "（已回滚，库存未变动）";
            msgColor = "#c0392b";
        }finally{
            try{ cn.setAutoCommit(true); }catch(Exception ignore){}
        }
    }
}catch(Exception ex){
    msg = "操作失败：" + ex.getMessage();
    msgColor = "#c0392b";
}
a.close();
%>
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<title>处方流转结果</title>
<link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" />
<style>
  body { font-family:"Microsoft YaHei",Arial,sans-serif; background:#f3f6fb; margin:0; }
  .box { max-width:520px; margin:80px auto; background:#fff; border-radius:12px;
         padding:32px 40px; text-align:center; box-shadow:0 4px 20px rgba(25,118,210,.08); }
  .msg { font-size:15px; line-height:1.8; color:<%=msgColor%>; font-weight:bold; }
  .acts { margin-top:24px; }
  .acts a { display:inline-block; padding:8px 22px; margin:0 6px; border-radius:8px;
            text-decoration:none; font-size:14px; background:#03A8F6; color:#fff; }
  .acts a.ghost { background:#fff; color:#546e7a; border:1px solid #d5dde6; }
  .hint { margin-top:14px; font-size:12px; color:#90a4ae; }
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business">
<div class="box">
    <div class="msg"><%=com.hospital.WebUtil.htmlEscape(msg)%></div>
    <div class="acts">
        <a href="list_chufang.jsp">返回处方列表</a>
        <a class="ghost" href="javascript:history.back()">返回上一页</a>
    </div>
    <div class="hint">3 秒后自动返回处方列表…</div>
</div>
<script>setTimeout(function(){ location.href='list_chufang.jsp'; }, 3000);</script>
</body>
</html>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"医生".equals(usertype)){
    out.print("<script>alert('仅医生可开方');history.back();</script>"); return;
}
if(!"POST".equals(request.getMethod())){ out.print("<script>alert('请通过表单提交');history.back();</script>"); return; }
request.setCharacterEncoding("UTF-8");
String pname   = request.getParameter("patient_name");
String beizhu  = request.getParameter("beizhu");

if(pname==null||"".equals(pname.trim())){
    out.print("<script>alert('请选择病人');history.back();</script>"); return;
}

// 收集明细
List<Object[]> rows = new ArrayList<Object[]>();
for(int i=0; ; i++){
    String code = request.getParameter("code_"+i);
    if(code==null) break;
    if("".equals(code)) continue;
    String qtyS  = request.getParameter("qty_"+i);
    String usage = request.getParameter("usage_"+i);
    int qty = 0; try{ qty=Integer.parseInt(qtyS); }catch(Exception e){ qty=0; }
    if(qty<=0) continue;
    rows.add(new Object[]{code, qty, usage==null?"":usage});
}
if(rows.isEmpty()){
    out.print("<script>alert('请至少添加一行药品');history.back();</script>"); return;
}

// ===== 配伍禁忌检查：本次处方内药品两两组合，比对 drug_interaction 规则表 =====
java.util.List<String> banned = new ArrayList<String>();   // 禁忌：拦截开方
java.util.List<String> warned = new ArrayList<String>();   // 慎用/注意：放行但提示
try{
    for(int i = 0; i < rows.size(); i++){
        for(int j = i + 1; j < rows.size(); j++){
            String ca = (String) rows.get(i)[0];
            String cb = (String) rows.get(j)[0];
            if(ca.equals(cb)) continue;
            ResultSet rsI = a.executeQuery(
                "SELECT level,description,advice," +
                "(SELECT name FROM yaoku WHERE code=drug_a) na," +
                "(SELECT name FROM yaoku WHERE code=drug_b) nb " +
                "FROM drug_interaction WHERE active=1 AND " +
                "((drug_a=? AND drug_b=?) OR (drug_a=? AND drug_b=?))",
                ca, cb, cb, ca);
            while(rsI.next()){
                String na = rsI.getString("na")==null?ca:rsI.getString("na");
                String nb = rsI.getString("nb")==null?cb:rsI.getString("nb");
                String line = na + " × " + nb + "：" + rsI.getString("description")
                            + "　【建议】" + rsI.getString("advice");
                if("禁忌".equals(rsI.getString("level"))) banned.add(line);
                else warned.add(line);
            }
            rsI.close();
        }
    }
}catch(Exception ignore){ /* 规则表不可用时静默降级，不影响正常开方 */ }

// 命中禁忌 -> 直接拦截，不写任何数据
if(!banned.isEmpty()){
    com.hospital.Audit.log(loginname, "开方被拦截",
        "病人=" + pname + " 命中配伍禁忌 " + banned.size() + " 项");
%>
<html>
<head><meta charset="UTF-8"><title>开方被拦截</title>
<link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" />
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="72%" border="0" cellpadding="12" cellspacing="1" class="table-border" align="center">
<tr><td style="background:#ffe6e6;color:#c0392b;font-size:15px;font-weight:bold;">
⚠ 开方已被系统拦截：检测到 <%=banned.size()%> 项配伍禁忌
</td></tr>
<tr><td style="background:#ffffff;font-size:13px;line-height:1.9;color:#444;">
<% for(String b : banned){ %>
    <div style="margin:8px 0;">· <%=com.hospital.WebUtil.htmlEscape(b)%></div>
<% } %>
    <div style="margin-top:16px;color:#888;">请调整用药方案后重新提交，本次操作未写入任何数据。</div>
</td></tr>
</table>
<p align="center" style="margin-top:24px;">
    <a href="javascript:history.back()">返回修改处方</a>
</p>
</body>
</html>
<%
    return;
}

// 拿病人科室（用作 cost/guahao）
String pkb="";
ResultSet rsk = a.executeQuery("SELECT kebie FROM patient WHERE name=? AND doctor=?", pname.trim(), loginname);
if(rsk.next()) pkb = rsk.getString("kebie")==null?"":rsk.getString("kebie");
rsk.close();

// ===== 事务内：写处方头 + 写明细 + 扣库存 + 写 cost 草稿 =====
String msg = "";
try{
    synchronized(com.hospital.Dbcoon.class){
        Connection cn = a.getConnection();
        cn.setAutoCommit(false);
        try{
            String cfNumber = "CF"+System.currentTimeMillis();
            // 1) 头表
            java.sql.PreparedStatement psH = cn.prepareStatement(
                "INSERT INTO chufang(cf_number,patient_name,doctor,kebie,zongjia,state,ctime,beizhu) VALUES(?,?,?,?,?,?,NOW(),?)");
            psH.setString(1, cfNumber);
            psH.setString(2, pname.trim());
            psH.setString(3, loginname);
            psH.setString(4, pkb);
            psH.setDouble(5, 0); // 后面回写
            psH.setString(6, "待发药");
            psH.setString(7, beizhu==null?"":beizhu);
            psH.executeUpdate();
            psH.close();

            double total = 0;
            // 2) 明细 + 3) 扣库存 + 4) 写 cost 草稿
            for(Object[] row : rows){
                String code = (String)row[0];
                int qty = (Integer)row[1];
                String usage = (String)row[2];
                java.sql.PreparedStatement psY = cn.prepareStatement(
                    "SELECT name,spec,unit,price,stock FROM yaoku WHERE code=? AND active=1 FOR UPDATE");
                psY.setString(1, code);
                java.sql.ResultSet rsY = psY.executeQuery();
                if(!rsY.next()){
                    rsY.close(); psY.close(); throw new RuntimeException("药品 "+code+" 不存在或已下架");
                }
                String yaoName = rsY.getString("name");
                double price = rsY.getDouble("price");
                int stock = rsY.getInt("stock");
                rsY.close(); psY.close();

                if(stock < qty){
                    throw new RuntimeException("药品「"+yaoName+"」库存不足（库存 "+stock+" < 需开 "+qty+"）");
                }
                double jine = price * qty;
                total += jine;

                // 写明细
                java.sql.PreparedStatement psI = cn.prepareStatement(
                    "INSERT INTO cf_item(cf_number,yao_code,yao_name,price,shuliang,jine,usage_note) VALUES(?,?,?,?,?,?,?)");
                psI.setString(1, cfNumber);
                psI.setString(2, code);
                psI.setString(3, yaoName);
                psI.setDouble(4, price);
                psI.setInt(5, qty);
                psI.setDouble(6, jine);
                psI.setString(7, usage);
                psI.executeUpdate();
                psI.close();

                // 扣库存
                java.sql.PreparedStatement psK = cn.prepareStatement(
                    "UPDATE yaoku SET stock=stock-? WHERE code=?");
                psK.setInt(1, qty);
                psK.setString(2, code);
                psK.executeUpdate();
                psK.close();

                // 写 cost 草稿（关联到这个处方）
                String bedNo = "B"+System.currentTimeMillis();
                java.sql.PreparedStatement psC = cn.prepareStatement(
                    "INSERT INTO cost(number,kebie,name,xiangmu,danjia,shuliang,jine,riqi,state) VALUES(?,?,?,?,?,?,?,?,?)");
                psC.setString(1, bedNo);
                psC.setString(2, pkb);
                psC.setString(3, pname.trim());
                psC.setString(4, "药品:"+yaoName);
                psC.setString(5, String.format("%.2f",price));
                psC.setString(6, String.valueOf(qty));
                psC.setString(7, String.format("%.2f",jine));
                psC.setString(8, new java.sql.Date(System.currentTimeMillis()).toString());
                psC.setString(9, "草稿");
                psC.executeUpdate();
                psC.close();
            }

            // 5) 回写总价
            java.sql.PreparedStatement psU = cn.prepareStatement(
                "UPDATE chufang SET zongjia=? WHERE cf_number=?");
            psU.setDouble(1, total);
            psU.setString(2, cfNumber);
            psU.executeUpdate();
            psU.close();

            cn.commit();
            com.hospital.Audit.log(loginname,"开方成功","处方号 "+cfNumber+" 病人="+pname+" 药品种类="+rows.size()+" 合计="+total);
            StringBuilder warnHtml = new StringBuilder();
            for(String w : warned){
                warnHtml.append("<div style='margin:5px 0;'>· ")
                        .append(com.hospital.WebUtil.htmlEscape(w)).append("</div>");
            }
            msg = "<span style='color:green'>处方保存成功！<br>处方号："+cfNumber+"<br>药品："+rows.size()+" 种，合计金额：¥"+String.format("%.2f",total)+"<br>已自动扣减库存并生成 "+rows.size()+" 条费用草稿，请到费用页面确认结算。</span>"
                + (warned.isEmpty() ? ""
                   : "<div style='margin:18px auto 0;max-width:640px;padding:12px 16px;background:#fff8e1;border-left:3px solid #f39c12;text-align:left;font-size:13px;color:#8a5300;line-height:1.8;'>"
                     + "<b>用药提醒（"+warned.size()+" 项 · 非禁忌，已放行）</b>" + warnHtml + "</div>");
        }catch(Exception ex){
            try{ cn.rollback(); }catch(Exception ignore){}
            msg = "<span style='color:red'>开方失败："+ex.getMessage()+"（已回滚库存）</span>";
        }finally{
            try{ cn.setAutoCommit(true); }catch(Exception ignore){}
        }
    }
}catch(Exception ex){
    msg = "<span style='color:red'>开方失败："+ex.getMessage()+"</span>";
}

// 用一个 GET 表单把 msg 回传到列表页不方便，直接刷本页显示
request.setAttribute("MSG", msg);
%>
<html>
<head><meta charset="UTF-8"><title>开方结果</title>
<link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" />
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<p align="center" style="font-size:15px;margin-top:30px;"><%=msg%></p>
<p align="center" style="margin-top:20px;">
<a href="add_chufang.jsp" style="margin-right:20px;">再开一张</a>
<a href="../chufang/list_chufang.jsp">查看历史处方</a>
</p>
</body>
</html>
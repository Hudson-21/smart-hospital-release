<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
if(!"医生".equals(usertype)){
    out.print("<script>alert('仅医生可开方');history.back();</script>"); return;
}

String msg="";

// 拉药品字典 + 病人列表
ResultSet rsY = a.executeQuery("SELECT code,name,spec,unit,price,stock FROM yaoku WHERE active=1 AND stock>0 ORDER BY category,name");
StringBuilder jsY = new StringBuilder();
java.util.Map<String,Object[]> yaoMap = new java.util.LinkedHashMap<String,Object[]>();
while(rsY.next()){
    String code=rsY.getString("code"), name=rsY.getString("name"),
           spec=rsY.getString("spec")==null?"":rsY.getString("spec"),
           unit=rsY.getString("unit")==null?"":rsY.getString("unit");
    double price=rsY.getDouble("price"); int stock=rsY.getInt("stock");
    yaoMap.put(code, new Object[]{code,name,spec,unit,price,stock});
    jsY.append("{code:'").append(code).append("',name:'").append(name.replace("'","").replace("\\","\\\\"))
       .append("',spec:'").append(spec.replace("'","").replace("\\","\\\\"))
       .append("',unit:'").append(unit).append("',price:").append(price).append(",stock:").append(stock).append("},");
}
if(jsY.length()>0) jsY.setLength(jsY.length()-1);
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>开方开药</title>
<style>
.yao-row{display:flex;gap:6px;align-items:center;margin-bottom:6px;}
.yao-row .code{width:90px;} .yao-row .qty{width:60px;} .yao-row .price{width:80px;color:#888;}
.yao-row .usage{width:180px;}
.add-btn{background:#27ae60;color:#fff;border:none;border-radius:3px;padding:4px 10px;cursor:pointer;}
.del-btn{background:#e74c3c;color:#fff;border:none;border-radius:3px;padding:4px 10px;cursor:pointer;}
.tip{font-size:12px;color:#888;margin:6px 0;}
#sumRow{font-weight:bold;font-size:14px;margin:14px 0;color:#1976d2;}
</style>

<link rel="stylesheet" href="<%=request.getContextPath()%>/css/hospital-ui.css?v=20261104">
<script src="<%=request.getContextPath()%>/js/hospital-ui.js?v=20261103" defer></script>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body class="h-business" bgcolor="#ffffff"><br>
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="pad5">
<tr><td valign="top" align="left" class="pad5">
<table width="100%" border="0" cellspacing="0" cellpadding="0" class="dqbg margb5">
<tr><td width="2%" align="right" class="pad05"><img src="<%=request.getContextPath()%>/images/img2.gif" width="16" height="16"></td>
<td width="98%" align="left" class="lan13b">医生工作台 > 开方开药（医生：<%=loginname%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" style="font-size:14px"><%=msg%></p><%}%>

<form method="post" action="save_chufang.jsp" id="cfForm">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<table width="90%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="14%" align="right" class="COLLECTION">选择病人：</td>
<td>
  <select name="patient_name" id="patientSel" style="width:240px" required>
    <option value="">--请选择本人负责的病人--</option>
<%
ResultSet rsp = a.executeQuery("SELECT name,kebie FROM patient WHERE doctor=?", loginname);
while(rsp.next()){
    out.print("<option value=\""+rsp.getString("name")+"\">"+rsp.getString("name")+"（"+rsp.getString("kebie")+"）</option>");
}
%>
  </select>
</td></tr>
<tr><td align="right" class="COLLECTION">处方备注：</td>
<td><input type="text" name="beizhu" style="width:300px" placeholder="可选：医嘱/注意事项"/></td></tr>
<tr><td colspan="2" class="tip">下方添加药品（可加多行）。库存不足/未列出药品无法添加。</td></tr>
<tr><td colspan="2">
  <div id="yaoBox">
    <div class="yao-row">
      <select name="code_0" class="code" onchange="yaoSel(0)">
        <option value="">--选药品--</option>
      </select>
      <span class="price" id="price_0">¥0</span>
      <span style="color:#888;">库存:</span><span id="stock_0">-</span>
      <span style="color:#888;">×</span>
      <input type="number" name="qty_0" class="qty" min="1" value="1" oninput="refreshSum()"/>
      <input type="text"   name="usage_0" class="usage" placeholder="用法：口服/每日3次"/>
      <button type="button" class="del-btn" onclick="this.parentNode.remove();refreshSum();">删除</button>
    </div>
  </div>
  <button type="button" class="add-btn" onclick="addYao()">+ 添加一行药品</button>
</td></tr>
<tr><td colspan="2" id="sumRow">合计金额：¥0.00</td></tr>
<tr><td colspan="2" class="tip" style="color:#e67e22;">
  ⚠ 保存时会自动检查药品配伍禁忌：命中「<b>禁忌</b>」将被拦截（不写入任何数据），
  命中「<b>慎用</b>／<b>注意</b>」会提示但允许保存。
</td></tr>
<tr><td colspan="2" align="center">
  <button type="submit" style="background:linear-gradient(135deg,#1976d2,#2196f3);color:#fff;border:none;border-radius:5px;padding:8px 30px;font-size:14px;cursor:pointer;" onclick="return preSubmit();">保存处方</button>
</td></tr>
</table>
</form>
</td></tr></table>

<script type="text/javascript">
var yaoData = [<%=jsY.toString()%>];

function yaoSel(idx){
  var sel=document.getElementsByName("code_"+idx)[0];
  var opt=sel.options[sel.selectedIndex];
  var price=opt.getAttribute("data-price")||0, stock=opt.getAttribute("data-stock")||0;
  document.getElementById("price_"+idx).innerHTML="¥"+price;
  document.getElementById("stock_"+idx).innerHTML=stock;
  refreshSum();
}

function refreshSum(){
  var rows=document.querySelectorAll(".yao-row"), sum=0;
  rows.forEach(function(r){
    var sel=r.querySelector("select"), qty=r.querySelector("input[type=number]");
    if(sel && sel.value && qty){
      var opt=sel.options[sel.selectedIndex];
      var price=parseFloat(opt.getAttribute("data-price")||0);
      var stock=parseInt(opt.getAttribute("data-stock")||0);
      var q=parseInt(qty.value||0);
      if(q>stock){ qty.style.color="red"; qty.title="库存不足"; } else { qty.style.color=""; qty.title=""; }
      sum += price * q;
    }
  });
  document.getElementById("sumRow").innerHTML="合计金额：¥"+sum.toFixed(2);
}

function fillSelect(sel){
  while(sel.options.length>1) sel.remove(1);
  yaoData.forEach(function(y){
    var o=document.createElement("option");
    o.value=y.code; o.text=y.name+"（"+y.spec+"，¥"+y.price+"）";
    o.setAttribute("data-price",y.price); o.setAttribute("data-stock",y.stock); o.setAttribute("data-name",y.name); o.setAttribute("data-unit",y.unit);
    sel.appendChild(o);
  });
}

function addYao(){
  var box=document.getElementById("yaoBox"), idx=box.children.length;
  var div=document.createElement("div"); div.className="yao-row";
  div.innerHTML='<select name="code_'+idx+'" class="code" onchange="yaoSel('+idx+')"><option value="">--选药品--</option></select>'
    +'<span class="price" id="price_'+idx+'">¥0</span>'
    +'<span style="color:#888;">库存:</span><span id="stock_'+idx+'">-</span>'
    +'<span style="color:#888;">×</span>'
    +'<input type="number" name="qty_'+idx+'" class="qty" min="1" value="1" oninput="refreshSum()"/>'
    +'<input type="text"   name="usage_'+idx+'" class="usage" placeholder="用法：口服/每日3次"/>'
    +'<button type="button" class="del-btn" onclick="this.parentNode.remove();refreshSum();">删除</button>';
  box.appendChild(div);
  fillSelect(div.querySelector("select"));
}

function preSubmit(){
  if(!document.getElementById("patientSel").value){ alert("请选择病人"); return false; }
  var rows=document.querySelectorAll(".yao-row"), picked=0;
  rows.forEach(function(r){
    var sel=r.querySelector("select"), qty=r.querySelector("input[type=number]");
    if(sel.value && parseInt(qty.value)>0) picked++;
  });
  if(picked===0){ alert("请至少添加一行药品"); return false; }
  var ok=confirm("确认开方？开方后将自动扣库存并生成费用。");
  if(!ok) return false;
  return true;
}

// 初始化第一个下拉
fillSelect(document.getElementsByName("code_0")[0]);
</script>
</body>
</html>
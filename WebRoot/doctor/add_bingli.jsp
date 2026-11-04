<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%
String loginname = (String)session.getAttribute("loginname");
String usertype  = (String)session.getAttribute("usertype");
if(loginname==null||"".equals(loginname)){response.sendRedirect(request.getContextPath()+"/login.jsp");return;}
String myname = loginname;

String msg = "";
if("POST".equals(request.getMethod())){
    request.setCharacterEncoding("UTF-8");
    String pv  = request.getParameter("patient");   // 格式: 姓名||科别
    String zd  = request.getParameter("zhenduan");
    String ct  = request.getParameter("content");
    if(pv==null||"".equals(pv)){ msg = "<span style='color:red'>请选择病人</span>"; }
    else {
        String pname = pv.split("\\|\\|")[0];
        String pkb   = pv.contains("||") ? pv.split("\\|\\|")[1] : "";
        String number= "BL" + System.currentTimeMillis();
        int r = a.executeUpdate("INSERT INTO bingli(patientname,doctor,kebie,zhenduan,content,riqi) VALUES(?,?,?,?,?,?)",
                pname, myname, pkb, zd, ct, new java.sql.Date(System.currentTimeMillis()));
        if(r>0){
            // ===== 医嘱→计费联动：扫描病历正文关键词，自动生成 cost 草稿 =====
            int matchedCnt = 0;
            try{
                ResultSet rsDict = a.executeQuery("SELECT code,name,price FROM cost_dict WHERE active=1");
                java.util.Map<String,Double> dictPrice = new java.util.HashMap<String,Double>();
                java.util.Map<String,String>  dictName = new java.util.HashMap<String,String>();
                while(rsDict.next()){
                    String code = rsDict.getString("code");
                    String name = rsDict.getString("name");
                    double price= rsDict.getDouble("price");
                    dictPrice.put(name, price);
                    dictName.put(name, code);
                }
                rsDict.close();
                java.util.Set<String> alreadyAdded = new java.util.HashSet<String>();
                String bedNumber = "B" + System.currentTimeMillis();
                String content = ct==null?"":ct;
                for(java.util.Map.Entry<String,Double> e : dictPrice.entrySet()){
                    String itemName = e.getKey();
                    if(itemName != null && content.indexOf(itemName) >= 0){
                        String code = dictName.get(itemName);
                        if(alreadyAdded.contains(code)) continue;
                        int qty = 1;
                        double jine = e.getValue() * qty;
                        a.executeUpdate("INSERT INTO cost(number,kebie,name,xiangmu,danjia,shuliang,jine,riqi,state) VALUES(?,?,?,?,?,?,?,?,?)",
                                bedNumber, pkb, pname, itemName, String.format("%.2f",e.getValue()),
                                String.valueOf(qty), String.format("%.2f",jine),
                                new java.sql.Date(System.currentTimeMillis()).toString(), "草稿");
                        com.hospital.Audit.log(myname, "自动生成计费草稿", itemName+" x "+qty+" = "+jine+" (bingli="+number+")");
                        alreadyAdded.add(code);
                        matchedCnt++;
                    }
                }
            }catch(Exception ex){ /* 联动失败不影响病历保存 */ }
            msg = "<span style='color:green'>病历保存成功！"+(matchedCnt>0?"系统已根据病历内容自动生成 "+matchedCnt+" 条计费草稿，请到费用页面查看。":"")+"</span>";
        } else msg = "<span style='color:red'>保存失败，请重试</span>";
    }
}

// 本人负责的病人列表（带出病症 bingzheng，供 AI 生成草稿）
ResultSet rsp = a.executeQuery("SELECT name,kebie,bingzheng FROM patient WHERE doctor=?", myname);
StringBuilder js = new StringBuilder();
while(rsp.next()){
    js.append("['").append(rsp.getString("name")==null?"":rsp.getString("name").replace("'",""))
      .append("','").append(rsp.getString("kebie")==null?"":rsp.getString("kebie").replace("'",""))
      .append("','").append(rsp.getString("bingzheng")==null?"":rsp.getString("bingzheng").replace("\\","\\\\").replace("'",""))
      .append("'],");
}
if(js.length()>0) js.setLength(js.length()-1);
a.close();
%>
<html>
<head><link rel="stylesheet" type="text/css" media="all" href="<%=request.getContextPath()%>/images/css1/ioa.css" /><title>书写病历</title>
<style type="text/css">
.ai-btn{background:linear-gradient(135deg,#7c4dff,#5c6bc0);color:#fff;border:none;border-radius:5px;
  padding:5px 16px;font-size:13px;cursor:pointer;margin-left:8px;}
.ai-btn:hover{opacity:.9;}
.ai-btn:disabled{opacity:.5;cursor:not-allowed;}
.qc-btn{background:linear-gradient(135deg,#1976d2,#2196f3);color:#fff;border:none;border-radius:5px;
  padding:6px 22px;font-size:14px;cursor:pointer;}
.qc-btn:hover{opacity:.9;}
.tip{font-size:12px;color:#888;margin-left:6px;}
#aiStatus{font-size:12px;color:#7c4dff;margin-left:6px;}
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
<td width="98%" align="left" class="lan13b">医生工作台 > 书写病历（医生：<%=myname%>）</td></tr>
</table>
<%if(!"".equals(msg)){%><p align="center" style="font-size:14px"><%=msg%></p><%}%>
<form method="post" action="add_bingli.jsp" id="blForm" onsubmit="return false;">
<input type="hidden" name="_csrf" value="<%=com.hospital.Csrf.token(session)%>">
<table width="70%" border="0" cellpadding="4" cellspacing="1" class="table-border margb5" align="center">
<tr><td width="22%" align="right" class="COLLECTION">选择病人：</td>
<td><select name="patient" id="patientSel" style="width:240px" onchange="fillDesc()">
<option value="">--请选择本人负责的病人--</option>
</select>
</td></tr>
<tr><td align="right" class="COLLECTION">病情简述：</td>
<td><input type="text" id="descInput" placeholder="选择病人自动带出，也可手动输入" style="width:240px"/>
<button type="button" class="ai-btn" id="draftBtn" onclick="aiDraft()">AI 生成草稿</button><span id="aiStatus"></span>
<div class="tip">AI 只生成草稿，最终内容由您审核修改后提交</div>
</td></tr>
<tr><td align="right" class="COLLECTION">诊断结果：</td>
<td><input type="text" name="zhenduan" id="zhenduan" style="width:240px"/></td></tr>
<tr><td align="right" class="COLLECTION">病历内容：</td>
<td><textarea name="content" id="content" rows="8" style="width:320px"></textarea></td></tr>
<tr><td colspan="2" align="center">
<button type="button" class="qc-btn" id="submitBtn" onclick="doSubmit()">AI 质控并保存病历</button>
</td></tr>
</table>
</form>
</td></tr></table>

<script type="text/javascript">
var pts=[<%=js.toString()%>];
var sel=document.getElementById("patientSel");
pts.forEach(function(p){
  var o=document.createElement("option");
  o.value=p[0]+"||"+p[1];
  o.text=p[0]+"（"+p[1]+"）";
  o.setAttribute("data-desc",p[2]||"");
  sel.appendChild(o);
});

// 选择病人后自动带出病情简述
function fillDesc(){
  var o=sel.options[sel.selectedIndex];
  document.getElementById("descInput").value=(o && o.getAttribute("data-desc"))||"";
}

// AI 生成病历草稿：填入表单，医生可继续修改
function aiDraft(){
  var desc=document.getElementById("descInput").value.trim();
  var pv=sel.value;
  if(!desc){ alert("请先选择病人（带出病症）或手动填写病情简述"); return; }
  var pname="",pkb="";
  if(pv){ var arr=pv.split("||"); pname=arr[0]; pkb=arr[1]||""; }
  var btn=document.getElementById("draftBtn"), st=document.getElementById("aiStatus");
  btn.disabled=true; st.textContent="正在生成草稿…";
  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"task=bingli_draft&patient="+encodeURIComponent(pname)
        +"&kebie="+encodeURIComponent(pkb)
        +"&desc="+encodeURIComponent(desc)
  }).then(function(r){return r.json();}).then(function(d){
    btn.disabled=false; st.textContent="";
    if(d.ok){
      document.getElementById("zhenduan").value=d.data.zhenduan;
      document.getElementById("content").value=d.data.content;
      st.textContent=d.data.mode==="mock"?"（模拟模式生成，可填写API Key启用大模型）":"草稿已生成，请审核修改";
    }else{
      st.textContent="";
      alert(d.error||"生成失败，请稍后重试");
    }
  }).catch(function(e){ btn.disabled=false; st.textContent=""; alert("网络异常，请稍后重试"); });
}

// 提交前 AI 质控：有警告时医生确认后仍可提交（提交权永远归医生）
function doSubmit(){
  var pv=sel.value;
  if(!pv){ alert("请选择病人"); return; }
  var zd=document.getElementById("zhenduan").value.trim();
  var ct=document.getElementById("content").value.trim();
  if(!zd){ alert("请填写诊断结果"); return; }
  if(!ct){ alert("请填写病历内容"); return; }
  var btn=document.getElementById("submitBtn");
  btn.disabled=true; btn.textContent="AI 质控中…";
  var pname=pv.split("||")[0];
  fetch("../ai/llm.jsp",{
    method:"POST",
    headers:{"Content-Type":"application/x-www-form-urlencoded"},
    body:"task=bingli_qc&patient="+encodeURIComponent(pname)
        +"&zhenduan="+encodeURIComponent(zd)
        +"&content="+encodeURIComponent(ct)
  }).then(function(r){return r.json();}).then(function(d){
    btn.disabled=false; btn.textContent="AI 质控并保存病历";
    if(!d.ok){ alert(d.error||"质控服务异常，请直接提交"); document.getElementById("blForm").submit(); return; }
    var ws=d.data.warnings||[];
    if(ws.length===0){ document.getElementById("blForm").submit(); return; }
    var ok=confirm("AI 质控发现以下 "+ws.length+" 条提醒：\n\n"+ws.map(function(w,i){return (i+1)+". "+w;}).join("\n")
      +"\n\n仍要保存提交吗？（提交权归医生，确认后提交）");
    if(ok) document.getElementById("blForm").submit();
  }).catch(function(e){
    btn.disabled=false; btn.textContent="AI 质控并保存病历";
    if(confirm("质控服务暂不可用，是否直接提交？")) document.getElementById("blForm").submit();
  });
}
</script>
</body>
</html>

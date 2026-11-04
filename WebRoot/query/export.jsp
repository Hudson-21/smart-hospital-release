<%@ page contentType="text/csv; charset=UTF-8" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.sql.*,java.util.*,com.hospital.*"%>
<jsp:useBean id="a" scope="page" class="com.hospital.Dbcoon" />
<%!
/* CSV 安全单元格：双引号包裹 + 内部引号翻倍 + 公式注入防护 */
String csvCell(String v){
    if(v == null) v = "";
    v = v.replace("\r", " ").replace("\n", " ");
    if(v.length() > 0){
        char c0 = v.charAt(0);
        if(c0 == '=' || c0 == '+' || c0 == '-' || c0 == '@'){
            v = "'" + v;      // 前置单引号，Excel 不再把它当公式执行
        }
    }
    return "\"" + v.replace("\"", "\"\"") + "\"";
}
%>
<%
/* ============================================================================
 *  数据导出（CSV，Excel 可直接打开）
 * ----------------------------------------------------------------------------
 *  用法：query/export.jsp?type=cost|bed|patient|guahao
 *  要点：
 *    1. 输出 UTF-8 BOM（\uFEFF），否则 Excel 打开中文全是乱码
 *    2. 字段统一双引号包裹、内部引号翻倍，防止逗号/换行破坏列结构
 *    3. 以 = + - @ 开头的单元格前置单引号，防 CSV 注入（Excel 公式执行）
 *  权限：位于 /query/ 目录，AuthFilter 已限定仅管理员可访问。
 * ========================================================================== */
String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){
    response.setStatus(403);
    out.print("未登录");
    return;
}

String type = request.getParameter("type");
if(type == null) type = "cost";

String sql, fileName, header;
if("bed".equals(type)){
    sql = "SELECT number,kebie,cost,state,name FROM bed ORDER BY number";
    fileName = "病床信息";
    header   = "病床号,所属科室,床位费,状态,在床病人";
} else if("patient".equals(type)){
    sql = "SELECT number,kebie,name,sex,age,bingzheng,doctor,ruyuan,chuyuan FROM patient ORDER BY id";
    fileName = "病人档案";
    header   = "病历号,科室,姓名,性别,年龄,病症,主治医生,入院日期,出院日期";
} else if("guahao".equals(type)){
    sql = "SELECT number,name,kebie,doctor,riqi,state,phone,beizhu FROM guahao ORDER BY id DESC";
    fileName = "挂号记录";
    header   = "挂号单号,姓名,科室,医生,就诊日期,状态,联系电话,备注";
} else {
    type = "cost";
    sql = "SELECT number,kebie,name,xiangmu,danjia,shuliang,jine,riqi,state FROM cost ORDER BY id DESC";
    fileName = "费用清单";
    header   = "病历号,科室,姓名,收费项目,单价,数量,金额,日期,状态";
}

// 下载文件名（中文需 URL 编码，否则部分浏览器保存后是乱码）
// 注意只在这里拼一次 .csv，filename 与 filename* 都复用同一个编码串
String fn  = fileName + ".csv";
String enc = java.net.URLEncoder.encode(fn, "UTF-8").replace("+", "%20");
response.setHeader("Content-Disposition",
    "attachment; filename=\"" + enc + "\"; filename*=UTF-8''" + enc);
response.setHeader("Cache-Control", "no-cache");

java.util.List<String[]> rows = new ArrayList<String[]>();
try{
    ResultSet rs = a.executeQuery(sql);
    while(rs != null && rs.next()){
        ResultSetMetaData md = rs.getMetaData();
        int n = md.getColumnCount();
        String[] line = new String[n];
        for(int i = 0; i < n; i++){
            String v = rs.getString(i + 1);
            line[i] = (v == null) ? "" : v;
        }
        rows.add(line);
    }
    a.close();
}catch(Exception ex){
    com.hospital.Audit.log(loginname, "数据导出失败", type + "：" + ex.getMessage());
}
com.hospital.Audit.log(loginname, "数据导出", fileName + " 共 " + rows.size() + " 行");

// ---- 拼整个 CSV（BOM 必须在最开头）----
StringBuilder csv = new StringBuilder();
csv.append('\uFEFF');
csv.append(header).append("\r\n");
for(String[] r : rows){
    for(int i = 0; i < r.length; i++){
        if(i > 0) csv.append(',');
        csv.append(csvCell(r[i]));
    }
    csv.append("\r\n");
}
// ⚠ 必须先清空 buffer 再输出：
//   JSP 里脚本块结束标记之间的换行属于「模板文本」，会被原样写进响应体。
//   本页上方有 page 指令、useBean、声明块，一共会产生若干换行；
//   如果不清掉，BOM(\uFEFF) 前面就会多出几个换行 ——
//   而 Excel / WPS 只读文件最前面几个字节来判断编码，看不到 BOM 就按本地 GBK 解析，
//   结果就是导出文件"中文全乱码"。此处 clear() 保证 BOM 真正位于文件第 1 个字节。
out.clear();
out.print(csv.toString());
%>

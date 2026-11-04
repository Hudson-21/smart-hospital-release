<%@ page contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.io.*,java.net.*,java.util.*,java.util.regex.*,java.sql.*,com.hospital.*" %>
<%!
/*
 * ============================================================================
 *  全院统一 AI 网关（ai/llm.jsp）
 * ============================================================================
 *  供三个智能化场景调用的后端入口（同步 JSON 响应，非流式）：
 *    task=bingli_draft   医生端：根据病情简述生成病历草稿（SOAP 结构）
 *    task=bingli_qc      医生端：提交前病历质控（本地规则 + LLM 增强）
 *    task=bingli_explain 患者端：病历通俗解读（大白话）
 *    task=stats_query    管理员端：自然语言 -> 查询意图 -> 模板 SQL -> 统计数据
 *
 *  设计原则：
 *    1. LLM 只负责"生成草稿 / 解读 / 选模板参数"，绝不直接执行 LLM 生成的 SQL
 *    2. 无 API Key 或调用失败时，自动降级为本地规则（模拟模式），保证演示不中断
 *    3. 每次调用写入 ai_chat 表做审计留痕（role 记录任务类型）
 *    4. 配置与 ai/api.jsp 保持一致（同一平台同一模型）
 * ============================================================================
 */
// ===== 配置外置：密钥从 /WEB-INF/llm.properties 读取，不再硬编码进源码 =====
String API_URL = "https://api.siliconflow.cn/v1/chat/completions";
String API_KEY = "";   // 由 jspInit() 从配置文件载入（空则走模拟模式）
String MODEL   = "Qwen/Qwen2.5-7B-Instruct";
public void jspInit(){
  java.util.Properties p = new java.util.Properties();
  try{
    java.io.InputStream in = getServletConfig().getServletContext().getResourceAsStream("/WEB-INF/llm.properties");
    if(in!=null){
      p.load(new java.io.InputStreamReader(in, "UTF-8"));
      in.close();
      API_URL = p.getProperty("apiUrl", API_URL);
      API_KEY = p.getProperty("apiKey", "");
      MODEL   = p.getProperty("model", MODEL);
    }
  }catch(Exception ignore){}
}

// ============================ 通用工具 ============================

String escape(String s){
    if(s==null) return "";
    return s.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","");
}
String unescape(String s){
    if(s==null) return "";
    return s.replace("\\n","\n").replace("\\r","\r").replace("\\\"","\"").replace("\\\\","\\");
}
String toJson(String s){
    if(s==null) return "\"\"";
    StringBuilder b=new StringBuilder("\"");
    for(int i=0;i<s.length();i++){
        char c=s.charAt(i);
        switch(c){
            case '"': b.append("\\\""); break;
            case '\\': b.append("\\\\"); break;
            case '\n': b.append("\\n"); break;
            case '\r': b.append("\\r"); break;
            case '\t': b.append("\\t"); break;
            default:
                if(c < 0x20){ b.append(String.format("\\u%04x",(int)c)); }
                else{ b.append(c); }
        }
    }
    b.append("\"");
    return b.toString();
}
// 从一段文本中提取第一个完整的 JSON 对象（容错处理 ```json 包裹与前后杂文字）
String extractJsonObj(String s){
    if(s==null) return null;
    String t = s.trim();
    if(t.startsWith("```")){
        int a = t.indexOf('{');
        int b = t.lastIndexOf('}');
        if(a>=0 && b>a) return t.substring(a,b+1);
        return null;
    }
    int a = t.indexOf('{');
    if(a<0) return null;
    int depth=0; boolean inStr=false, esc=false;
    for(int i=a;i<t.length();i++){
        char c=t.charAt(i);
        if(esc){ esc=false; continue; }
        if(c=='\\' && inStr){ esc=true; continue; }
        if(c=='"'){ inStr=!inStr; continue; }
        if(inStr) continue;
        if(c=='{') depth++;
        else if(c=='}'){ depth--; if(depth==0) return t.substring(a,i+1); }
    }
    return null;
}
// 从 JSON 字符串里取字符串字段值（简单解析，够用且无依赖）
String jsonField(String json, String key){
    if(json==null) return null;
    int ki = json.indexOf("\""+key+"\"");
    if(ki<0) return null;
    int colon = json.indexOf(":", ki+key.length()+2);
    if(colon<0) return null;
    int st = colon+1;
    while(st<json.length() && (json.charAt(st)==' '||json.charAt(st)=='\t')) st++;
    if(st>=json.length() || json.charAt(st)!='"') return null;
    st++;
    StringBuilder b=new StringBuilder();
    for(int i=st;i<json.length();i++){
        char c=json.charAt(i);
        if(c=='\\' && i+1<json.length()){
            char n=json.charAt(i+1);
            if(n=='n') b.append('\n'); else if(n=='r') b.append('\r');
            else if(n=='t') b.append('\t'); else if(n=='"') b.append('"');
            else if(n=='\\') b.append('\\');
            else b.append(n);
            i++; continue;
        }
        if(c=='"') break;
        b.append(c);
    }
    return b.toString();
}
// 从 JSON 字符串里取整数字段值
int jsonIntField(String json, String key, int def){
    if(json==null) return def;
    try{
        String v = jsonField(json,key);
        if(v==null){
            // 数字型字段（无引号）
            int ki = json.indexOf("\""+key+"\"");
            if(ki<0) return def;
            int colon = json.indexOf(":",ki+key.length()+2);
            if(colon<0) return def;
            String rest = json.substring(colon+1).trim();
            StringBuilder b=new StringBuilder();
            for(int i=0;i<rest.length() && Character.isDigit(rest.charAt(i));i++) b.append(rest.charAt(i));
            if(b.length()==0) return def;
            return Integer.parseInt(b.toString());
        }
        return Integer.parseInt(v.trim());
    }catch(Exception ex){ return def; }
}

// 同步调用 LLM（非流式）。成功返回文本，失败/无Key 返回 null
String callLlm(String sysPrompt, String userPrompt){
    if(API_KEY==null || API_KEY.trim().isEmpty()) return null;
    HttpURLConnection conn = null;
    try{
        String body = "{\"model\":\""+MODEL+"\",\"temperature\":0.3,\"messages\":["
            + "{\"role\":\"system\",\"content\":\""+escape(sysPrompt)+"\"},"
            + "{\"role\":\"user\",\"content\":\""+escape(userPrompt)+"\"}]}";
        URL url = new URL(API_URL);
        conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(60000);
        conn.setRequestProperty("Content-Type","application/json; charset=UTF-8");
        conn.setRequestProperty("Authorization","Bearer "+API_KEY);
        OutputStream os = conn.getOutputStream();
        os.write(body.getBytes("UTF-8"));
        os.flush(); os.close();
        int code = conn.getResponseCode();
        if(code!=200){ conn.disconnect(); return null; }
        BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream(),"UTF-8"));
        StringBuilder all=new StringBuilder(); String line;
        while((line=br.readLine())!=null) all.append(line);
        br.close(); conn.disconnect();
        // 解析 choices[0].message.content：定位 "message" 后的 "content"
        String resp = all.toString();
        int mi = resp.indexOf("\"message\"");
        int ci = resp.indexOf("\"content\"", mi>=0?mi:0);
        if(ci<0) return null;
        int colon = resp.indexOf(":",ci+9);
        if(colon<0) return null;
        int st=colon+1;
        while(st<resp.length() && (resp.charAt(st)==' '||resp.charAt(st)=='\t')) st++;
        if(st>=resp.length()||resp.charAt(st)!='"') return null;
        st++;
        StringBuilder b=new StringBuilder();
        for(int i=st;i<resp.length();i++){
            char c=resp.charAt(i);
            if(c=='\\' && i+1<resp.length()){
                char n=resp.charAt(i+1);
                if(n=='n') b.append('\n'); else if(n=='r') b.append('\r');
                else if(n=='t') b.append('\t'); else if(n=='"') b.append('"');
                else if(n=='\\') b.append('\\');
                else if(n=='u' && i+5<resp.length()){
                    try{ b.append((char)Integer.parseInt(resp.substring(i+2,i+6),16)); i+=4; }
                    catch(Exception ex){ b.append(n); }
                } else b.append(n);
                i++; continue;
            }
            if(c=='"') break;
            b.append(c);
        }
        return b.toString();
    }catch(Exception ex){
        if(conn!=null) try{conn.disconnect();}catch(Exception e2){}
        return null;
    }
}

String escapeSql(String s){
    if(s==null) return "";
    return s.replace("\\","\\\\").replace("'","''").replace(";","").replace("--","");
}

// 审计落库（复用 ai_chat 表，role 记录任务类型），失败不影响业务
void saveAudit(String who, String role, String content){
    if(who==null||who.isEmpty()||content==null||content.isEmpty()) return;
    try{
        com.hospital.Dbcoon db = new com.hospital.Dbcoon();
        if(content.length()>500) content = content.substring(0,500);
        db.executeUpdate("INSERT INTO ai_chat(loginname,role,content) VALUES(?,?,?)",
                who, role, content);
        db.close();
    }catch(Exception ex){}
}

// ============================ 任务一：病历草稿 ============================

// 模拟模式：按关键词模板生成草稿（无 Key / LLM 失败时兜底）
String mockDraft(String patient, String kebie, String desc){
    String d = desc==null?"":desc.trim();
    String zd;
    if(d.matches(".*(发热|发烧|咳嗽|咽|感冒|流涕|鼻塞|嗓子).*")) zd="急性上呼吸道感染";
    else if(d.matches(".*(腹痛|腹泻|恶心|呕吐|胃|拉肚).*")) zd="急性胃肠炎";
    else if(d.matches(".*(头痛|头晕|眩晕).*")) zd="偏头痛（待排）";
    else if(d.matches(".*(腰|腿|关节|扭|摔|崴|外伤|肿痛).*")) zd="软组织挫伤";
    else if(d.matches(".*(皮疹|痒|过敏|红疹).*")) zd="过敏性皮炎";
    else if(d.matches(".*(尿频|尿急|尿痛).*")) zd="尿路感染";
    else zd="初诊待查";
    StringBuilder c=new StringBuilder();
    c.append("主诉：").append(d.isEmpty()?"不适待述":d).append("。\n");
    c.append("现病史：患者").append(patient==null||patient.isEmpty()?"":patient)
     .append("自述").append(d.isEmpty()?"身体不适":d).append("，起病以来精神可，饮食睡眠尚可，二便正常，体重无明显变化。\n");
    c.append("既往史：既往体健，否认药物食物过敏史。\n");
    c.append("体格检查：神志清楚，查体合作，生命体征平稳。\n");
    c.append("处理意见：1.完善相关检查以明确诊断；2.予以对症支持治疗；3.注意休息、清淡饮食，不适随诊。");
    return "{\"zhenduan\":"+toJson(zd)+",\"content\":"+toJson(c.toString())+"}";
}

// 病历草稿：优先 LLM，失败走模拟
String taskDraft(String patient, String kebie, String desc){
    String sys = "你是门诊病历书写助手。根据医生提供的病情简述生成规范的门诊病历草稿。\n" +
        "要求：\n" +
        "1. 严格只输出 JSON，不要输出任何其他文字，格式：{\"zhenduan\":\"初步诊断\",\"content\":\"病历正文\"}\n" +
        "2. zhenduan：最可能的一个初步诊断，不超过20字；\n" +
        "3. content 按以下结构书写（用换行分隔）：\n" +
        "   主诉：主要症状+持续时间\n" +
        "   现病史：起病情况、症状特点、伴随症状、一般情况\n" +
        "   既往史：常规问诊描述（含过敏史）\n" +
        "   体格检查：常规查体描述\n" +
        "   处理意见：1.xxx 2.xxx 3.xxx（编号列出）\n" +
        "4. 语言符合中文病历书写规范，简洁专业；\n" +
        "5. 信息不足处用合理的一般性描述，禁止编造具体检查数值。";
    String user = "患者："+(patient==null?"":patient)+"（"+(kebie==null?"":kebie)+"科）。病情简述："+(desc==null?"":desc);
    String llm = callLlm(sys, user);
    if(llm!=null){
        String obj = extractJsonObj(llm);
        if(obj!=null){
            String zd = jsonField(obj,"zhenduan");
            String ct = jsonField(obj,"content");
            if(zd!=null && !zd.trim().isEmpty() && ct!=null && !ct.trim().isEmpty()){
                return "{\"zhenduan\":"+toJson(zd.trim())+",\"content\":"+toJson(ct.trim())+",\"mode\":\"llm\"}";
            }
        }
    }
    String mock = mockDraft(patient, kebie, desc);
    return mock.substring(0, mock.length()-1) + ",\"mode\":\"mock\"}";
}

// ============================ 任务二：病历质控 ============================

// 本地规则质控（不依赖 LLM，稳定可靠）
java.util.List<String> localQc(String zhenduan, String content){
    java.util.List<String> ws = new java.util.ArrayList<String>();
    String zd = zhenduan==null?"":zhenduan.trim();
    String ct = content==null?"":content.trim();
    if(zd.isEmpty()) ws.add("诊断结果不能为空");
    if(ct.isEmpty()) ws.add("病历内容不能为空");
    if(!zd.isEmpty() && ct.length()<15) ws.add("病历内容过于简短，建议补充现病史与处理意见");
    if(!ct.isEmpty() && !ct.contains("主诉")) ws.add("病历未按规范结构书写（建议包含：主诉/现病史/处理意见）");
    if(!ct.isEmpty() && !ct.matches("(?s).*\\d+\\s*(天|日|周|月|年|小时).*"))
        ws.add("主诉建议写明症状持续时间（如\"咳嗽3天\"）");
    if(!ct.isEmpty() && !ct.contains("过敏")) ws.add("未记录过敏史：如无过敏请写\"否认药物食物过敏史\"");
    // 诊断与内容关联性抽查（常见演示诊断）
    if(!zd.isEmpty() && !ct.isEmpty()){
        if((zd.contains("上呼吸道感染")||zd.contains("感冒")) &&
           !ct.matches("(?s).*(咳嗽|咽|鼻|流涕|发热|发烧).*"))
            ws.add("诊断为上呼吸道感染，但病历内容未见咳嗽/咽痛/发热等相关描述，请核对");
        if(zd.contains("肺炎") && !ct.matches("(?s).*(咳嗽|发热|发烧|肺|胸片|影像).*"))
            ws.add("诊断为肺炎，但病历内容未见咳嗽/发热/影像学描述，请核对");
        if((zd.contains("胃肠炎")||zd.contains("胃炎")) && !ct.matches("(?s).*(腹泻|腹痛|呕吐|恶心|大便).*"))
            ws.add("诊断为胃肠炎，但病历内容未见腹泻/腹痛/呕吐等相关描述，请核对");
        if(zd.contains("骨折") && !ct.matches("(?s).*(外伤|摔|扭|肿|痛|拍片|X线|影像).*"))
            ws.add("诊断为骨折，但病历内容未见外伤史或影像学描述，请核对");
    }
    return ws;
}

// 质控：本地规则为主，有 Key 时叠加 LLM 逻辑一致性检查
String taskQc(String patient, String zhenduan, String content){
    java.util.List<String> ws = localQc(zhenduan, content);
    String llmWarn = null;
    if(API_KEY!=null && !API_KEY.trim().isEmpty()){
        String sys = "你是病历质控助手。检查这份病历的诊断与内容是否一致、有无明显医学常识错误、有无重要遗漏。\n" +
            "只输出 JSON：{\"warnings\":[\"问题1\",\"问题2\"]}；若无问题输出 {\"warnings\":[]}。不要输出其他文字。警告最多3条，每条不超过40字。";
        String user = "患者："+(patient==null?"":patient)+"\n诊断："+(zhenduan==null?"":zhenduan)
            +"\n病历内容："+(content==null?"":content);
        String llm = callLlm(sys,user);
        if(llm!=null){
            String obj = extractJsonObj(llm);
            if(obj!=null){
                // 提取 warnings 数组中的字符串
                Pattern p = Pattern.compile("\"warnings\"\\s*:\\s*\\[(.*?)\\]", Pattern.DOTALL);
                Matcher m = p.matcher(obj);
                if(m.find()){
                    Pattern sp = Pattern.compile("\"((?:[^\"\\\\]|\\\\.)*)\"");
                    Matcher sm = sp.matcher(m.group(1));
                    int added=0;
                    while(sm.find() && added<3){
                        String w = unescape(sm.group(1)).trim();
                        if(!w.isEmpty()){ ws.add(w); added++; }
                    }
                }
            }
        }
    }
    StringBuilder sb=new StringBuilder("{\"pass\":").append(ws.isEmpty()).append(",\"warnings\":[");
    for(int i=0;i<ws.size();i++){ if(i>0) sb.append(","); sb.append(toJson(ws.get(i))); }
    sb.append("]}");
    return sb.toString();
}

// ============================ 任务三：病历通俗解读 ============================

// 模拟模式：常见诊断的通俗解释模板
String mockExplain(String zhenduan, String content){
    String zd = zhenduan==null?"":zhenduan;
    String what;
    if(zd.contains("上呼吸道感染")||zd.contains("感冒")) what="就是俗话说的\"感冒\"，病毒引起了鼻子、嗓子这些上呼吸道的发炎，是最常见的病之一，一般一周左右自愈。";
    else if(zd.contains("肺炎")||zd.contains("支气管")) what="肺或气管有了感染发炎，多数是细菌或病毒引起的，需要按疗程治疗，多数患者可以完全康复。";
    else if(zd.contains("胃肠炎")||zd.contains("胃炎")) what="肠胃\"感冒\"了——胃和肠子发炎，常因为吃坏东西、受凉或病毒引起，表现为拉肚子、肚子疼、恶心。";
    else if(zd.contains("骨折")) what="骨头断了或者裂了，需要固定让它慢慢长好，具体方案听骨科医生的。";
    else if(zd.contains("过敏")) what="身体对某些东西（食物、药物、花粉等）反应过度了，表现在皮肤上就是疹子和痒。";
    else if(zd.contains("尿路")||zd.contains("尿频")) what="尿道或膀胱的细菌感染，就像下水道发炎，多喝水、按时吃药一般很快就好。";
    else if(zd.contains("高血压")) what="血管里的压力长期偏高，像水管压力太大，需要长期管理，防止伤到心、脑、肾。";
    else what="您的诊断是【"+(zd.isEmpty()?"待查":zd)+"】。通俗地说，这是该科室的一种常见情况，具体性质请以主治医生当面解释为准。";
    String treat;
    String ct = content==null?"":content;
    int idx = ct.indexOf("处理意见");
    if(idx>=0) treat="医生的处理："+ct.substring(idx).trim();
    else if(!ct.isEmpty()) treat="医生已经给出处理意见并写进病历，请按医嘱执行；如对用药有疑问，取药时问清楚药师。";
    else treat="病历中暂无处理记录，请咨询您的主治医生。";
    return "{\"what\":"+toJson(what)
        + ",\"treat\":"+toJson(treat)
        + ",\"care\":"+toJson("1.按医嘱按时用药，不要自行加量减量；\n2.注意休息，饮食清淡，多喝温水；\n3.保持心情放松，避免劳累和熬夜。")
        + ",\"warning\":"+toJson("出现以下情况请立即复诊或去急诊：症状明显加重、持续高热不退、呼吸困难、剧烈疼痛不能缓解。")
        + "}";
}

// 通俗解读：优先 LLM，失败走模拟
String taskExplain(String patient, String kebie, String doctor, String zhenduan, String content, String riqi){
    String sys = "你是面向患者的病历解读助手，任务是把医生写的病历\"翻译\"成初中文化程度患者能听懂的大白话。\n" +
        "要求：\n" +
        "1. 严格只输出 JSON：{\"what\":\"这是什么病\",\"treat\":\"医生做了什么处理\",\"care\":\"回家注意什么\",\"warning\":\"什么情况要立即复诊\"}\n" +
        "2. what：2-3句话通俗解释这个诊断是什么；\n" +
        "3. treat：解释医生的处理措施在做什么；\n" +
        "4. care：3-4条日常注意事项，用\\n分隔；\n" +
        "5. warning：2-3个需要立即复诊的危险信号，用\\n分隔；\n" +
        "6. 语气亲切易懂，专业术语必须用括号解释；\n" +
        "7. 禁止给出新的诊断、禁止修改医嘱、禁止推荐具体药物剂量。";
    String user = "患者："+(patient==null?"":patient)+"；科室："+(kebie==null?"":kebie)
        +"；主治医生："+(doctor==null?"":doctor)+"；日期："+(riqi==null?"":riqi)
        +"\n诊断："+(zhenduan==null?"":zhenduan)
        +"\n病历原文："+(content==null?"":content);
    String llm = callLlm(sys,user);
    if(llm!=null){
        String obj = extractJsonObj(llm);
        if(obj!=null){
            String w=jsonField(obj,"what"), t=jsonField(obj,"treat"), c=jsonField(obj,"care"), g=jsonField(obj,"warning");
            if(w!=null && !w.trim().isEmpty()){
                return "{\"what\":"+toJson(w.trim())
                    + ",\"treat\":"+toJson(t==null?"请以医嘱为准":t.trim())
                    + ",\"care\":"+toJson(c==null?"按医嘱执行":c.trim())
                    + ",\"warning\":"+toJson(g==null?"症状加重请及时复诊":g.trim())+"}";
            }
        }
    }
    return mockExplain(zhenduan, content);
}

// ============================ 任务四：自然语言统计查询 ============================

// 规则解析统计意图（无 Key / LLM 失败兜底）：{metric, dim, days}
String[] ruleIntent(String q){
    if(q==null) q="";
    String metric="guahao", dim="keshi"; int days=0;
    if(q.matches(".*(费用|收费|金额|消费|花了|多少钱).*")){ metric="fee"; dim="xiangmu"; }
    else if(q.matches(".*(病人|患者|在院|在册).*")){ metric="patient"; dim="keshi"; }
    if(metric.equals("guahao")){
        if(q.matches(".*(医生|大夫|哪位|哪个医生|谁).*")) dim="doctor";
        else if(q.matches(".*(每天|趋势|按天|日期|走势|变化|每天分布).*")) dim="day";
        else dim="keshi";
    }
    if(q.matches(".*(7天|七天|一周|最近一周|近7|7日).*")) days=7;
    else if(q.matches(".*(30天|三十天|一个月|近30|30日).*")) days=30;
    else if(q.matches(".*(90天|九十天|三个月|近90|90日).*")) days=90;
    else if(q.matches(".*(今年|全部|所有|历史|累计|总).*")) days=0;
    return new String[]{metric,dim,String.valueOf(days)};
}

// 按模板拼 SQL（metric/dim/days 已过白名单校验；LLM 永远不生成 SQL，只选模板参数）
String buildStatsSql(String metric, String dim, int days){
    boolean filter = days>0;
    String dateCond = filter ? " WHERE riqi >= DATE_FORMAT(DATE_SUB(CURDATE(), INTERVAL "+days+" DAY),'%Y-%m-%d')" : "";
    if("fee".equals(metric)){
        return "SELECT xiangmu AS nm, SUM(jine+0) AS v FROM cost GROUP BY xiangmu ORDER BY v DESC";
    }
    if("patient".equals(metric)){
        return "SELECT kebie AS nm, COUNT(*) AS v FROM patient GROUP BY kebie ORDER BY v DESC";
    }
    // guahao
    if("doctor".equals(dim)){
        return "SELECT doctor AS nm, COUNT(*) AS v FROM guahao"+dateCond+" GROUP BY doctor ORDER BY v DESC";
    }
    if("day".equals(dim)){
        return "SELECT riqi AS nm, COUNT(*) AS v FROM guahao"+dateCond+" GROUP BY riqi ORDER BY nm";
    }
    return "SELECT kebie AS nm, COUNT(*) AS v FROM guahao"+dateCond+" GROUP BY kebie ORDER BY v DESC";
}

// 执行统计查询，返回 {title, metric, dim, days, note, rows:[{name,value}], conclusion} 的 JSON
String taskStats(String who, String q){
    String metric="guahao", dim="keshi"; int days=0;
    boolean llmParsed = false;
    // 1) 意图解析：LLM 优先，失败走规则
    if(API_KEY!=null && !API_KEY.trim().isEmpty()){
        String sys = "你是医院管理系统的统计查询解析器。把管理员的自然语言问题转换为JSON查询意图。\n" +
            "可选值：\n" +
            "metric: \"guahao\"(挂号量) | \"fee\"(收费金额) | \"patient\"(在册病人)\n" +
            "dim: \"keshi\"(按科室) | \"doctor\"(按医生) | \"day\"(按日期) | \"xiangmu\"(按收费项目)\n" +
            "days: 0(全部) | 7 | 30 | 90 (统计最近N天)\n" +
            "规则：问费用时dim用\"xiangmu\"；问挂号时提到医生按医生、提到趋势/每天按日期、默认按科室；提到一周/7天days=7、一个月/30天days=30、全部/历史days=0。\n" +
            "只输出JSON，格式：{\"metric\":\"...\",\"dim\":\"...\",\"days\":7}";
        String llm = callLlm(sys, q==null?"挂号统计":q);
        if(llm!=null){
            String obj = extractJsonObj(llm);
            if(obj!=null){
                String m=jsonField(obj,"metric"), d=jsonField(obj,"dim");
                int dy=jsonIntField(obj,"days",-1);
                if(m!=null && (m.equals("guahao")||m.equals("fee")||m.equals("patient"))) metric=m;
                if(d!=null && (d.equals("keshi")||d.equals("doctor")||d.equals("day")||d.equals("xiangmu"))) dim=d;
                if(dy==0||dy==7||dy==30||dy==90) days=dy;
                llmParsed = true;
            }
        }
    }
    if(!llmParsed){
        String[] ri = ruleIntent(q);
        metric=ri[0]; dim=ri[1]; days=Integer.parseInt(ri[2]);
    }
    // 2) 白名单最终校验（防 LLM 幻觉值）
    if(!metric.equals("guahao")&&!metric.equals("fee")&&!metric.equals("patient")) metric="guahao";
    if(!dim.equals("keshi")&&!dim.equals("doctor")&&!dim.equals("day")&&!dim.equals("xiangmu")) dim="keshi";
    if(days!=0&&days!=7&&days!=30&&days!=90) days=0;
    if("fee".equals(metric)) dim="xiangmu";
    if("patient".equals(metric)) dim="keshi";

    // 3) 执行模板 SQL（0 行时自动去掉时间条件重查）
    String note = "";
    java.util.List<String> names = new java.util.ArrayList<String>();
    java.util.List<Double> values = new java.util.ArrayList<Double>();
    String sql = buildStatsSql(metric, dim, days);
    try{
        com.hospital.Dbcoon db = new com.hospital.Dbcoon();
        ResultSet rs = db.executeQuery(sql);
        while(rs!=null && rs.next()){
            names.add(rs.getString("nm")==null?"未知":rs.getString("nm"));
            values.add(rs.getDouble("v"));
        }
        if(names.isEmpty() && days>0){
            sql = buildStatsSql(metric, dim, 0);
            ResultSet rs2 = db.executeQuery(sql);
            while(rs2!=null && rs2.next()){
                names.add(rs2.getString("nm")==null?"未知":rs2.getString("nm"));
                values.add(rs2.getDouble("v"));
            }
            note = "所选时间范围内无数据，已自动显示全部记录";
            days = 0;
        }
        db.close();
    }catch(Exception ex){
        return "{\"ok\":false,\"error\":\"查询失败："+toJson(ex.getMessage())+"\"}";
    }

    // 4) 标题与结论
    String mLab = "guahao".equals(metric)?"挂号量":("fee".equals(metric)?"收费金额":"在册病人");
    String dLab = "keshi".equals(dim)?"按科室":("doctor".equals(dim)?"按医生":("day".equals(dim)?"按日期":"按收费项目"));
    String tLab = days==7?"最近7天":(days==30?"最近30天":(days==90?"最近90天":"全部"));
    String title = tLab+" · "+dLab+" · "+mLab;
    String unit = "fee".equals(metric)?"元":("patient".equals(metric)?"人":"次");
    String conclusion = "查询完成，共"+names.size()+"条结果";
    if(!names.isEmpty()){
        String top = names.get(0); double tv = values.get(0);
        String tvs = (tv==Math.rint(tv))?String.valueOf((long)tv):String.format(java.util.Locale.US,"%.2f",tv);
        conclusion = "结论：最高的是【"+top+"】——"+tvs+" "+unit;
    }
    if("day".equals(dim)) conclusion = "按日期分布，共"+names.size()+"天有记录";

    StringBuilder sb=new StringBuilder();
    sb.append("{\"ok\":true,\"data\":{");
    sb.append("\"title\":").append(toJson(title));
    sb.append(",\"metric\":").append(toJson(metric));
    sb.append(",\"dim\":").append(toJson(dim));
    sb.append(",\"days\":").append(days);
    sb.append(",\"note\":").append(toJson(note));
    sb.append(",\"unit\":").append(toJson(unit));
    sb.append(",\"conclusion\":").append(toJson(conclusion));
    sb.append(",\"rows\":[");
    for(int i=0;i<names.size();i++){
        if(i>0) sb.append(",");
        double v = values.get(i);
        String vs = (v==Math.rint(v))?String.valueOf((long)v):String.format(java.util.Locale.US,"%.2f",v);
        sb.append("{\"name\":").append(toJson(names.get(i))).append(",\"value\":").append(vs).append("}");
    }
    sb.append("]}}");
    return sb.toString();
}
%>
<%
request.setCharacterEncoding("UTF-8");
response.setContentType("application/json; charset=UTF-8");
response.setHeader("Cache-Control","no-cache");

String loginname = (String)session.getAttribute("loginname");
if(loginname==null||"".equals(loginname)){
    out.print("{\"ok\":false,\"error\":\"未登录或会话已过期，请重新登录\"}");
    return;
}
String task = request.getParameter("task");

// ---------- 任务一：病历草稿（限医生） ----------
if("bingli_draft".equals(task)){
    String usertype = (String)session.getAttribute("usertype");
    if(!"医生".equals(usertype) && !"doctor".equalsIgnoreCase(usertype)){
        out.print("{\"ok\":false,\"error\":\"只有医生角色可以使用病历助手\"}");
        return;
    }
    String patient = request.getParameter("patient");
    String kebie   = request.getParameter("kebie");
    String desc    = request.getParameter("desc");
    if(desc==null || desc.trim().isEmpty()){
        out.print("{\"ok\":false,\"error\":\"请先填写病情简述（或选择病人自动带出病症）\"}");
        return;
    }
    String data = taskDraft(patient, kebie, desc.trim());
    saveAudit(loginname, "病历草稿", (patient==null?"":patient)+" | 简述："+desc.trim());
    out.print("{\"ok\":true,\"data\":"+data+"}");
    return;
}

// ---------- 任务二：病历质控（限医生） ----------
if("bingli_qc".equals(task)){
    String usertype = (String)session.getAttribute("usertype");
    if(!"医生".equals(usertype) && !"doctor".equalsIgnoreCase(usertype)){
        out.print("{\"ok\":false,\"error\":\"只有医生角色可以使用病历质控\"}");
        return;
    }
    String patient = request.getParameter("patient");
    String zhenduan= request.getParameter("zhenduan");
    String content = request.getParameter("content");
    String data = taskQc(patient, zhenduan, content);
    saveAudit(loginname, "病历质控", (patient==null?"":patient)+" | "+data);
    out.print("{\"ok\":true,\"data\":"+data+"}");
    return;
}

// ---------- 任务三：病历通俗解读（患者/医生均可，登录+审计） ----------
if("bingli_explain".equals(task)){
    String patient = request.getParameter("patient");
    String kebie   = request.getParameter("kebie");
    String doctor  = request.getParameter("doctor");
    String zhenduan= request.getParameter("zhenduan");
    String content = request.getParameter("content");
    String riqi    = request.getParameter("riqi");
    if((zhenduan==null||zhenduan.trim().isEmpty()) && (content==null||content.trim().isEmpty())){
        out.print("{\"ok\":false,\"error\":\"病历内容为空，无法解读\"}");
        return;
    }
    String data = taskExplain(patient, kebie, doctor, zhenduan, content, riqi);
    saveAudit(loginname, "病历解读", (patient==null?"":patient)+" | 诊断："+(zhenduan==null?"":zhenduan));
    out.print("{\"ok\":true,\"data\":"+data+"}");
    return;
}

// ---------- 任务四：自然语言统计查询（限管理员/医生） ----------
if("stats_query".equals(task)){
    String usertype = (String)session.getAttribute("usertype");
    if(!"管理员".equals(usertype) && !"admin".equalsIgnoreCase(usertype)
            && !"医生".equals(usertype) && !"doctor".equalsIgnoreCase(usertype)){
        out.print("{\"ok\":false,\"error\":\"统计查询仅限管理员或医生使用\"}");
        return;
    }
    String q = request.getParameter("q");
    if(q==null || q.trim().isEmpty()){
        out.print("{\"ok\":false,\"error\":\"请输入统计问题，例如：最近7天哪个医生挂号最多\"}");
        return;
    }
    String result = taskStats(loginname, q.trim());
    if(result.startsWith("{\"ok\":true")){
        saveAudit(loginname, "统计查询", q.trim());
    }
    out.print(result);
    return;
}

out.print("{\"ok\":false,\"error\":\"未知任务类型\"}");
%>

<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.io.*,java.net.*,java.util.*,java.util.regex.*" %>
<%-- HTTP 超时与降级提示（P0 修复）：
       - 区分 SocketTimeoutException / 401(密钥失效) / 403(权限) / 429(限流) / 5xx(服务异常)
       - 失败时第一条 SSE chunk 立刻告知降级原因，让用户立即看到而不是等待 streamText 流完
       - 保留 mockTriage 兜底，确保系统始终可用（答辩口径：永远不会"卡死"） --%>
<%!
/*
 * 智能导诊后端接口（服务端调用大模型，避免在前端暴露 API Key、避免跨域）
 * 采用 SSE（Server-Sent Events）流式返回，前端逐字显示回复内容。
 *
 * ========== 如何接入真实大模型（重要） ==========
 * 在 /WEB-INF/llm.properties 中配置 apiKey。本项目使用 OpenAI 兼容协议，以下平台都可直接用：
 *   1) 硅基流动  : API_URL = https://api.siliconflow.cn/v1/chat/completions
 *                 MODEL = Qwen/Qwen2.5-7B-Instruct  或  deepseek-ai/DeepSeek-V3
 *   2) DeepSeek  : API_URL = https://api.deepseek.com/v1/chat/completions , MODEL = deepseek-chat
 *   3) 腾讯混元  : API_URL = https://api.hunyuan.cloud.tencent.com/v1/chat/completions , MODEL = hunyuan-t1
 *   4) OpenAI    : API_URL = https://api.openai.com/v1/chat/completions , MODEL = gpt-3.5-turbo
 * 如果 API_KEY 留空，则自动走"关键词模拟导诊"兜底，系统照样能演示。
 */
// ===== 配置外置：从 /WEB-INF/llm.properties 读取（密钥不再硬编码进源码/仓库）=====
String API_URL = "https://api.siliconflow.cn/v1/chat/completions";
String API_KEY = "";   // 由 jspInit() 从 /WEB-INF/llm.properties 载入；留空则自动走本地模拟导诊
String MODEL   = "Qwen/Qwen2.5-7B-Instruct";

public void jspInit(){
    java.util.Properties p = new java.util.Properties();
    try{
        java.io.InputStream in = getServletConfig().getServletContext()
                .getResourceAsStream("/WEB-INF/llm.properties");
        if(in != null){
            p.load(new java.io.InputStreamReader(in, "UTF-8"));
            in.close();
            API_URL = p.getProperty("apiUrl", API_URL);
            API_KEY = p.getProperty("apiKey", "");
            MODEL   = p.getProperty("model", MODEL);
        }
    }catch(Exception ignore){}
}

// 导诊系统提示词（决定 AI 的角色与边界）
String SYSTEM_PROMPT =
    "你是某三甲医院的智能导诊助手，名叫「小医」。你可以回答患者的多种问题，包括：\n" +
    "1. 根据患者描述的症状推荐合适的就诊科室，并给出简短就医建议；\n" +
    "2. 介绍本院有哪些科室、各科室主要看什么病；\n" +
    "3. 说明挂号、预约、查报告等常见流程；\n" +
    "4. 回答问候、自我介绍、能做什么等通用问题；\n" +
    "5. 对紧急情况（如剧烈胸痛、呼吸困难、大出血、昏迷等）明确提示立即就医或拨打120。\n" +
    "回答要求：语言亲切、专业、简洁，尽量分点；不要编造具体的检查、诊断或医生排班；" +
    "始终声明：本建议仅供就诊参考，不能替代医生的诊断与治疗。";

// 科室兜底元数据（keshi 表不存在时使用），与 hospital_triage.sql 中 keshi 保持一致
static java.util.Map<String,String[]> DEPT_META = new java.util.HashMap<String,String[]>();
static {
  DEPT_META.put("内科",       new String[]{"NK","门诊楼2楼","诊治发热、咳嗽、感冒等常见内科疾病"});
  DEPT_META.put("消化内科",   new String[]{"XHN","门诊楼3楼","腹痛、腹泻、胃痛、反酸等消化系统疾病"});
  DEPT_META.put("神经内科",   new String[]{"SJ","门诊楼3楼","头痛、头晕、失眠、麻木等神经系统疾病"});
  DEPT_META.put("心血管内科", new String[]{"XXG","门诊楼4楼","心慌、胸闷、胸痛、高血压等心血管疾病"});
  DEPT_META.put("骨科",       new String[]{"GK","门诊楼5楼","骨折、扭伤、腰痛、关节痛等骨科疾病"});
  DEPT_META.put("皮肤科",     new String[]{"PF","门诊楼5楼","皮疹、过敏、瘙痒、痤疮等皮肤疾病"});
  DEPT_META.put("口腔科",     new String[]{"KQ","门诊楼6楼","牙疼、口腔溃疡、牙龈问题等口腔疾病"});
  DEPT_META.put("眼科",       new String[]{"YK","门诊楼6楼","视力下降、红眼、视物模糊等眼科疾病"});
  DEPT_META.put("耳鼻喉科",   new String[]{"EBH","门诊楼6楼","耳鸣、鼻塞、咽喉不适等耳鼻喉疾病"});
  DEPT_META.put("妇产科",     new String[]{"FCK","门诊楼7楼","孕产、产检、妇科及月经相关问题"});
  DEPT_META.put("儿科",       new String[]{"EK","门诊楼1楼","儿童、婴幼儿常见疾病诊治"});
  DEPT_META.put("急诊科",     new String[]{"JZ","急诊楼1楼","24小时接诊突发急危重症"});
  DEPT_META.put("泌尿外科",   new String[]{"MNW","门诊楼4楼","尿频尿急、结石、肾炎等泌尿疾病"});
  DEPT_META.put("肛肠外科",   new String[]{"GCH","门诊楼5楼","痔疮、便血、肛周疾病等肛肠外科"});
  DEPT_META.put("精神心理科", new String[]{"JSXL","门诊楼8楼","焦虑、抑郁、失眠等心理卫生问题"});
}

// 症状→科室规则（mockTriage 与 detectDept 共用），急诊关键词最严重，放最前
String[][] DEPT_RULES = {
  {"呼吸困难|大出血|昏迷|抽搐|严重外伤|车祸|烧伤|溺水|休克|窒息|剧烈胸痛|猝死","急诊科","病情紧急，请立即前往急诊科或拨打120急救电话！"},
  {"发热|发烧|低烧|高烧|咳嗽|感冒|咽痛|嗓子疼|嗓子痛|肺炎|流感|畏寒|鼻塞|流鼻涕|浑身没劲|乏力","内科","建议您前往内科就诊，注意休息、多饮水，必要时查血常规。"},
  {"骨折|扭伤|摔伤|腰痛|腰疼|关节痛|外伤|崴|拉伤|肌肉痛|颈椎|腰椎|脖子疼|肩膀疼|膝盖疼|腿疼|闪腰","骨科","建议您前往骨科就诊，避免患处受力，必要时拍片或CT检查。"},
  {"腹痛|腹泻|胃痛|胃疼|恶心|呕吐|消化|腹胀|反酸|嗳气|便秘|便血|肚子痛|肚子疼|肚子不舒服|肚子胀|胃不舒服|胃胀|拉肚子|反胃|烧心","消化内科","建议您前往消化内科就诊，近期清淡饮食，避免辛辣刺激。"},
  {"头痛|头疼|头晕|失眠|睡不着|偏瘫|手脚麻木|手麻|脚麻|眩晕|偏头痛|记忆力下降","神经内科","建议您前往神经内科就诊，必要时完善头颅CT或相关检查。"},
  {"皮疹|过敏|皮肤瘙痒|皮肤痒|青春痘|痤疮|长痘|红斑|荨麻疹|湿疹|脱皮|起疹子","皮肤科","建议您前往皮肤科就诊，避免抓挠和自行用药。"},
  {"牙疼|牙痛|牙齿疼|口腔溃疡|牙龈|拔牙|补牙|龋齿|智齿","口腔科","建议您前往口腔科就诊。"},
  {"眼睛|视力|红眼|视物|眼痛|眼睛疼|眼睛红|眼干|流泪|看不清|白内障|青光眼","眼科","建议您前往眼科就诊。"},
  {"耳鸣|听力|耳痛|鼻塞|咽喉|扁桃体炎|鼻窦炎|鼻炎|嗓子哑|鼻子不通","耳鼻喉科","建议您前往耳鼻喉科就诊。"},
  {"心慌|胸闷|胸痛|心悸|气喘|气短|心绞痛|高血压|低血压|心跳快|心脏疼|心脏不舒服","心血管内科","建议您前往心血管内科就诊；若出现剧烈胸痛请立即前往急诊。"},
  {"怀孕|孕|产科|产检|妇科|月经|白带|痛经|例假|大姨妈|腹痛伴阴道出血","妇产科","建议您前往妇产科就诊。"},
  {"小孩|儿童|宝宝|婴幼儿|小儿|孩子|小朋友","儿科","建议您前往儿科就诊。"},
  {"尿频|尿急|尿痛|尿血|血尿|腰痛伴发热|肾结石|肾炎|小便疼|小便不舒服","泌尿外科","建议您先挂泌尿外科，具体由分诊台进一步指引。"},
  {"痔疮|便血|肛周疼痛|肛瘘|肛裂|肛门疼","肛肠外科","建议您前往肛肠外科或普外科就诊。"},
  {"焦虑|抑郁|情绪低落|失眠严重|精神紧张|幻听|幻觉","精神心理科","建议您前往精神心理科或神经内科就诊。"}
};

// 根据用户输入识别归属科室（评分式：命中关键词多者优先；同分时以出现位置更早者优先，
// 即"主诉"优先于后置的伴随症状。急诊关键词一票决定，最优先。）
String detectDept(String text){
  if(text==null) return null;
  String t = text.trim();
  // 急诊关键词：一票决定
  for(String kw: DEPT_RULES[0][0].split("\\|")){
    if(t.contains(kw)) return "急诊科";
  }
  String best = null; int bestHits = 0; int bestPos = Integer.MAX_VALUE;
  for(int i = 1; i < DEPT_RULES.length; i++){
    String[] r = DEPT_RULES[i];
    int hits = 0, pos = Integer.MAX_VALUE;
    for(String kw: r[0].split("\\|")){
      int idx = t.indexOf(kw);
      if(idx >= 0){ hits++; if(idx < pos) pos = idx; }
    }
    if(hits == 0) continue;
    if(hits > bestHits || (hits == bestHits && pos < bestPos)){
      best = r[1]; bestHits = hits; bestPos = pos;
    }
  }
  return best;
}

// 兜底：关键词没命中时，从模型回复里找"唯一"提到的科室，用于出卡片。
// 命中多个时不猜（例如"儿科或内科"），宁可不出卡片也不误推荐。
// 科室名存在包含关系（"内科"是"消化内科"的子串），先按长名占位，避免重复计数。
String uniqueDeptInText(String text){
  if(text==null || text.trim().isEmpty()) return null;
  java.util.List<String> names = new java.util.ArrayList<String>(DEPT_META.keySet());
  java.util.Collections.sort(names, new java.util.Comparator<String>(){
    public int compare(String a, String b){ return b.length() - a.length(); }
  });
  java.util.List<int[]> spans = new java.util.ArrayList<int[]>();
  String best = null; int bestPos = Integer.MAX_VALUE; int count = 0;
  for(String name: names){
    int from = 0, idx, firstIdx = -1; boolean found = false;
    while((idx = text.indexOf(name, from)) >= 0){
      boolean overlap = false;
      for(int[] sp: spans){
        if(idx < sp[1] && idx + name.length() > sp[0]){ overlap = true; break; }
      }
      if(!overlap){
        found = true;
        if(firstIdx < 0) firstIdx = idx;
        spans.add(new int[]{idx, idx + name.length()});
      }
      from = idx + name.length();
    }
    if(found){
      count++;
      if(firstIdx < bestPos){ best = name; bestPos = firstIdx; }
    }
  }
  return count == 1 ? best : null;
}

// 简单的 SQL 注入防护（科室名来自本系统受控规则，这里再做一层转义）
String escapeSql(String s){
  if(s==null) return "";
  return s.replace("\\","\\\\").replace("'","''").replace(";","").replace("--","");
}

// 组装科室卡片 JSON：读取数据库该科室的医生与今日剩余号源；科室简介用兜底元数据（与 keshi 表一致）
String buildDeptCard(String deptName){
  String[] meta = DEPT_META.get(deptName);
  String code = meta!=null?meta[0]:"";
  String location = meta!=null?meta[1]:"";
  String intro = meta!=null?meta[2]:"";
  java.util.List<String> docs = new java.util.ArrayList<String>();
  int remain = 0;
  try {
    com.hospital.Dbcoon db = new com.hospital.Dbcoon();
    java.sql.ResultSet rs = db.executeQuery(
        "SELECT d.name AS dname, COALESCE(SUM(p.remain),0) AS rem FROM doctor d " +
        "LEFT JOIN paiban p ON p.doctor_code=d.number AND p.work_date=CURDATE() " +
        "WHERE d.kebie=? GROUP BY d.name", deptName);
    while(rs!=null && rs.next()){
      String dn = rs.getString("dname");
      if(dn!=null && !dn.isEmpty()) docs.add(dn);
      try{ remain += rs.getInt("rem"); }catch(Exception ex){}
    }
    db.close();
  } catch(Exception ex){ /* 数据库不可用时使用兜底元数据，不影响对话 */ }
  StringBuilder sb = new StringBuilder();
  sb.append("{\"type\":\"department\",\"name\":").append(toJson(deptName))
    .append(",\"code\":").append(toJson(code))
    .append(",\"location\":").append(toJson(location))
    .append(",\"intro\":").append(toJson(intro))
    .append(",\"doctors\":[");
  for(int i=0;i<docs.size();i++){ if(i>0) sb.append(","); sb.append(toJson(docs.get(i))); }
  sb.append("],\"todayRemain\":").append(remain).append("}");
  return sb.toString();
}

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
            case '\b': b.append("\\b"); break;
            case '\f': b.append("\\f"); break;
            default:
                if(c < 0x20){ b.append(String.format("\\u%04x", (int)c)); }
                else{ b.append(c); }
        }
    }
    b.append("\"");
    return b.toString();
}
String extractDelta(String json){
    // 从 OpenAI 兼容流式 JSON 中提取 delta.content
    int idx = json.indexOf("\"delta\"");
    if(idx < 0) return null;
    int contentIdx = json.indexOf("\"content\"", idx);
    if(contentIdx < 0) return null;
    int colon = json.indexOf(":", contentIdx);
    if(colon < 0) return null;
    int start = colon + 1;
    while(start < json.length() && (json.charAt(start) == ' ' || json.charAt(start) == '\t')) start++;
    char quote = json.charAt(start);
    if(quote == '"'){
        start++;
        boolean esc = false;
        int end = start;
        while(end < json.length()){
            char c = json.charAt(end);
            if(esc){ esc = false; end++; continue; }
            if(c == '\\'){ esc = true; end++; continue; }
            if(c == '"') break;
            end++;
        }
        return unescape(json.substring(start, end));
    } else if(quote == 'n' && json.startsWith("null", start)){
        return null;
    }
    return null;
}

// 关键词模拟导诊（兜底）：覆盖症状、问候、流程、科室介绍、医院信息等多类问题
String mockTriage(String text){
    if(text==null) text="";
    String t = text.trim();
    if(t.isEmpty())
        return "您好，请描述您的不适症状，例如：发热咳嗽、腹痛腹泻、骨折扭伤等，我帮您推荐就诊科室。";

    if(t.matches(".*(你好|您好|在吗|嗨|哈喽|hello|hi).*")){
        return "您好！我是智能导诊助手「小医」，可以帮您：\n" +
               "1. 根据症状推荐就诊科室\n" +
               "2. 介绍本院科室和挂号流程\n" +
               "3. 说明如何预约、查看报告等常见操作\n" +
               "4. 提醒紧急情况处理建议\n\n" +
               "请直接描述您的不适或想了解的问题。";
    }
    if(t.matches(".*(你能做什么|你会什么|你能干嘛|功能|帮助|help).*")){
        return "我可以为您提供以下帮助：\n" +
               "1. 症状分诊：告诉我哪里不舒服，我推荐合适的科室。\n" +
               "2. 科室查询：问「有什么科室」，我会列出主要科室。\n" +
               "3. 挂号指导：问「怎么挂号」，我会告诉您线上/线下挂号步骤。\n" +
               "4. 预约指导：问「怎么预约」，我会说明预约流程。\n" +
               "5. 紧急提示：剧烈胸痛、呼吸困难、大出血、昏迷等请立即前往急诊或拨打120。\n\n" +
               "请用一句话描述您的需求。";
    }
    if(t.matches(".*(有什么科室|有哪些科室|科室介绍|看什么病|哪个科室).*")){
        return "本院主要开设以下科室，您可以根据症状选择：\n" +
               "1. 内科 — 发热、咳嗽、感冒、咽痛、肺炎等\n" +
               "2. 消化内科 — 腹痛、腹泻、胃痛、恶心呕吐等\n" +
               "3. 神经内科 — 头痛、头晕、失眠、手脚麻木等\n" +
               "4. 心血管内科 — 心慌、胸闷、胸痛、心悸等\n" +
               "5. 骨科 — 骨折、扭伤、腰痛、关节痛、外伤等\n" +
               "6. 皮肤科 — 皮疹、过敏、皮肤瘙痒、痤疮等\n" +
               "7. 口腔科 — 牙疼、口腔溃疡、牙龈问题等\n" +
               "8. 眼科 — 眼睛红肿、视力下降、视物模糊等\n" +
               "9. 耳鼻喉科 — 耳鸣、耳痛、鼻塞、咽喉不适等\n" +
               "10. 妇产科 — 孕产、产检、妇科问题等\n" +
               "11. 儿科 — 儿童、婴幼儿常见疾病等\n" +
               "12. 急诊科 — 突发剧烈胸痛、呼吸困难、大出血、昏迷等紧急情况\n\n" +
               "如果不确定，可以描述症状让我帮您推荐。";
    }
    if(t.matches(".*(怎么挂号|如何挂号|挂号流程|挂号方式|现场挂号).*")){
        return "本院挂号方式如下：\n" +
               "1. 线上挂号：登录本系统后，进入「挂号预约」→「在线挂号」，选择科室和医生提交即可。\n" +
               "2. 线下挂号：携带身份证/就诊卡到门诊大厅挂号窗口办理。\n" +
               "3. 自助机挂号：门诊各楼层均设有自助挂号机，可刷身份证或就诊卡操作。\n" +
               "4. 电话挂号：可拨打医院服务热线进行预约（具体号码请查看官网或院内公告）。\n\n" +
               "建议提前预约，减少排队时间。";
    }
    if(t.matches(".*(怎么预约|如何预约|预约流程|预约挂号|在线预约).*")){
        return "在线预约挂号的操作步骤：\n" +
               "1. 使用管理员分配的账号登录本系统。\n" +
               "2. 在左侧菜单点击「挂号预约」→「我要挂号」。\n" +
               "3. 选择科室、医生和期望就诊时间，填写病情简述。\n" +
               "4. 提交后可在「我的挂号」中查看预约记录。\n" +
               "5. 就诊当天请提前15分钟到对应科室分诊台报到。\n\n" +
               "如需取消预约，请在「我的挂号」中操作。";
    }
    if(t.matches(".*(上班时间|门诊时间|几点上班|营业时间|医院地址|怎么去|联系电话).*")){
        return "本院基本信息：\n" +
               "• 门诊时间：周一至周五 08:00-12:00，14:00-17:30；周六上午 08:00-12:00。\n" +
               "• 急诊时间：全年无休，24小时开放。\n" +
               "• 地址：请填写您学校的地址或医院模拟地址。\n" +
               "• 联系电话：请填写医院模拟联系电话。\n\n" +
               "（注：以上信息为演示数据，实际部署时可在后台配置。）";
    }
    if(t.matches(".*(报告|检查结果|化验单|片子|影像|怎么查).*")){
        return "查询检查报告的常用方式：\n" +
               "1. 登录系统后，在患者端查看「我的病历」或「检查报告」模块（若已开通）。\n" +
               "2. 凭就诊卡/身份证到门诊大厅自助报告打印机打印。\n" +
               "3. 部分检验项目可到对应检验窗口领取纸质报告。\n\n" +
               "如对报告有疑问，建议携带报告到开单科室复诊。";
    }

    // 症状→科室映射（与 detectDept 共用评分逻辑，主诉优先、伴随症状只作加分）
    String hitDept = detectDept(t);
    if(hitDept != null){
        String dept = hitDept;
        if(dept.equals("急诊科")){
            return "【紧急提醒】根据您描述的情况，建议立即前往【急诊科】就诊！\n" +
                   "如情况危急，请立即拨打120急救电话，不要耽误。";
        }
        return "根据您描述的症状，建议前往【"+dept+"】就诊。\n"+adviceOf(dept)+"\n\n（温馨提示：本建议仅供就诊参考，不替代医生诊断。）";
    }

    return "抱歉，我暂时无法仅凭这句话判断您的情况。\n\n" +
           "您可以：\n" +
           "1. 更详细地描述症状，例如「头痛头晕三天，伴有恶心」；\n" +
           "2. 直接问「有什么科室」「怎么挂号」「怎么预约」；\n" +
           "3. 若出现剧烈胸痛、呼吸困难、大出血、昏迷等紧急情况，请立即前往急诊科或拨打120。\n\n" +
           "请问您哪里不舒服？";
}

// 将文本按字符/单词切分，逐个 SSE chunk 输出（用于模拟流式）
void streamText(JspWriter out, String text) throws Exception {
    if(text == null) text = "";
    StringBuilder word = new StringBuilder();
    for(int i = 0; i < text.length(); i++){
        char c = text.charAt(i);
        word.append(c);
        boolean sendNow = false;
        if(c == '\n') sendNow = true;
        else if(c <= 127 && (c == ' ' || c == ',' || c == '.' || c == '!' || c == '?' || c == '；' || c == '，' || c == '。' || c == '！' || c == '？')){
            sendNow = true;
        }
        else if(word.length() >= 2) sendNow = true;

        if(sendNow && word.length() > 0){
            sendChunk(out, word.toString());
            word.setLength(0);
            Thread.sleep(45);
        }
    }
    if(word.length() > 0){
        sendChunk(out, word.toString());
        Thread.sleep(45);
    }
}

// 发送一个 SSE chunk
void sendChunk(JspWriter out, String chunk) throws Exception {
    if(chunk == null) return;
    String json = "{\"chunk\":" + toJson(chunk) + "}";
    out.print("data: " + json + "\n\n");
    out.flush();
}

// 发送一张科室卡片（结构化数据，前端渲染为富卡片 + 去挂号按钮）
void sendCard(JspWriter out, String json) throws Exception {
    if(json == null) return;
    out.print("data: {\"card\":" + json + "}\n\n");
    out.flush();
}

// 发送结束标记
void sendDone(JspWriter out) throws Exception {
    out.print("data: {\"done\":true}\n\n");
    out.flush();
}

// 按部位兜底映射科室（结构化问诊中没有命中关键词时使用）
String fallbackPart(String part){
  if(part==null) return "内科";
  if(part.contains("头")) return "神经内科";
  if(part.contains("胸")) return "心血管内科";
  if(part.contains("腹")) return "消化内科";
  if(part.contains("四肢")||part.contains("关节")) return "骨科";
  if(part.contains("皮肤")) return "皮肤科";
  if(part.contains("五官")) return "耳鼻喉科";
  if(part.contains("全身")) return "内科";
  return "内科";
}
// 结构化问诊分诊：以「具体症状」为主，「部位」为辅，「伴随症状」仅作补充说明不参与定位，
// 避免伴随症状（如恶心）覆盖主要症状（如头痛）导致分诊错误。
String triageByQuestionnaire(String part, String syms, String dur, String acc){
  String d = null;
  if(syms!=null && !syms.trim().isEmpty()) d = detectDept(syms);
  if(d==null && part!=null && !part.trim().isEmpty()) d = detectDept(part);
  if(d==null) d = fallbackPart(part);
  return d;
}
// 取某科室对应的建议文案
String adviceOf(String dept){
  for(String[] r: DEPT_RULES){ if(dept.equals(r[1])) return r[2]; }
  return "请前往相应科室就诊。";
}
// 组装结构化问诊的文本回复
String buildStructuredReply(String part, String syms, String dur, String acc, String dept){
  StringBuilder b = new StringBuilder();
  b.append("根据您的智能问诊信息：\n");
  b.append("• 部位：").append(part==null?"未填写":part).append("\n");
  b.append("• 症状：").append((syms!=null&&!syms.isEmpty())?syms:"未填写").append("\n");
  b.append("• 持续时间：").append((dur!=null&&!dur.isEmpty())?dur:"未填写").append("\n");
  if(acc!=null && !acc.isEmpty()) b.append("• 伴随症状：").append(acc).append("\n");
  b.append("\n建议前往【").append(dept).append("】就诊。").append(adviceOf(dept))
   .append("\n\n（温馨提示：本建议仅供就诊参考，不替代医生诊断。）");
  return b.toString();
}
// 服务端对话存储（审计 / 跨设备可追溯），失败不影响对话
// Metadata describes the actual response path, never merely key presence.
void sendSource(javax.servlet.jsp.JspWriter out, String source, String model, String detail, boolean reset) throws java.io.IOException {
    out.print("data: {\"meta\":{\"source\":" + toJson(source) + ",\"model\":" + toJson(model)
        + ",\"detail\":" + toJson(detail) + ",\"reset\":" + reset + "}}\n\n");
    out.flush();
}
void saveChat(String who, String role, String content, String dept){
  if(who==null||who.isEmpty()||content==null||content.isEmpty()) return;
  try{
    com.hospital.Dbcoon db = new com.hospital.Dbcoon();
    if(content.length()>500) content = content.substring(0,500);
    db.executeUpdate("INSERT INTO ai_chat(loginname,role,content,dept) VALUES(?,?,?,?)",
            who, role, content, dept==null?"":dept);
    db.close();
  }catch(Exception ex){ /* 存储失败不影响导诊 */ }
}
%>
<%
request.setCharacterEncoding("UTF-8");
// 设置为 SSE 流式响应
response.setContentType("text/event-stream;charset=UTF-8");
response.setHeader("Cache-Control", "no-cache");
response.setHeader("Pragma", "no-cache");
response.setHeader("Connection", "keep-alive");
response.setBufferSize(0);  // 禁用缓冲，立即输出

// 当前登录用户（用于服务端对话存储）
String loginname = (String)session.getAttribute("loginname");

// 结构化问诊参数（来自前端「智能问诊」问卷）
String qPart = request.getParameter("part");
String qSyms = request.getParameter("syms");
String qDur  = request.getParameter("dur");
String qAcc  = request.getParameter("acc");
boolean useQuestionnaire = (qPart!=null && !qPart.trim().isEmpty());

String raw = request.getParameter("messages");
if (raw == null) raw = "[]";
String userText = request.getParameter("msg");
if (userText == null) userText = "";

// 解析 messages
List<String> roles = new ArrayList<String>();
List<String> contents = new ArrayList<String>();
Pattern p = Pattern.compile("\"role\"\\s*:\\s*\"(\\w+)\"\\s*,\\s*\"content\"\\s*:\\s*\"((?:[^\"\\\\]|\\\\.)*)\"");
Matcher m = p.matcher(raw);
while (m.find()) {
    roles.add(m.group(1));
    contents.add(unescape(m.group(2)));
}
if (contents.isEmpty() && !userText.isEmpty()) {
    roles.add("user");
    contents.add(userText);
}

String lastText = contents.isEmpty() ? "" : contents.get(contents.size() - 1);

// 确定推荐科室：结构化问诊优先，否则按关键词识别
String deptName = useQuestionnaire ? triageByQuestionnaire(qPart, qSyms, qDur, qAcc) : detectDept(lastText);
// 文本回复内容
String replyText = useQuestionnaire
    ? buildStructuredReply(qPart, qSyms, qDur, qAcc, deptName)
    : mockTriage(lastText);

if (API_KEY == null || API_KEY.trim().isEmpty()) {
    sendSource(out, "local", "", "未配置模型服务", false);
    // ===== 无 Key：模拟导诊兜底，按流式输出 =====
    streamText(out, replyText);
    saveChat(loginname, "user", lastText, deptName);
    saveChat(loginname, "assistant", replyText, deptName);
    if (deptName != null) sendCard(out, buildDeptCard(deptName));
    sendDone(out);
} else {
    // ===== 有 Key：调用真实大模型流式接口 =====
    try {
        StringBuilder sb = new StringBuilder();
        sb.append("{\"model\":\"").append(MODEL).append("\",\"temperature\":0.7,\"stream\":true,\"messages\":[");
        sb.append("{\"role\":\"system\",\"content\":\"").append(escape(SYSTEM_PROMPT)).append("\"}");
        for (int i = 0; i < roles.size(); i++) {
            sb.append(",{\"role\":\"").append(roles.get(i)).append("\",\"content\":\"")
              .append(escape(contents.get(i))).append("\"}");
        }
        sb.append("]}");

        URL url = new URL(API_URL);
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);
        conn.setDoInput(true);
        conn.setConnectTimeout(15000);
        conn.setReadTimeout(60000);  // 流式读取需要较长超时
        conn.setRequestProperty("Content-Type", "application/json; charset=UTF-8");
        conn.setRequestProperty("Authorization", "Bearer " + API_KEY);
        conn.setRequestProperty("Accept", "text/event-stream");
        OutputStream os = conn.getOutputStream();
        os.write(sb.toString().getBytes("UTF-8"));
        os.flush();
        os.close();

        int code = conn.getResponseCode();
        InputStream is = (code == 200) ? conn.getInputStream() : conn.getErrorStream();
        BufferedReader br = new BufferedReader(new InputStreamReader(is, "UTF-8"));

        if (code != 200) {
            // —— 收集错误体以便排查 ——
            StringBuilder err = new StringBuilder();
            String line;
            while ((line = br.readLine()) != null) err.append(line);
            br.close();
            conn.disconnect();
            // —— 按状态码分类，便于前端 / 用户立刻看到降级原因 ——
            String reason;
            if (code == 401)       reason = "AI 密钥失效或账户欠费";
            else if (code == 403)  reason = "AI 服务拒绝访问（权限/区域）";
            else if (code == 429)  reason = "AI 服务限流，请稍后再试";
            else if (code >= 500)  reason = "AI 服务异常（" + code + "）";
            else                   reason = "AI 接口返回错误码 " + code;
            // —— 第一条 SSE 立刻告知降级，不再让用户空等 ——
            sendSource(out, "local", "", reason, true);
            sendChunk(out, "【服务降级提示】" + reason + "，已自动切换为本地模拟导诊。\n\n");
            streamText(out, replyText);
            saveChat(loginname, "user", lastText, deptName);
            saveChat(loginname, "assistant", "【降级:" + code + "】" + replyText, deptName);
            if (deptName != null) sendCard(out, buildDeptCard(deptName));
            sendDone(out);
        } else {
            String line;
            StringBuilder llmReply = new StringBuilder();
            while ((line = br.readLine()) != null) {
                if (line.startsWith("data: ")) {
                    String data = line.substring(6).trim();
                    if ("[DONE]".equals(data)) {
                        break;
                    }
                    String delta = extractDelta(data);
                    if (delta != null && !delta.isEmpty()) {
                        if(llmReply.length() == 0) sendSource(out, "llm", MODEL, "", false);
                        llmReply.append(delta);
                        sendChunk(out, delta);
                    }
                }
            }
            br.close();
            conn.disconnect();
            if(llmReply.toString().trim().isEmpty()) throw new java.io.IOException("Empty model response");
            saveChat(loginname, "user", lastText, deptName);
            saveChat(loginname, "assistant", llmReply.toString(), deptName);
            // 关键词没命中时，用模型回复里唯一提到的科室兜底，保证仍有卡片和挂号按钮
            String cardDept = (deptName != null) ? deptName : uniqueDeptInText(llmReply.toString());
            if (cardDept != null) sendCard(out, buildDeptCard(cardDept));
            sendDone(out);
        }
    } catch (java.net.SocketTimeoutException ste) {
            // —— 连接/读取超时：第一条 SSE 立刻告知降级原因（不再让用户盯着空屏幕） ——
            sendSource(out, "local", "", "模型服务响应超时", true);
            sendChunk(out, "【服务降级提示】AI 接口响应超时，已自动切换为本地模拟导诊。\n\n");
            streamText(out, replyText);
            saveChat(loginname, "user", lastText, deptName);
            saveChat(loginname, "assistant", "【降级:超时】" + replyText, deptName);
            if (deptName != null) sendCard(out, buildDeptCard(deptName));
            sendDone(out);
    } catch (Exception e) {
            // —— 其它网络/解析异常：第一条 SSE 立刻告知降级原因 ——
            String msg = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
            sendSource(out, "local", "", "模型服务暂时不可用", true);
            sendChunk(out, "【服务降级提示】模型服务暂时不可用，已自动切换为本地模拟导诊。\n\n");
            streamText(out, replyText);
            saveChat(loginname, "user", lastText, deptName);
            saveChat(loginname, "assistant", "【降级:异常】" + replyText, deptName);
            if (deptName != null) sendCard(out, buildDeptCard(deptName));
            sendDone(out);
    }
}
%>

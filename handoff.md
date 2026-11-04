# 项目交接（2026-11-04）

## 目标与范围
- 已完成医院系统前端蓝白风格改版。用户已确认应用提高文字对比度的方案；已完成项目样式修改。
- 最新任务：排查智能导诊是否真实连接大模型，修复输入区焦点框与按钮重叠；已完成代码修改及验证，详见 dev-logs/2026-11-04.md。

## 进度与验证
- 前一阶段：修改 50 个 JSP，新增 6 个 CSS、2 个 JS；三角色首页使用真实数据；登录、导航、业务表格、导诊、统计页风格统一。
- 前一阶段在隔离 Tomcat 中完成 51 项页面/脚本/权限检查，以及桌面和 390px 浏览器交互验证；独立复核未发现确认的回归问题。未提交真实挂号、收费、处方或 AI 请求。
- 当前对比度预览：使用隔离副本渲染同一页面，仅在浏览器临时注入 CSS，生成 before/after 整页图及局部对比图；已视觉检查。

## 已确认内容
- 用户偏好克制医疗蓝、白色卡片、线性图标；最近要求解决灰蓝文字融入白底的问题。
- 预览使用正文 #334155、标题 #1F2937、表头/标签 #475569、说明最终采用 #5F6F85（浅灰背景上实测达到 4.5:1）、主背景 #F1F5F9，并略提高菜单字重。
- 用户已授权并完成对比度改造。6 个 CSS 更新配色/字重，50 个 JSP 仅更新 CSS 缓存版本为 20261104，未改变业务逻辑。
- 旧业务 JSP 同时存在 GBK/UTF-8，必须保留编码及原表单业务逻辑。不得把演示数字写进生产首页。

## 关键位置
- 项目 D:/hospital，无 Git 仓库。
- 样式 WebRoot/css/hospital-*.css；共享脚本 WebRoot/js/hospital-*.js；首页 WebRoot/right.jsp。
- 工作目录 C:/Users/Hudson Chen/Documents/Codex/2026-11-03/kad/work。
- 输出目录 C:/Users/Hudson Chen/Documents/Codex/2026-11-03/kad/outputs。
- outputs/hospital-ui-before.zip 是上一轮 50 个原始 JSP 备份；前端改版说明.md、hospital-ui-change-list.json 记录变更。
- 新预览：hospital-contrast-before.png、hospital-contrast-after.png、hospital-contrast-comparison.png。
- 预览脚本 work/preview_contrast.js；对比拼图 work/contrast_comparison.py。
- 隔离 Tomcat 在 work/hospital-tomcat，测试登录仅在副本；端口 18086。每次结束预览应关闭测试浏览器并停止这个测试进程，勿停止用户其他服务。

## 问题与限制
- 本轮抽查 24 处文本颜色对比度全部达到 4.5:1，最低约 4.68:1；不是全站完整无障碍认证。登录身份选择、390px 登录布局及患者首页导航检查通过。50 个 JSP 与本轮备份逐字节比对，除 CSS 版本号外一致。
- 写入类业务未做端到端测试；原统计页仍依赖 ECharts CDN。

## 本轮交付与运行状态
- 最新实际截图 outputs/hospital-contrast-applied.png。
- 改动前备份 outputs/hospital-before-contrast-20261104.zip（6 个 CSS、50 个 JSP）。
- 验证脚本 work/verify_contrast.js；实现脚本 work/apply_contrast.py 已执行，不要直接重复运行。
- 本轮使用隔离 Tomcat 的 18086 端口和临时浏览器验证，结束时关闭。

## 下一步
1. 用户按原 IDEA/Smart Tomcat 方式重新部署项目，Ctrl+F5 查看效果；导诊 CSS 最新为 v=20261104-2，其他页面仍为 v=20261104。
2. 新导诊回复下方应显示“大模型回复 · Qwen/Qwen2.5-7B-Instruct”或“本地规则回复”；旧记录没有元数据，显示来源未记录。
3. 若需要提高问诊质量，再单独评估追问策略及模型选择；当前未改模型或提示词。

## 智能导诊排查（2026-11-04）
- 硅基流动接口实测 HTTP 200，当前 Qwen/Qwen2.5-7B-Instruct 配置可产生真实流式响应。不能证明用户旧截图当时的请求来源。
- 三处修改：WebRoot/ai/ask.jsp、WebRoot/ai/api.jsp、WebRoot/css/hospital-chat.css。安全加粗渲染、实际来源元数据与历史持久化、统一输入区焦点提示和按钮间距；api.jsp 硬编码密钥默认值移除，配置文件未改。
- 隔离后端四项检查通过（真实模型、无密钥、401、空流）；浏览器 14 项检查通过，覆盖三种宽度、来源显示与持久化、HTML 安全、重复提交、中途降级替换。
- work/triage-before-fix-20261104 是修改前三文件备份；含原服务端源码，不可作为公开交付件或上传。
- work/verify_triage_backend.py、work/verify_triage_fix.js 为本次验证脚本；后端测试仅隔离副本禁止聊天写库。
- outputs/hospital-triage-fixed.png 与 hospital-triage-fixed-mobile.png 展示修改后界面，使用已验证真实模型响应重放。

- 本次验证结束：隔离浏览器与 18086 Tomcat 已停止；临时测试 JSP/配置已删除。原项目未部署到用户运行中的服务器，需重新部署后查看。

## 根路径 403 修复（2026-11-04 10:20）
- 用户重新运行后打开 `http://localhost:8080/hospital/` 出现 403「当前角色：病人」。访问日志确认 `GET /hospital/ → 403`。
- 原因：`AuthFilter` 把根路径 `/` 当作普通业务路径做 default deny，welcome-file `login.jsp` 从未生效。
- 已改 `src/com/hospital/AuthFilter.java`：根路径改为显式分流，已登录跳 `index.jsp`、未登录跳 `login.jsp`（不能放行给 login.jsp，那个页面会 invalidate 会话）。
- 已编译并同步 `WebRoot/WEB-INF/classes` 与 `out/production/hospital` 两处 class。**必须重启 Tomcat**（上下文 reloadable=false），否则仍跑旧 filter。
- 注意：Smart Tomcat 通过 `PreResources` 把 `out/production/hospital` 挂在 `/WEB-INF/classes` 之前，以后改 Java 类两处都要更新。
- 未做：带真实登录会话的端到端复测（需要重启后进行）。

## 导诊科室卡片修复（2026-11-04 10:32）
- 现象：大模型文字回复正常，但科室推荐卡片、今日号源、去挂号按钮消失。
- 原因：卡片只在 `deptName != null` 时发送，而 `deptName` 来自 `detectDept()` 关键词匹配；规则里只有书面语「腹痛」，用户说「肚子痛」命中不了。
- 已改 `WebRoot/ai/api.jsp`：补充口语同义词到 `DEPT_RULES`；新增 `uniqueDeptInText()` 用模型回复兜底（仅唯一命中才出卡片）；大模型成功分支使用 `cardDept`。
- 验证：规则与识别逻辑抽成独立类编译执行，15 项用例全通过。
- 待办：浏览器登录后实测一次「我肚子痛」，确认卡片与号源显示。JSP 改动无需重启 Tomcat。

## GitHub 仓库（2026-11-04 10:45）
- 仓库：https://github.com/Hudson-21/smart-hospital（**私有**），默认分支 main，首次提交 41571aa，远程 180 个文件。
- 已排除：`WebRoot/WEB-INF/llm.properties`（真实密钥）、`db/*.mdf|*.ldf|*.bak`、`out/`、`.idea/`、`*.class`、`.smarttomcat/`、`*.log`。
- 远程 WEB-INF 已核对：只有 `lib/`、`llm.properties.template`、`web.xml`，无密钥文件。
- 推送网络：环境默认代理 `127.0.0.1:19392` 对 github.com 是 502，直连被 reset。用本机 7890 端口可推：
  `git -c http.proxy=http://127.0.0.1:7890 -c https.proxy=http://127.0.0.1:7890 push`
- 仓库不含编译后的 class，克隆后需在 IDEA 编译；README 已补充（提交 a8c8880），含环境、建库、部署步骤与测试账号。
- 若日后改为公开：先清理 `db/hospital_init.sql` 里的测试手机号，并确认 `llm.properties` 从未外发（建议重置硅基流动密钥）。

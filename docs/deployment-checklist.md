# 接手清单：从一份源码到一笔可核对的挂号

**目标是隔离验收，不是发布操作。** 从项目根目录核对 `git status -sb`、`git log -5 --oneline`。不启动现有 Smart Tomcat、不连接本机默认 MySQL、不导入项目备份或初始化脚本的数据行。下列任一隔离条件不能满足就停止；不要临时改业务源码或借用已有账号。

## 1. 准备与隔离

在 Windows PowerShell 中准备 Git、Python 3、Node.js、已安装的 Playwright（含 Chromium 或可执行的 Edge）、JDK 8、Tomcat 9、MySQL 8 完整二进制（含 mysqld、mysql、mysqladmin）。不需要事先启动数据库或应用。

```powershell
# 示例路径，请替换为实际安装位置。不是数据库连接参数。
$env:JAVA_HOME='D:\jdk-1.8'
$env:CATALINA_HOME='D:\apache-tomcat-9.0.122'
$env:MYSQL_HOME='D:\Mysql'
$env:SMOKE_PLAYWRIGHT='C:\path\to\node_modules\playwright'  # 或使用 Node 可解析的 playwright
$env:SMOKE_BROWSER='C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'  # 或使用 Playwright 已安装的 Chromium
$env:PYTHONIOENCODING='utf-8'
python -u tools/isolated-smoke/verify.py
```

不要使用 `python -O`。每次均创建新的临时目录、回环端口、MySQL 数据目录、虚构账号和 Tomcat base。脚本只从基线 SQL 取建表语句；不执行种子、`USE hospital` 或备份。依次校验新实例的 UUID、数据目录和端口，再写入测试库。测试代理只在隔离 JVM 加载：替换 JDBC 目标与账号，校验库名和 UUID，拒绝其他出站 TCP（Windows NIO 自身的回环管道除外）。浏览器只访问该回环站点。**绝不能**把测试代理、测试凭据、临时数据目录或验证码测试用法用于生产。

## 2. 迁移门槛：先核对，再部署新代码

| 顺序 | 文件 | 执行后必须看到 |
|---|---|---|
| 1 | `db/migrations/2026-11-25-booking-shift.sql` | `guahao` 新增可空 `booking_shift`、`booking_request_id`；唯一索引覆盖 `(name,booking_request_id)`。旧记录两个值均 NULL。 |
| 2 | `db/migrations/2026-11-26-prescription-cost.sql` | `cost.rx_item_id` 可空且唯一，外键指向 `cf_item.id`；旧费用不回填、金额不变。 |
| 3 | `db/migrations/2026-11-26-visit-notes.sql` | 新挂号保存登录账号主键，新病历保存挂号主键；两个外键可空，不按姓名回填历史归属。 |

脚本在每次全新隔离库各执行一次。这不是可重复执行的升级器：遇到已有列、索引或部分迁移，不要盲目重跑或删列。迁移前后、产生新预约之前，核对全部 16 张表行数、旧挂号的状态和号源。第 1、4 项无迁移。实际库备份、恢复演练与上线均须另行授权；应用回退不等于删列，更不能丢掉已写入的关联数据。规则细节见 [挂号](booking-reliability.md) 与 [AI 边界](ai-data-boundary.md)。

## 3. 编译、编码与实际加载位置

- 完整复制受版本管理的 Web 资源（不带旧 class 和真实 `llm.properties`）；使用 JDK 8 的 `javac -encoding UTF-8` 编译 `src`，classpath 含 Tomcat 的 lib 与应用 `WEB-INF/lib`，输出到**隔离应用** `WEB-INF/classes`。不要将测试输出写回源码树。
- `WebRoot/cost/list_cost.jsp` 是 GBK，`WebRoot/patient/guahao.jsp` 是 UTF-8。编辑前核对页面声明、原文件实际字节及换行，不全站转码；复制资源逐字节校验。文件编码、JDBC 字符集、HTTP 响应字符集不是同一件事。
- 编译成功不是加载成功。改 Java、过滤器、JAR 或启动配置后，重新编译并完整重启目标 Tomcat；新 JVM 开启 JDK 8 `-verbose:class`，触发挂号。检查 `Loaded com.hospital.AppointmentBooking from ...` **与** `CLASS ORIGIN` 的路径及 WebappClassLoader；不是本次副本即停止验收。JSP 可能按容器策略重新编译，不要用浏览器刷新推断 Java 类已更新。
- 本脚本是普通 Tomcat：期望来源为本次临时目录下 `tomcat/webapps/hospital/WEB-INF/classes/`。Smart Tomcat 另有 `PreResources`，可能优先使用 `out/production/hospital`；按 README 的部署路径说明核对实际 context、IDE 输出和运行日志，不应同时猜测两份 class 哪一份生效。
- 不提供真实模型配置。即使已配置服务，导诊外发仍须服务端 `triageExternalEnabled=true` 和用户本次选择同时满足；病历解读只用本地模板。不要为验证连通性开启真实外发。

## 4. 三角色冒烟及停止条件

1. **患者**：用虚构账号从原登录页进入；旧挂号显示“时段未记录”。预约指定日期上午，提交 303 后“我的挂号”有同日、上午、待接诊；行数加一，只有对应余号减一。
2. **医生**：原登录页进入，仅对同一挂号验收。缺少 CSRF 的 POST 应为 403，数据不变。页面表单带令牌提交后仅该记录转已接诊，不能再次扣号。
   接诊后从该行进入“写病历”；无须选人。确认仅本次症状进入模板、诊断由医生填写；保存后返回对应挂号行。历史未绑定账号的就诊不可直接新建病历。
3. **管理员**：原登录页进入；GBK 收费页能显示虚构费用和中文，UTF-8 AI 历史页显示元数据说明。无需真实账单、患者档案或外部模型。
4. 请以脚本退出码 0 和本次 `result.txt` 为准；任何断言失败都不能登记为通过。输出目录由首行 `Fixture:` 指出，类加载详见同目录 `tomcat.log`。只关闭本次的进程，不按进程名批量结束；检查该 data/base 路径不再被服务使用。日志、编译物、带虚构账号的库和代理均不提交；如需归档，只归档脱敏摘要。

这是部署冒烟，不替代第 1–4 项专项回归。正式业务库、真实供应商、生产实例和 Smart Tomcat 热更新行为均未验证。

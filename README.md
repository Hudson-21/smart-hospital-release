# 智能化医院管理系统（smart-hospital）

基于 JSP + Servlet + MySQL 的医院信息管理系统，包含管理员、医生、病人三种角色的完整业务闭环，并接入大模型实现智能导诊。

## 功能概览

| 角色 | 可用功能 |
|---|---|
| 管理员 | 医生/病人档案、科室排班、挂号记录、收费、处方、药品库存、病床、统计看板、账号权限 |
| 医生 | 我的档案、我的病人、我的接诊、我的病历、开方开药、我的处方、药品库存 |
| 病人 | 我的信息、我的费用、在线挂号、我的挂号、我的病历、智能导诊 |

其他能力：

- **智能导诊**：接入硅基流动 `Qwen/Qwen2.5-7B-Instruct`，SSE 流式输出；识别症状后推送科室卡片（科室介绍、出诊医生、今日剩余号源、去挂号按钮）；未配置密钥或调用失败时自动降级为本地规则导诊，并在界面标注回复来源。
- **病历助手**：医生端生成 SOAP 病历草稿、提交前质控；患者端病历大白话解读。
- **统计问答**：管理员用自然语言查询统计口径，模型只负责选模板，不执行模型生成的 SQL。
- **安全**：全局 `AuthFilter` 做登录认证 + 角色白名单授权 + CSRF 校验；口令 PBKDF2 加盐存储。

## 技术栈

- JDK 8
- Servlet / JSP（JSP 内嵌业务逻辑，未使用 Spring 等框架）
- Tomcat 9.x
- MySQL 8.x（库名 `hospital`，字符集 **GBK**）
- 原生 HTML / CSS / JavaScript，统计页使用 ECharts（CDN）

## 目录结构

```
src/com/hospital/          Java 工具类：鉴权过滤器、CSRF、口令哈希、数据库连接
WebRoot/                   站点根目录
  ├─ ai/                   智能导诊与 AI 网关
  ├─ doctor/ patient/ ...  各角色业务页面
  ├─ css/ js/              前端样式与脚本
  └─ WEB-INF/              web.xml、JDBC 驱动、大模型配置模板
db/                        建库与初始化脚本
docs/                      架构与流程图
```

## 快速开始

### 1. 准备环境

JDK 8、Tomcat 9、MySQL 8 已安装并启动。

### 2. 初始化数据库

```bash
mysql -u root -p --default-character-set=gbk < db/hospital_init.sql
```

脚本会创建 `hospital` 库、16 张表并写入演示数据。**必须带 `--default-character-set=gbk`**：脚本是 GBK 编码的 mysqldump，用默认 utf8 客户端导入会导致中文乱码。

### 3. 修改数据库连接

编辑 `src/com/hospital/Dbcoon.java`，把连接信息改成你本机的：

```java
private static final String URL =
    "jdbc:mysql://localhost:3306/hospital?useUnicode=true&characterEncoding=gbk&serverTimezone=Asia/Shanghai&useSSL=false";
private static final String USER_NAME = "root";
private static final String PASSWORD = "你的密码";
```

不要改掉 `characterEncoding=gbk`，库和连接编码必须一致。

### 4. 配置大模型（可选）

```bash
copy WebRoot\WEB-INF\llm.properties.template WebRoot\WEB-INF\llm.properties
```

在生成的 `llm.properties` 中填入服务地址、密钥和模型名。使用 OpenAI 兼容协议的平台均可，默认示例是硅基流动：

```properties
apiUrl=https://api.siliconflow.cn/v1/chat/completions
apiKey=你的密钥
model=Qwen/Qwen2.5-7B-Instruct
```

**不配置也能运行**：导诊会自动使用本地关键词规则，回复下方标注「本地规则回复」。

`llm.properties` 含真实密钥，已被 `.gitignore` 排除，请勿提交。

### 5. 编译与运行（IDEA + Smart Tomcat）

1. IDEA 打开项目，Project SDK 选 **1.8**。
2. 执行 `Build → Build Project`，产物在 `out/production/hospital`。
3. 新建 Smart Tomcat 运行配置：
   - Tomcat：9.0.x
   - **Context path**：`/hospital`
   - **Doc base**：`WebRoot`
4. 访问 <http://localhost:8080/hospital/>。

> **必须先编译再启动。** 仓库不提交 `.class`（见下方说明），未编译就部署时 `web.xml` 里的 `AuthFilter`、`Csrf` 会加载失败，鉴权与 CSRF 防护不会生效。

### 测试账号

| 账号 | 密码 | 角色 |
|---|---|---|
| `admin` | `123456` | 管理员 |
| `doctor1` | `123456` | 医生 |
| `张医生` | `123456` | 医生 |
| `李病人` | `123456` | 病人 |
| `1` | `123456` | 病人 |

均为演示数据，正式使用请立即修改密码。

## 关于仓库不含 class

`.gitignore` 忽略了 `*.class`、`/out/`、`.idea/` 等构建与 IDE 产物，这是 Java 项目的常规做法：字节码与 JDK 版本绑定，入库会产生无法合并的二进制冲突。因此克隆后需要自己编译一次，步骤见上文第 5 步。

## 部署路径说明

Smart Tomcat 的 `context.xml` 会把 `out/production/hospital` 以 `PreResources` 方式挂到 `/WEB-INF/classes`，优先级高于 `WebRoot/WEB-INF/classes`。也就是说：

- **JSP 修改**：直接生效，刷新页面即可（Tomcat 会重新编译 JSP）。
- **Java 类修改**：需要重新 Build 并重启 Tomcat，且要确认 `out/production/hospital` 下的 class 已更新。

## 已知限制

- 统计页图表依赖 ECharts CDN，离线环境不显示。
- 数据库访问是全站共享单连接 + 类锁同步，适合课程设计规模，不适合高并发。
- 业务 JSP 同时存在 GBK 与 UTF-8 编码，编辑前先确认文件编码，避免中文乱码。
- 仓库只保留 SQL 脚本，`db/*.mdf`、`*.ldf` 是早期 SQL Server 文件，与当前 MySQL 版本无关，未纳入版本库。

## 文档与图示

- `docs/` 与根目录存放功能模块图、程序流程图、整体 ER 图。
- `dev-logs/` 按日期记录开发与修复过程。
- `handoff.md` 为项目交接说明，含当前进度、验证结果与遗留问题。

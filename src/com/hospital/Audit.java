package com.hospital;

/**
 * 轻量操作审计：写入 oplog 表（id 自增，ts 默认当前时间）。
 * 建表 SQL（已由初始化脚本执行）：
 *   CREATE TABLE IF NOT EXISTS oplog(
 *     id INT AUTO_INCREMENT PRIMARY KEY,
 *     ts DATETIME DEFAULT CURRENT_TIMESTAMP,
 *     loginname VARCHAR(50),
 *     action    VARCHAR(50),
 *     detail    VARCHAR(500)
 *   )ENGINE=InnoDB DEFAULT CHARSET=gbk;
 *
 * 记录失败不影响业务（登录页/删除页照常执行）。
 */
public class Audit {

	public static void log(String loginname, String action, String detail) {
		try {
			Dbcoon db = new Dbcoon();
			if (loginname != null && loginname.length() > 50)  loginname = loginname.substring(0, 50);
			if (action    != null && action.length()    > 50)  action    = action.substring(0, 50);
			if (detail    != null && detail.length()    > 500) detail    = detail.substring(0, 500);
			db.executeUpdate(
				"INSERT INTO oplog(loginname,action,detail) VALUES(?,?,?)",
				loginname, action, detail);
		} catch (Exception ex) {
			System.err.println("Audit.log: " + ex.getMessage());
		}
	}
}

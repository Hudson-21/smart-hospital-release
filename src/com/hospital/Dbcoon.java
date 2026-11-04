package com.hospital;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

/**
 * 数据库访问工具类（2026-09-22 安全加固版）
 *
 * 主要改动：
 * 1. 连接复用：全站共享一个静态连接，失败自动重连，彻底解决"每页开 N 个连接不关闭"的连接泄漏；
 * 2. 参数化查询：新增 executeQuery(sql, params...) / executeUpdate(sql, params...) 重载，
 *    所有带用户输入的 SQL 一律走这两个方法，杜绝 SQL 注入；
 * 3. 原有 executeQuery(String)/executeUpdate(String)/preparedstatements(String)/close() 签名保持不变，
 *    老页面无需改动即可编译运行；
 * 4. close() 保留但不再关闭连接（连接是共享的），只为兼容旧调用。
 *
 * 线程模型：所有执行方法对类锁同步，事务期间其他请求会排队等待（对课程设计规模足够）。
 */
public class Dbcoon {

	// MySQL 连接地址（数据库名 hospital，字符集 gbk 与项目一致，时区上海）
	private static final String URL =
		"jdbc:mysql://localhost:3306/hospital?useUnicode=true&characterEncoding=gbk&serverTimezone=Asia/Shanghai&useSSL=false";
	private static final String USER_NAME = "root";
	private static final String PASSWORD = "123456";

	// 全站共享的单一连接
	private static Connection con = null;

	public Dbcoon() {
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");
		} catch (ClassNotFoundException e) {
			System.err.println(e);
		}
	}

	/** 获取共享连接；失效则重建 */
	public Connection getConnection() {
		synchronized (Dbcoon.class) {
			try {
				if (con == null || con.isClosed() || !con.isValid(2)) {
					try { if (con != null) con.close(); } catch (Exception ignore) {}
					con = DriverManager.getConnection(URL, USER_NAME, PASSWORD);
				}
			} catch (SQLException e) {
				System.err.println("Dbcoon.getConnection: " + e.getMessage());
			}
			return con;
		}
	}

	/** 旧接口：整句 SQL 查询（仅供无用户输入的静态 SQL 使用） */
	public ResultSet executeQuery(String sql) {
		synchronized (Dbcoon.class) {
			try {
				Statement stmt = getConnection().createStatement(
						ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
				return stmt.executeQuery(sql);
			} catch (SQLException er) {
				System.err.println("Dbcoon.executeQuery: " + er.getMessage());
				return null;
			}
		}
	}

	/** 新接口：参数化查询。用法：executeQuery("SELECT * FROM t WHERE name LIKE ?", "%张%") */
	public ResultSet executeQuery(String sql, Object... params) {
		synchronized (Dbcoon.class) {
			try {
				PreparedStatement ps = getConnection().prepareStatement(sql,
						ResultSet.TYPE_SCROLL_SENSITIVE, ResultSet.CONCUR_READ_ONLY);
				bind(ps, params);
				return ps.executeQuery();
			} catch (SQLException er) {
				System.err.println("Dbcoon.executeQuery(PS): " + er.getMessage());
				return null;
			}
		}
	}

	/** 旧接口：整句 SQL 更新（仅供无用户输入的静态 SQL 使用） */
	public int executeUpdate(String sql) {
		synchronized (Dbcoon.class) {
			try {
				Statement stmt = getConnection().createStatement();
				try {
					return stmt.executeUpdate(sql);
				} finally {
					stmt.close();
				}
			} catch (SQLException ex) {
				System.err.println("Dbcoon.executeUpdate: " + ex.getMessage());
				return 0;
			}
		}
	}

	/** 新接口：参数化更新/删除/插入。用法：executeUpdate("DELETE FROM t WHERE id=?", 5) */
	public int executeUpdate(String sql, Object... params) {
		synchronized (Dbcoon.class) {
			try {
				PreparedStatement ps = getConnection().prepareStatement(sql);
				bind(ps, params);
				try {
					return ps.executeUpdate();
				} finally {
					ps.close();
				}
			} catch (SQLException ex) {
				System.err.println("Dbcoon.executeUpdate(PS): " + ex.getMessage());
				return 0;
			}
		}
	}

	/** 兼容旧接口：返回预编译语句（调用方负责 close） */
	public PreparedStatement preparedstatements(String sql) {
		synchronized (Dbcoon.class) {
			try {
				return getConnection().prepareStatement(sql);
			} catch (SQLException ex) {
				System.err.println("Dbcoon.preparedstatements: " + ex.getMessage());
				return null;
			}
		}
	}

	/**
	 * 兼容旧接口：连接现为全站共享，close() 不再真正关闭连接。
	 * （保留方法签名，老页面里的 db.close() 调用无需删除）
	 */
	public void close() {
		// 共享连接：不关闭。需要停机时由容器负责。
	}

	private static void bind(PreparedStatement ps, Object... params) throws SQLException {
		if (params == null) return;
		for (int i = 0; i < params.length; i++) {
			ps.setObject(i + 1, params[i]);
		}
	}
}

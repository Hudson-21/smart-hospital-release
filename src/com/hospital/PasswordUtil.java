package com.hospital;

import java.security.SecureRandom;
import java.security.spec.KeySpec;
import javax.crypto.SecretKeyFactory;
import javax.crypto.spec.PBEKeySpec;

/**
 * 口令哈希工具（PBKDF2WithHmacSHA256 + 随机盐）。
 *
 * 存储格式：pbkdf2:<迭代次数>:<盐hex>:<哈希hex>
 * 旧明文口令可通过 PasswordUtil.verify 的兜底比对继续登录（用于平滑迁移），
 * check_login 检测到明文口令登录成功后应立即回写哈希。
 */
public class PasswordUtil {

	private static final String PREFIX = "pbkdf2:";
	private static final int ITERATIONS = 120000;
	private static final int SALT_LEN = 16;   // 字节
	private static final int HASH_LEN = 32;   // 字节
	private static final SecureRandom RNG = new SecureRandom();

	/** 对明文口令生成带盐哈希 */
	public static String hash(String pwd) {
		if (pwd == null) pwd = "";
		try {
			byte[] salt = new byte[SALT_LEN];
			RNG.nextBytes(salt);
			byte[] dk = pbkdf2(pwd, salt, ITERATIONS);
			return PREFIX + ITERATIONS + ":" + hex(salt) + ":" + hex(dk);
		} catch (Exception e) {
			throw new RuntimeException("口令哈希失败", e);
		}
	}

	/**
	 * 校验口令。
	 * stored 为 pbkdf2: 格式 → 做常量时间比对；
	 * stored 为旧明文 → 明文比对（兼容迁移期），返回 true 时调用方应回写哈希。
	 */
	public static boolean verify(String pwd, String stored) {
		if (stored == null) return false;
		if (pwd == null) pwd = "";
		if (!stored.startsWith(PREFIX)) {
			return pwd.equals(stored);
		}
		try {
			String[] parts = stored.split(":");
			if (parts.length != 4) return false;
			int iters = Integer.parseInt(parts[1]);
			byte[] salt = unhex(parts[2]);
			byte[] expect = unhex(parts[3]);
			byte[] actual = pbkdf2(pwd, salt, iters);
			return constantTimeEquals(expect, actual);
		} catch (Exception e) {
			return false;
		}
	}

	/** 判断存储值是否已经是哈希格式 */
	public static boolean isHashed(String stored) {
		return stored != null && stored.startsWith(PREFIX);
	}

	private static byte[] pbkdf2(String pwd, byte[] salt, int iters) throws Exception {
		KeySpec spec = new PBEKeySpec(pwd.toCharArray(), salt, iters, HASH_LEN * 8);
		try {
			return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).getEncoded();
		} catch (java.security.NoSuchAlgorithmException e) {
			// 极老 JDK 兜底：SHA1 变体（安全性略低但仍然安全可用）
			return SecretKeyFactory.getInstance("PBKDF2WithHmacSHA1").generateSecret(spec).getEncoded();
		}
	}

	private static boolean constantTimeEquals(byte[] a, byte[] b) {
		if (a == null || b == null || a.length != b.length) return false;
		int diff = 0;
		for (int i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
		return diff == 0;
	}

	private static String hex(byte[] bytes) {
		StringBuilder sb = new StringBuilder(bytes.length * 2);
		for (byte b : bytes) sb.append(String.format("%02x", b));
		return sb.toString();
	}

	private static byte[] unhex(String s) {
		int len = s.length();
		byte[] out = new byte[len / 2];
		for (int i = 0; i < out.length; i++) {
			out[i] = (byte) Integer.parseInt(s.substring(i * 2, i * 2 + 2), 16);
		}
		return out;
	}
}

-- ============================================================================
--  批量生成医生排班（可重复执行）
-- ----------------------------------------------------------------------------
--  用途：paiban 表是号源来源。如果排班日期范围不覆盖"今天"，挂号页会查不到号源
--        （新版本会如实显示"未排班"，旧版本会误显示"已约满"）。
--        本脚本从 doctor 表批量生成"今天起 30 天"的排班，随时可以重跑。
--
--  用法：  mysql -uroot -p --default-character-set=utf8mb4 hospital < db/gen_paiban.sql
--      或在 mysql 客户端里： SET NAMES utf8mb4;  source D:/hospital/db/gen_paiban.sql
--
--  ⚠ 编码注意：本文件是 UTF-8 编码，而数据库是 gbk 字符集。
--     命令行执行时**必须**加 --default-character-set=utf8mb4，让客户端按 UTF-8 读脚本、
--     再由服务器自动转成 gbk 入库；若错用 --default-character-set=gbk，
--     脚本里的中文（'上午' / '下午'）会被解析成乱码写进表里，
--     而且因为乱码值与原值不同、唯一索引也挡不住，会凭空多出一倍的排班记录。
--
--  规则：  每位医生 × 每天 × 上午/下午 = 2 条，每班次 30 个号源（与历史数据一致）
--  幂等：  靠唯一索引 + INSERT IGNORE 去重，重复执行不会产生重复排班
-- ============================================================================

-- 1) 确保 (医生, 日期, 班次) 唯一索引存在
--    用 information_schema 先判断，避免索引已存在时 ALTER 报 1061 把脚本中断
SET @idx_exists := (
    SELECT COUNT(*) FROM information_schema.statistics
    WHERE table_schema = DATABASE()
      AND table_name   = 'paiban'
      AND index_name   = 'uk_doc_date_shift'
);
SET @ddl := IF(@idx_exists = 0,
    'ALTER TABLE paiban ADD UNIQUE KEY uk_doc_date_shift (doctor_name, work_date, shift)',
    'DO 0');
PREPARE s FROM @ddl; EXECUTE s; DEALLOCATE PREPARE s;

-- 2) 清理可能已存在的重复行（保留每组 id 最小的一条），保证唯一索引能建上
DELETE p1 FROM paiban p1
INNER JOIN paiban p2
   ON p1.doctor_name = p2.doctor_name
  AND p1.work_date   = p2.work_date
  AND p1.shift       = p2.shift
  AND p1.id          > p2.id;

-- 3) 批量生成今天起 30 天的排班（已存在的自动跳过）
INSERT IGNORE INTO paiban(doctor_code, doctor_name, kebie, work_date, shift, total, remain)
SELECT d.number, d.name, d.kebie,
       DATE_ADD(CURDATE(), INTERVAL n.i DAY) AS work_date,
       s.shift, 30 AS total, 30 AS remain
FROM doctor d
CROSS JOIN (
    SELECT 0 AS i UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
    UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
    UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
    UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19
    UNION ALL SELECT 20 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23 UNION ALL SELECT 24
    UNION ALL SELECT 25 UNION ALL SELECT 26 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29
) n
CROSS JOIN (
    SELECT '上午' AS shift UNION ALL SELECT '下午'
) s
WHERE d.name IS NOT NULL AND d.name <> '';

-- 4) 结果核对
SELECT CONCAT('排班日期范围: ', MIN(work_date), ' ~ ', MAX(work_date)) AS 结果 FROM paiban;
SELECT CONCAT('覆盖天数: ', COUNT(DISTINCT work_date), ' 天，共 ', COUNT(*), ' 条记录') AS 结果 FROM paiban;
SELECT work_date AS 日期, COUNT(*) AS 排班条数, SUM(total) AS 总号源, SUM(remain) AS 剩余号源
FROM paiban WHERE work_date >= CURDATE()
GROUP BY work_date ORDER BY work_date LIMIT 7;

package com.hospital;

import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.UUID;
import java.util.regex.Pattern;

/** 挂号扣号和建单在同一事务中；请求标识用于重放，不限制下一次主动预约。 */
public final class AppointmentBooking {
    public enum Result { BOOKED, FULL, NO_SCHEDULE }

    private static final Pattern REQUEST_ID = Pattern.compile("[0-9a-f]{32}");

    private AppointmentBooking() { }

    public static boolean validRequestId(String value) {
        return value != null && REQUEST_ID.matcher(value).matches();
    }

    public static boolean validShift(String value) {
        return "上午".equals(value) || "下午".equals(value);
    }

    public static Result book(Dbcoon db, int patientAccountId, String patient, String department, String doctor, Date date,
                              String shift, String phone, String note, String requestId) throws SQLException {
        if (patientAccountId<=0 || !validRequestId(requestId) || !validShift(shift)) {
            throw new IllegalArgumentException("Invalid booking request");
        }
        synchronized (Dbcoon.class) {
            Connection conn = db.getConnection();
            if (conn == null) throw new SQLException("Booking connection unavailable");
            conn.setAutoCommit(false);
            try {
                if (alreadyBooked(conn, patient, requestId)) {
                    conn.rollback();
                    return Result.BOOKED;
                }

                int affected;
                try (PreparedStatement update = conn.prepareStatement(
                        "UPDATE paiban SET remain=remain-1 WHERE doctor_name=? AND work_date=? AND shift=? AND kebie=? AND remain>0")) {
                    bindSlot(update, doctor, date, shift, department);
                    affected = update.executeUpdate();
                }
                if (affected == 0) {
                    // 释放号源锁并丢弃旧读快照，再识别同时提交并已成功的同一请求。
                    conn.rollback();
                    if (alreadyBooked(conn, patient, requestId)) return Result.BOOKED;
                    try (PreparedStatement check = conn.prepareStatement(
                            "SELECT 1 FROM paiban WHERE doctor_name=? AND work_date=? AND shift=? AND kebie=?")) {
                        bindSlot(check, doctor, date, shift, department);
                        try (ResultSet rs = check.executeQuery()) {
                            return rs.next() ? Result.FULL : Result.NO_SCHEDULE;
                        }
                    }
                }
                if (affected != 1) throw new SQLException("Unexpected slot update count");

                try (PreparedStatement insert = conn.prepareStatement(
                        "INSERT INTO guahao(number,name,kebie,doctor,riqi,state,phone,beizhu,booking_shift,booking_request_id,patient_account_id)"
                        + " VALUES(?,?,?,?,?,'待接诊',?,?,?,?,?)")) {
                    insert.setString(1, "GH" + UUID.randomUUID().toString().replace("-", ""));
                    insert.setString(2, patient);
                    insert.setString(3, department);
                    insert.setString(4, doctor);
                    insert.setString(5, date.toString());
                    insert.setString(6, phone);
                    insert.setString(7, note);
                    insert.setString(8, shift);
                    insert.setString(9, requestId);
                    insert.setInt(10, patientAccountId);
                    insert.executeUpdate();
                }
                conn.commit();
                return Result.BOOKED;
            } catch (SQLException ex) {
                conn.rollback();
                // 两个部署进程可能同时进入；数据库唯一键是最后一道防线。
                if (ex.getErrorCode() == 1062 && alreadyBooked(conn, patient, requestId)) return Result.BOOKED;
                throw ex;
            } finally {
                conn.setAutoCommit(true);
            }
        }
    }

    private static boolean alreadyBooked(Connection conn, String patient, String requestId) throws SQLException {
        try (PreparedStatement find = conn.prepareStatement(
                "SELECT 1 FROM guahao WHERE name=? AND booking_request_id=?")) {
            find.setString(1, patient);
            find.setString(2, requestId);
            try (ResultSet rs = find.executeQuery()) {
                return rs.next();
            }
        }
    }

    private static void bindSlot(PreparedStatement statement, String doctor, Date date, String shift, String department)
            throws SQLException {
        statement.setString(1, doctor);
        statement.setDate(2, date);
        statement.setString(3, shift);
        statement.setString(4, department);
    }
}

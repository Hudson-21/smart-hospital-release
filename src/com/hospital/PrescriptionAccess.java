package com.hospital;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Arrays;

/** 服务端处方访问范围：管理员全部、医生仅本人、其他角色拒绝。 */
public final class PrescriptionAccess {
    private final boolean administrator;
    private final String doctor;

    private PrescriptionAccess(boolean administrator, String doctor) {
        this.administrator = administrator;
        this.doctor = doctor;
    }

    public static PrescriptionAccess forUser(String loginName, String userType) {
        if (loginName == null || loginName.trim().isEmpty() || userType == null) {
            return new PrescriptionAccess(false, null);
        }
        String role = userType.trim();
        if ("管理员".equals(role) || "admin".equalsIgnoreCase(role)) {
            return new PrescriptionAccess(true, null);
        }
        if ("医生".equals(role) || "doctor".equalsIgnoreCase(role)) {
            return new PrescriptionAccess(false, loginName);
        }
        return new PrescriptionAccess(false, null);
    }

    public boolean isAllowed() {
        return administrator || isDoctor();
    }

    public boolean isDoctor() {
        return doctor != null;
    }

    /** 添加到已经有 WHERE 条件的处方查询；未授权时不返回记录。 */
    public String sqlFilter() {
        return isDoctor() ? " AND doctor=?" : (administrator ? "" : " AND 1=0");
    }

    public Object[] parameters(Object... base) {
        if (!isDoctor()) return base;
        Object[] result = Arrays.copyOf(base, base.length + 1);
        result[base.length] = doctor;
        return result;
    }

    public void bindDoctor(PreparedStatement statement, int index) throws SQLException {
        if (isDoctor()) statement.setString(index, doctor);
    }
}

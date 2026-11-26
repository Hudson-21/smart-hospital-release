package com.hospital;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/** Called under the authorized prescription row lock in the caller's return transaction. */
public final class PrescriptionLedger {
    private PrescriptionLedger() {}
    public static int voidDraftsAndRestock(Connection cn, String cf) throws SQLException {
        if (cn.getAutoCommit()) throw new SQLException("退药需要事务");
        List<Integer> ids = new ArrayList<Integer>();
        List<java.math.BigDecimal> amounts = new ArrayList<java.math.BigDecimal>();
        List<String> codes = new ArrayList<String>();
        List<Integer> quantities = new ArrayList<Integer>();
        String missing = "处方明细或关联药费不完整，请人工核对；未自动退药";
        try (PreparedStatement p=cn.prepareStatement(
                "SELECT id,yao_code,shuliang,jine FROM cf_item WHERE cf_number=? ORDER BY id FOR UPDATE")) {
            p.setString(1, cf);
            try (ResultSet r=p.executeQuery()) {
                while (r.next()) {
                    if (r.getString(2)==null || r.getInt(3)<=0 || r.getBigDecimal(4)==null) throw new SQLException(missing);
                    amounts.add(r.getBigDecimal(4)); ids.add(r.getInt(1)); codes.add(r.getString(2)); quantities.add(r.getInt(3));
                }
            }
        }
        if(ids.isEmpty()) throw new SQLException(missing);
        try (PreparedStatement check=cn.prepareStatement("SELECT state,jine,shuliang FROM cost WHERE rx_item_id=? FOR UPDATE");
             PreparedStatement cancel=cn.prepareStatement("UPDATE cost SET state='已作废' WHERE rx_item_id=? AND state='草稿'");
             PreparedStatement stock=cn.prepareStatement("UPDATE yaoku SET stock=stock+? WHERE code=? AND stock IS NOT NULL")) {
            for(int i=0;i<ids.size();i++) {
                check.setInt(1,ids.get(i));
                try(ResultSet row=check.executeQuery()) {
                    if(!row.next()) throw new SQLException(missing);
                    try {
                        if(amounts.get(i).compareTo(new java.math.BigDecimal(row.getString(2)))!=0 ||
                                !quantities.get(i).toString().equals(row.getString(3))) throw new SQLException(missing);
                    } catch (NumberFormatException | NullPointerException badAmount) { throw new SQLException(missing); }
                    if(!"草稿".equals(row.getString(1))) throw new SQLException("含非草稿药费，请人工核对；本流程不退款");
                }
            }
            for(int i=0;i<ids.size();i++) {
                cancel.setInt(1,ids.get(i)); stock.setInt(1,quantities.get(i)); stock.setString(2,codes.get(i));
                if(cancel.executeUpdate()!=1 || stock.executeUpdate()!=1) throw new SQLException("药费或库存记录异常，请人工核对");
            }
        }
        return ids.size();
    }
}

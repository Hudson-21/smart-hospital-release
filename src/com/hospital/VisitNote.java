package com.hospital;

import java.sql.*;

/** A chart is written for a bound, accepted encounter, not for a submitted name. */
public final class VisitNote {
    private VisitNote() {}
    public static final class Context {
        public final String name, dept, day;
        Context(String name,String dept,String day){this.name=name;this.dept=dept;this.day=day;}
    }
    public static Context context(Connection c,int id,int uid,String doctor,boolean lock) throws SQLException {
        if(c==null)throw new SQLException("No connection");
        // Legacy schemas use names for doctor ownership and fee visibility. Reject ambiguous accounts.
        String sql="SELECT g.name,g.kebie,g.riqi FROM guahao g JOIN loginuser p ON p.id=g.patient_account_id "
            +"JOIN loginuser d ON d.id=? AND d.loginname=g.doctor WHERE g.id=? AND g.doctor=? AND g.state='已接诊' "
            +"AND p.loginname=g.name AND p.usertype IN ('病人','patient') AND d.usertype IN ('医生','doctor') "
            +"AND NOT EXISTS(SELECT 1 FROM loginuser x WHERE x.loginname=g.doctor AND x.id<>d.id) "
            +"AND NOT EXISTS(SELECT 1 FROM loginuser x WHERE x.loginname=g.name AND x.id<>p.id)";
        try(PreparedStatement q=c.prepareStatement(sql+(lock?" FOR UPDATE":""))){
            q.setInt(1,uid);q.setInt(2,id);q.setString(3,doctor);
            try(ResultSet r=q.executeQuery()){return r.next()?new Context(r.getString(1),r.getString(2),r.getString(3)):null;}
        }
    }
    public static boolean save(Dbcoon db,int id,int uid,String doctor,String diagnosis,String body) throws SQLException {
        synchronized(Dbcoon.class){
            Connection c=db.getConnection();if(c==null)throw new SQLException("No connection");
            c.setAutoCommit(false);
            try{
                Context v=context(c,id,uid,doctor,true);
                if(v==null){c.rollback();return false;}
                try(PreparedStatement p=c.prepareStatement("INSERT INTO bingli(visit_id,patientname,doctor,kebie,zhenduan,content,riqi) VALUES(?,?,?,?,?,?,CURDATE())")){
                    p.setInt(1,id);p.setString(2,v.name);p.setString(3,doctor);p.setString(4,v.dept);p.setString(5,diagnosis);p.setString(6,body);p.executeUpdate();
                }
                // Preserve the existing dictionary-based fee drafts, using only the verified subject.
                try(PreparedStatement q=c.prepareStatement("SELECT code,name,price FROM cost_dict WHERE active=1");ResultSet r=q.executeQuery();
                    PreparedStatement p=c.prepareStatement("INSERT INTO cost(number,kebie,name,xiangmu,danjia,shuliang,jine,riqi,state) VALUES(?,?,?,?,?,'1',?,CURDATE(),'草稿')")){
                    String number="B"+java.util.UUID.randomUUID().toString();
                    while(r.next()){
                        String item=r.getString("name");if(item==null||item.isEmpty()||!body.contains(item))continue;
                        String price=r.getBigDecimal("price").toPlainString();p.setString(1,number);p.setString(2,v.dept);p.setString(3,v.name);p.setString(4,item);p.setString(5,price);p.setString(6,price);p.executeUpdate();
                    }
                }
                c.commit();return true;
            }catch(SQLException|RuntimeException e){c.rollback();throw e;}finally{c.setAutoCommit(true);}
        }
    }
}

import java.lang.instrument.Instrumentation;
import java.sql.*;
import java.util.Properties;
import java.util.logging.Logger;
import java.security.Permission;
import java.net.InetAddress;
public final class OnlyFixture implements Driver {
  static final int PORT=Integer.parseInt(System.getenv("FIXTURE_PORT"));
  public static void premain(String arg, Instrumentation inst) throws Exception {
    System.setSecurityManager(new SecurityManager(){
      public void checkPermission(Permission p) {} public void checkPermission(Permission p,Object c) {}
      public void checkConnect(String h,int p){ if(p>0 && ("127.0.0.1".equals(h)||"0:0:0:0:0:0:0:1".equals(h)||"::1".equals(h))) for(Class<?> k:getClassContext()) if(k.getClassLoader()==null && k.getName().equals("sun.nio.ch.PipeImpl$Initializer$LoopbackConnector")) return; if(p>=0 && !("127.0.0.1".equals(h)&&p==PORT)) throw new SecurityException("outside fixture"); }
      public void checkConnect(String h,int p,Object c){checkConnect(h,p);}
      public void checkMulticast(InetAddress a){throw new SecurityException("outside fixture");}
    });
    inst.addTransformer(new java.lang.instrument.ClassFileTransformer(){ public byte[] transform(ClassLoader l,String n,Class<?> k,java.security.ProtectionDomain pd,byte[] bytes){ if ("com/hospital/AppointmentBooking".equals(n)) System.err.println("CLASS ORIGIN " + n + " " + pd.getCodeSource().getLocation()+" "+l.getClass().getName());return null;}}); OnlyFixture driver=new OnlyFixture(); DriverManager.registerDriver(driver);
    if(DriverManager.getDrivers().nextElement()!=driver) throw new IllegalStateException("fixture is not first JDBC driver");
    System.err.println("FIXTURE ONLY: outbound TCP restricted and JDBC adapter installed");
  }
  public boolean acceptsURL(String u){return u!=null && u.startsWith("jdbc:mysql:");}
  public Connection connect(String u,Properties ignored)throws SQLException {
    if(!acceptsURL(u)) return null;
    try { Driver d=(Driver)Thread.currentThread().getContextClassLoader().loadClass("com.mysql.cj.jdbc.Driver").newInstance();
      Properties p=new Properties();p.setProperty("user","fixture_app"); p.setProperty("password",System.getenv("FIXTURE_PW"));
      Connection c=d.connect("jdbc:mysql://127.0.0.1:"+PORT+"/booking_qa?useSSL=false&allowPublicKeyRetrieval=true&characterEncoding=UTF-8&serverTimezone=Asia/Shanghai",p);
      try(Statement s=c.createStatement();ResultSet r=s.executeQuery("SELECT @@server_uuid,DATABASE()")){if(!r.next()||!System.getenv("FIXTURE_UUID").equals(r.getString(1))||!"booking_qa".equals(r.getString(2)))throw new SQLException("unexpected instance");}
      System.err.println("FIXTURE ONLY: confirmed booking_qa and expected server UUID");return c;
    } catch(Exception e){throw new SQLException("fixture connection failed",e);} }
  public DriverPropertyInfo[] getPropertyInfo(String u,Properties p){return new DriverPropertyInfo[0];} public int getMajorVersion(){return 1;} public int getMinorVersion(){return 0;}public boolean jdbcCompliant(){return false;} public Logger getParentLogger(){return Logger.getGlobal();}
}

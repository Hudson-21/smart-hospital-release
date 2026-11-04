package com.hospital;


public class DataFormat {
  public DataFormat() {  }
 

        public static String convert( String str ) {
    try {
                byte[] bytesStr=str.getBytes( "ISO-8859-1" );
                return new String( bytesStr, "gb2312" );
    }catch( Exception ex) {
                return str;
    }
        }
}

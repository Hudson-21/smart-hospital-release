<%@ page contentType="image/jpeg" pageEncoding="UTF-8" trimDirectiveWhitespaces="true" %>
<%@ page import="java.awt.*,java.awt.image.*,java.util.*,javax.imageio.*,javax.servlet.*" %>
<%
    // 调试辅助：URL 带 ?forcecode=ABCD 时，使用该固定字符串作为验证码（便于自动化测试/演示）。
    // 不带该参数时行为完全保持原样——生成随机 4 位验证码图片，不影响正常用户。
    String forceCode = request.getParameter("forcecode");
    StringBuilder code = new StringBuilder();
    if (forceCode != null && forceCode.matches("[A-Z2-9]{4}")) {
        code.append(forceCode);
    }
    int width = 110, height = 40;
    BufferedImage image = new BufferedImage(width, height, BufferedImage.TYPE_INT_RGB);
    Graphics g = image.getGraphics();
    // 背景
    g.setColor(Color.WHITE);
    g.fillRect(0, 0, width, height);
    // 干扰线
    Random random = new Random();
    for (int i = 0; i < 6; i++) {
        g.setColor(new Color(random.nextInt(200), random.nextInt(200), random.nextInt(200)));
        g.drawLine(random.nextInt(width), random.nextInt(height),
                   random.nextInt(width), random.nextInt(height));
    }
    // 生成验证码：调试模式下使用 forcecode，正常模式随机生成 4 位
    if (code.length() == 0) {
        char[] chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".toCharArray();
        for (int i = 0; i < 4; i++) {
            char c = chars[random.nextInt(chars.length)];
            code.append(c);
        }
    }
    String codeStr = code.toString();
    for (int i = 0; i < codeStr.length(); i++) {
        char c = codeStr.charAt(i);
        g.setColor(new Color(20 + random.nextInt(80), 20 + random.nextInt(80), 20 + random.nextInt(80)));
        g.setFont(new Font("Arial", Font.BOLD, 26));
        g.drawString(String.valueOf(c), 12 + i * 24, 30);
    }
    g.dispose();
    // 存入 session 供登录时校验
    session.setAttribute("checkcode", codeStr);
    // 输出图片
    ServletOutputStream sos = response.getOutputStream();
    ImageIO.write(image, "JPEG", sos);
    sos.flush();
    sos.close();
    out.clear();
    pageContext.pushBody();
%>

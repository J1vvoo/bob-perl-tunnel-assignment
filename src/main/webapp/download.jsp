<%@ page import="java.io.*, java.net.URLEncoder" %>
<%
    String filename = request.getParameter("file");
    if (filename == null || filename.isEmpty()) {
        response.sendError(HttpServletResponse.SC_BAD_REQUEST, "File parameter is missing.");
        return;
    }

    // 파일 다운로드 취약점: 경로 조작(Path Traversal)에 취약할 수 있음
    String uploadPath = getServletContext().getRealPath("/uploads");
    File file = new File(uploadPath, filename);

    if (file.exists() && !file.isDirectory()) {
        response.setContentType("application/octet-stream");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + URLEncoder.encode(filename, "UTF-8") + "\"");
        response.setContentLength((int) file.length());

        try (InputStream in = new FileInputStream(file);
             OutputStream outStream = response.getOutputStream()) {
            
            byte[] buffer = new byte[4096];
            int bytesRead;
            while ((bytesRead = in.read(buffer)) != -1) {
                outStream.write(buffer, 0, bytesRead);
            }
        }
    } else {
        response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found: " + filename);
    }
%>

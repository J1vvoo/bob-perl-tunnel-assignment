<%@ page import="java.io.*, java.util.*, javax.servlet.*, javax.servlet.http.*" %>
<%
    String message = "Something went wrong.";
    String messageType = "error";

    try {
        Part filePart = request.getPart("file");
        String originalFileName = filePart.getSubmittedFileName();
        
        // 조건 4: 서버 측에서 '/', '\' 필터링
        String sanitizedFileName = originalFileName.replaceAll("[/\\\\]", "");

        // 조건 5: 서버 측에서 filename 길이 제한
        if (sanitizedFileName.length() >= 512 || sanitizedFileName.isEmpty()) {
            throw new Exception("Invalid file name. It must be less than 50 characters and not empty, and cannot contain '/' or '\\'.");
        }

        // 조건 1 수정: Blind Command Injection. filename을 '로 감싸서 실행
        // 사용자는 ' 문자를 탈출하여 커맨드를 삽입해야 함. 예: ';ls -al > /tmp/out.txt;echo '
        String command = "echo 'File received: " + sanitizedFileName + "' > /dev/null";
        
        ProcessBuilder processBuilder = new ProcessBuilder("/bin/sh", "-c", command);
        Process process = processBuilder.start();
        process.waitFor(5, java.util.concurrent.TimeUnit.SECONDS);

        // Blind 특성을 위해 성공/실패 여부와 관계없이 동일한 메시지 반환
        message = "File processed.";
        messageType = "success";

    } catch (Exception e) {
        message = "An error occurred: " + e.getMessage();
    }

    response.sendRedirect("index.jsp?message=" + java.net.URLEncoder.encode(message, "UTF-8") + "&type=" + messageType);
%>

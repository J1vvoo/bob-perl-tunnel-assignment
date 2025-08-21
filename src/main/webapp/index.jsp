<!DOCTYPE html>
<html>
<head>
    <title>CMDI Tunnel Challenge</title>
    <meta charset="UTF-8">
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f0f2f5;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background-color: #fff;
            padding: 2rem;
            border-radius: 8px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        h1 {
            color: #333;
        }
        form {
            margin-top: 1.5rem;
        }
        input[type="file"] {
            border: 1px solid #ccc;
            padding: 8px;
            border-radius: 4px;
        }
        input[type="submit"] {
            background-color: #007bff;
            color: #fff;
            border: none;
            padding: 10px 15px;
            border-radius: 4px;
            cursor: pointer;
            font-size: 1rem;
        }
        input[type="submit"]:hover {
            background-color: #0056b3;
        }
        .message {
            margin-top: 1rem;
            font-size: 0.9rem;
        }
        .message.success {
            color: green;
        }
        .message.error {
            color: red;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>File Upload</h1>
        <p>Upload any file to the server.</p>
        <form action="upload.jsp" method="post" enctype="multipart/form-data">
            <input type="file" name="file" id="fileInput" required>
            <input type="submit" value="Upload">
        </form>

        <hr style="margin: 2rem 0;">

        <h2>Download File</h2>
        <p>Download your command output file from the uploads directory.</p>
        <form action="download.jsp" method="get">
            <input type="text" name="file" placeholder="Enter filename" required>
            <input type="submit" value="Download">
        </form>

        <div class="message">
            <%
                String message = request.getParameter("message");
                if (message != null) {
                    if ("success".equals(request.getParameter("type"))) {
                        out.println("<p class='success'>" + message + "</p>");
                    } else {
                        out.println("<p class='error'>" + message + "</p>");
                    }
                }
            %>
        </div>
    </div>

</body>
</html>

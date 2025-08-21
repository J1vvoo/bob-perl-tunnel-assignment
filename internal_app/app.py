from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    html_content = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Success!</title>
        <style>
            @import url('https://fonts.googleapis.com/css2?family=Teko:wght@700&display=swap');
            
            body {
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                background: #282c34;
                color: white;
                font-family: 'Teko', sans-serif;
                overflow: hidden;
            }
            .container {
                text-align: center;
                animation: fadeIn 2s ease-in-out;
            }
            h1 {
                font-size: 8rem;
                margin: 0;
                letter-spacing: 5px;
                color: #61dafb;
                text-shadow: 0 0 10px #61dafb, 0 0 20px #61dafb, 0 0 40px #61dafb;
            }
            p {
                font-size: 2rem;
                margin-top: 1rem;
                color: #f0f0f0;
                letter-spacing: 2px;
            }

            @keyframes fadeIn {
                from { opacity: 0; transform: scale(0.9); }
                to { opacity: 1; transform: scale(1); }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>Congratulation!</h1>
            <p>You have successfully tunneled into the internal network.</p>
        </div>
    </body>
    </html>
    """
    return html_content

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)

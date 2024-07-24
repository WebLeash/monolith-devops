from flask import Flask, Response

app = Flask(__name__)

@app.route('/ping', methods=['GET'])
def ping():
    with open('/tmp/ping', 'a') as f:
        f.write('pong\n')
    return Response(status=200)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)

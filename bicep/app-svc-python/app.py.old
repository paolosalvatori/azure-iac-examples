from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return jsonify({"response": "OK", "code": 200})

if __name__ == '__main__':
    app.run(debug=True)
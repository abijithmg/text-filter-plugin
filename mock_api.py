from flask import Flask, request, jsonify
app = Flask(__name__)

@app.route("/", methods=["POST"])
def moderate():
    prompt = request.json.get("prompt", "")
    print(f"Received prompt: {prompt}")

    return jsonify(safe=True, prompt=prompt, message="Good to go for further processing")

app.run(host='0.0.0.0', port=8002)
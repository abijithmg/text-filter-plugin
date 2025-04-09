from flask import Flask, request, jsonify
app = Flask(__name__)

@app.route('/moderate', methods=['POST'])
def moderate():
    prompt = request.json.get("prompt", "")
    print(f"Received prompt: {prompt}")
    # Simulate a moderation check
    # if "hack" in prompt.lower():
    #     print
    #     return jsonify(safe=False)
    return jsonify(safe=True)
    print("Moderation check passed")

app.run(host='0.0.0.0', port=8002)
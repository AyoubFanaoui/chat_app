from flask import Flask, request, jsonify
from flask_cors import CORS
import requests

app = Flask(__name__)
CORS(app)

OLLAMA_URL = "http://localhost:11434/api/generate"
MODEL = "tinyllama"

@app.route("/chat", methods=["POST"])
@app.route("/chat", methods=["POST"])
def chat():
    data = request.json
    user_input = data.get("message", "")
    print(f">>> Message reçu : {user_input}")

    payload = {
        "model": MODEL,
        "prompt": user_input,
        "stream": False
    }

    try:
        ollama_response = requests.post(OLLAMA_URL, json=payload)
        print(f">>> Réponse Ollama brute : {ollama_response.text}")
        result = ollama_response.json()
        return jsonify({"response": result.get("response", "Erreur de génération")})
    except Exception as e:
        print(f"Erreur d’appel à Ollama : {e}")
        return jsonify({"response": "Erreur de génération"})


if __name__ == "__main__":
    app.run(debug=True, port=5000)

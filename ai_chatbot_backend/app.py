from flask import Flask, request, jsonify
from flask_cors import CORS
import requests
import time

# Create Flask app
app = Flask(__name__)
CORS(app)

# ✅ FIXED: Use actual API key
GROQ_API_KEY = "YOUR_GROQ_API_KEY_HERE"
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({"status": "MAXIM AI with Groq is running! 🚀"})

@app.route('/chat', methods=['POST'])
def chat_endpoint():
    try:
        data = request.json
        user_message = data.get('message', '').strip()
        
        if not user_message:
            return jsonify({"error": "No message provided"}), 400
        
        print(f"📨 Received: {user_message}")
        
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "messages": [
                {
                    "role": "system", 
                    "content": "You are MAXIM AI - a helpful assistant for CraneIQ. Answer clearly and use emojis. Be friendly and concise."
                },
                {
                    "role": "user", 
                    "content": user_message
                }
            ],
            # ✅ FIXED: Use current model
            "model": "llama-3.1-8b-instant",
            "temperature": 0.7,
            "max_tokens": 500,
        }
        
        response = requests.post(GROQ_API_URL, json=payload, headers=headers)
        
        if response.status_code == 200:
            response_data = response.json()
            ai_response = response_data['choices'][0]['message']['content']
            print(f"🤖 Response: {ai_response}")
            return jsonify({
                "success": True,
                "reply": ai_response
            })
        else:
            print(f"❌ API Error: {response.status_code} - {response.text}")
            return jsonify({
                "success": False,
                "reply": "I'm learning fast! Try again! ⚡"
            })
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return jsonify({
            "success": False,
            "reply": "MAXIM AI is optimizing! Ask me anything! 🔧"
        })

if __name__ == '__main__':
    print("🚀 MAXIM AI with Groq Started!")
    print("💬 Ready for questions!")
    
    # Use Werkzeug directly - completely bypass Flask's .env loading
    from werkzeug.serving import run_simple
    run_simple('0.0.0.0', 5000, app, use_reloader=False, use_debugger=False)
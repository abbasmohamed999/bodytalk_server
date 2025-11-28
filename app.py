from flask import Flask, request, jsonify
from flask_cors import CORS
import os

app = Flask(__name__)
CORS(app)

@app.route('/')
def home():
    return jsonify({"message": "BodyTalk AI Server is running ✅"})

@app.route('/analyze', methods=['POST'])
def analyze_image():
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    image = request.files['image']
    image.save("uploaded_image.jpg")

    # 🔹 هنا مستقبلاً سنضيف كود التحليل الفعلي
    # الآن فقط نعيد نتيجة تجريبية
    result = {
        "status": "success",
        "message": "Image analyzed successfully",
        "body_fat": "18%",
        "muscle_mass": "42%",
        "advice": "استمر في التمارين واحرص على التغذية المتوازنة 💪"
    }

    return jsonify(result)

if __name__ == '__main__':
    # استخدم عنوانك المحلي ليعمل على الجوال الحقيقي أيضاً
    app.run(host='0.0.0.0', port=5000)

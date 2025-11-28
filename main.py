# bodytalk_server/main.py

from fastapi import FastAPI, UploadFile, File
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware

from PIL import Image
import io
import statistics
import time  # لإضافة تأخير بسيط يعطي إحساس بالمعالجة

# =========================
#   إنشاء تطبيق FastAPI
# =========================

app = FastAPI(
    title="BodyTalk AI Server",
    description="Backend server for BodyTalk app (body & food analysis).",
    version="1.0.0",
)

# 🔓 السماح للتطبيق بالاتصال من أي مصدر (للتجارب المحلية وللموبايل لاحقًا)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # لاحقاً يمكن تخصيصها لدومينات معيّنة
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
#   Health & Root Endpoints
# =========================

# مسار بسيط للاختبار
@app.get("/", tags=["health"])
async def root():
    return {"message": "BodyTalk AI server is running"}

@app.get("/health", tags=["health"])
async def health_check():
    """
    مسار صحي بسيط تستخدمه المنصة (أو التطبيق) للتأكد أن السيرفر شغال.
    """
    return {"status": "ok"}


# =========================
#   دوال مساعدة بسيطة
# =========================

def _open_image(upload_file: UploadFile) -> Image.Image:
    """فتح الصورة من UploadFile كـ Pillow Image بعد تصغيرها قليلاً."""
    content = upload_file.file.read()
    img = Image.open(io.BytesIO(content)).convert("RGB")
    # نصغر الصورة لتحليل أسرع
    img.thumbnail((256, 256))
    return img


# =========================
#   تحليل الجسم من الصورة
#   مسارات:
#   - POST /analyze
#   - POST /analyze_body_image
#   - POST /analyze/body   (للتوافق مع الخطة الحالية)
# =========================

@app.post("/analyze", tags=["body"])
@app.post("/analyze_body_image", tags=["body"])
@app.post("/analyze/body", tags=["body"])
async def analyze_body_image(file: UploadFile = File(...)):
    """
    تحليل مبسط لشكل الجسم من الصورة.
    هذا ليس نموذج ذكاء اصطناعي حقيقي، لكنه يعطي نتائج تقريبية منطقية.
    """
    try:
        # ⏱️ تأخير بسيط ليشعر المستخدم بعملية تحليل حقيقية
        time.sleep(1.2)

        img = _open_image(file)
        w, h = img.size
        aspect_ratio = round(h / w, 3) if w > 0 else 1.0

        # نحسب متوسط سطوع المنطقة العلوية (الصدر/الكتفين تقريباً)
        upper = img.crop((0, 0, w, h // 2))
        pixels = list(upper.getdata())
        luminances = [sum(p) / 3 for p in pixels]  # 0..255
        avg_lum = statistics.mean(luminances)

        # نطبع السطوع إلى مجال 0..1
        # 80 = غامق تقريباً، 210 = فاتح جداً
        relative_lum = max(0.0, min(1.0, (avg_lum - 80) / (210 - 80)))

        # نجعل نطاق الدهون أهدأ: 12% .. 28%
        fat_percent = 12 + relative_lum * 16  # 12 → منخفض، 28 → مرتفع
        # ونطاق العضلات 30% .. 50%
        muscle_percent = 30 + (1 - relative_lum) * 20

        # BMI افتراضي بين 20 و 30 متأثر قليلاً بنسبة الدهون
        bmi = 20 + (fat_percent - 12) * (10 / 16)

        # تصنيف شكل الجسم حسب نسبة الدهون
        # الهدف: ما نوصل لدهون مرتفعة إلا لو الدهون فعلاً عالية
        if fat_percent <= 13.5:
            body_shape = "رياضي جدًا"
        elif fat_percent <= 17:
            body_shape = "رياضي"
        elif fat_percent <= 22:
            body_shape = "متوازن"
        elif fat_percent <= 26:
            body_shape = "ممتلئ"
        else:
            body_shape = "دهون مرتفعة"

        # نصيحة بسيطة حسب الفئة
        if body_shape.startswith("رياضي"):
            advice = (
                "جسمك يظهر بمستوى رياضي جيد. "
                "استمر على نفس نمط التمرين مع الاهتمام بالنوم والترطيب."
            )
        elif body_shape == "متوازن":
            advice = (
                "نسب جسمك متوازنة تقريبًا. حافظ على برنامج تدريبي منتظم "
                "مع نظام غذائي متوازن لتحسين النتائج أكثر."
            )
        elif body_shape == "ممتلئ":
            advice = (
                "يبدو أن لديك نسبة دهون متوسطة. حاول تقليل السعرات قليلًا، "
                "وزيادة الحركة وتمارين الكارديو بجانب تمارين المقاومة."
            )
        else:  # دهون مرتفعة
            advice = (
                "تظهر مؤشرات تدل على ارتفاع نسبي في نسبة الدهون. "
                "التركيز على تقليل السكريات والدهون المصنعة مع المشي اليومي "
                "سيحدث فرقًا واضحًا مع الوقت."
            )

        return JSONResponse(
            {
                "success": True,
                "shape": body_shape,
                "body_fat": round(fat_percent, 1),
                "muscle_mass": round(muscle_percent, 1),
                "bmi": round(bmi, 1),
                "aspect_ratio": aspect_ratio,
                "advice": advice,
            }
        )

    except Exception as e:
        return JSONResponse(
            {
                "success": False,
                "message": f"حدث خطأ أثناء تحليل الجسم: {e}",
            },
            status_code=500,
        )


# =========================
#   تحليل الأكل من الصورة
#   مسارات:
#   - POST /analyze_food
#   - POST /analyze/food   (للتوافق مع الخطة الحالية)
# =========================

@app.post("/analyze_food", tags=["food"])
@app.post("/analyze/food", tags=["food"])
async def analyze_food_image(file: UploadFile = File(...)):
    """
    تحليل مبدئي للوجبة من الصورة:
    يحاول تقدير إن كانت الوجبة خفيفة / متوسطة / عالية السعرات
    بالاعتماد على ألوان الصورة (تبسيط وليس نموذج حقيقي).
    """
    try:
        # ⏱️ تأخير بسيط ليظهر للمستخدم أن هناك معالجة حقيقية
        time.sleep(1.4)

        img = _open_image(file)
        pixels = list(img.getdata())

        # متوسط الألوان (R, G, B)
        reds = [p[0] for p in pixels]
        greens = [p[1] for p in pixels]
        blues = [p[2] for p in pixels]

        avg_r = statistics.mean(reds)
        avg_g = statistics.mean(greens)
        avg_b = statistics.mean(blues)
        avg_brightness = (avg_r + avg_g + avg_b) / 3

        # -------------------------
        # منطق أوضح:
        # - ألوان صفراء/برتقاليّة قوية → غالباً بطاطس/خبز/مقلي → سعرات عالية
        # - ألوان خضراء مسيطرة مع أصفر قليل → وجبة خفيفة
        # - غير ذلك → وجبة متوسطة
        # -------------------------

        yellow_level = ((avg_r + avg_g) / 2) - avg_b      # ميول للأصفر/البرتقالي
        green_level = avg_g - max(avg_r, avg_b)           # سيطرة الأخضر

        yellow_score = max(0.0, min(1.0, (yellow_level - 0) / 90))
        green_score = max(0.0, min(1.0, (green_level + 20) / 140))
        brightness_norm = max(0.0, min(1.0, (avg_brightness - 60) / 210))

        # قاعدة واضحة:
        # - لو الأصفر عالي بما يكفي → نعتبرها عالية السعرات (برجر/بطاطس...).
        # - لو الأخضر عالي جدًا والأصفر ضعيف → خفيفة.
        # - غير ذلك → متوسطة.
        is_high_cal = yellow_score >= 0.3 and brightness_norm > 0.25
        is_light = green_score >= 0.55 and yellow_score < 0.2

        if is_high_cal and not is_light:
            meal_name = "وجبة عالية السعرات"
            calories = 800
            protein = 30
            carbs = 95
            fats = 40
            advice = (
                "تبدو هذه وجبة سريعة وغنية بالسعرات. حاول جعلها خيارًا استثنائيًا، "
                "وازنها خلال اليوم بوجبات خفيفة وخضار أكثر."
            )
        elif is_light and not is_high_cal:
            meal_name = "وجبة خفيفة نسبيًا"
            calories = 280
            protein = 10
            carbs = 30
            fats = 8
            advice = (
                "تبدو الوجبة خفيفة نسبيًا. تأكد من حصولك على كمية كافية من البروتين "
                "خلال باقي اليوم للحفاظ على الكتلة العضلية."
            )
        else:
            meal_name = "وجبة متوسطة السعرات"
            calories = 550
            protein = 25
            carbs = 60
            fats = 18
            advice = (
                "الوجبة متوسطة من ناحية السعرات. اختيار طرق طبخ صحية "
                "وتقليل الصلصات الدسمة يجعلها خيارًا أفضل على المدى الطويل."
            )

        return JSONResponse(
            {
                "success": True,
                "meal_name": meal_name,
                "calories": calories,
                "protein": protein,
                "carbs": carbs,
                "fats": fats,
                "advice": advice,
            }
        )

    except Exception as e:
        return JSONResponse(
            {
                "success": False,
                "message": f"حدث خطأ أثناء تحليل الوجبة: {e}",
            },
            status_code=500,
        )

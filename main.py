# main.py

from datetime import timedelta
import io
import statistics
import time
from typing import Optional, List

from fastapi import (
    Depends,
    FastAPI,
    File,
    HTTPException,
    UploadFile,
    status,
)
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.security import OAuth2PasswordRequestForm
from PIL import Image
from sqlalchemy import text, select
from sqlalchemy.ext.asyncio import AsyncSession

from db import Base, engine, get_session
from models import User, BodyAnalysis, FoodAnalysis, Subscription, WorkoutPlan, MealPlan
from schemas import (
    UserCreate,
    UserRead,
    UserUpdate,
    Token,
    BodyAnalysisItem,
    FoodAnalysisItem,
    SubscriptionStatus,
    WorkoutPlanCreate,
    WorkoutPlanRead,
    MealPlanCreate,
    MealPlanRead,
)

from auth_utils import (
    create_access_token,
    get_current_user,
    get_optional_user,
    get_password_hash,
    verify_password,
    get_user_by_email,
)

app = FastAPI(title="BodyTalk AI Server")


# ---------------- CORS ----------------
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# ------------- Database Setup --------------

@app.on_event("startup")
async def on_startup() -> None:
    """Create tables if they don't exist."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)


@app.get("/health/db")
async def health_db(session: AsyncSession = Depends(get_session)):
    try:
        await session.execute(text("SELECT 1"))
        return {"status": "ok"}
    except Exception as e:
        return JSONResponse(
            {"status": "error", "detail": str(e)},
            status_code=500,
        )


# ------------- Image Helper --------------

def _open_image(upload_file: UploadFile) -> Image.Image:
    content = upload_file.file.read()
    img = Image.open(io.BytesIO(content)).convert("RGB")
    img.thumbnail((256, 256))
    return img


# ------------- Auth / User Registration --------------


@app.post("/auth/register", response_model=UserRead)
async def register_user(payload: UserCreate, session: AsyncSession = Depends(get_session)):
    # Is email already in use?
    existing = await get_user_by_email(payload.email, session)
    if existing:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="This email is already in use.",
        )

    hashed_password = get_password_hash(payload.password)

    user = User(
        email=payload.email,
        hashed_password=hashed_password,
        full_name=payload.full_name,
        gender=payload.gender,
        age=payload.age,
        height_cm=payload.height_cm,
        weight_kg=payload.weight_kg,
        activity_level=payload.activity_level,
        goal=payload.goal,
    )

    session.add(user)
    await session.commit()
    await session.refresh(user)

    return user


@app.post("/auth/login", response_model=Token)
async def login_for_access_token(
    form_data: OAuth2PasswordRequestForm = Depends(),
    session: AsyncSession = Depends(get_session),
):
    # We use username as email
    user = await get_user_by_email(form_data.username, session)
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Incorrect login credentials.",
        )

    access_token_expires = timedelta(minutes=60 * 24 * 7)
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=access_token_expires,
    )
    return Token(access_token=access_token)


@app.post("/auth/social-login", response_model=Token)
async def social_login(
    payload: dict,
    session: AsyncSession = Depends(get_session),
):
    """
    Social login endpoint for Google/Apple Sign-In
    Creates user if doesn't exist, returns access token
    """
    provider = payload.get('provider')  # 'google' or 'apple'
    email = payload.get('email')
    name = payload.get('name', '')
    photo_url = payload.get('photo_url')
    user_id = payload.get('user_id')  # For Apple

    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required for social login.",
        )

    # Check if user exists
    user = await get_user_by_email(email, session)

    if not user:
        # Create new user with social login
        # Generate a random secure password (user won't need it for social login)
        import secrets
        random_password = secrets.token_urlsafe(32)
        hashed_password = get_password_hash(random_password)

        user = User(
            email=email,
            hashed_password=hashed_password,
            full_name=name or email.split('@')[0],
            # Set defaults for required fields
            gender=None,
            age=None,
            height_cm=None,
            weight_kg=None,
            activity_level=None,
            goal=None,
        )

        session.add(user)
        await session.commit()
        await session.refresh(user)

    # Generate access token
    access_token_expires = timedelta(minutes=60 * 24 * 7)
    access_token = create_access_token(
        data={"sub": str(user.id)},
        expires_delta=access_token_expires,
    )

    return Token(access_token=access_token)


@app.get("/auth/me", response_model=UserRead)
async def read_current_user_auth(current_user: User = Depends(get_current_user)):
    return current_user


@app.post("/auth/forgot-password")
async def forgot_password(
    payload: dict,
    session: AsyncSession = Depends(get_session),
):
    """
    Send password reset link (simulation)
    In production: you'll need to send an actual email
    """
    email = payload.get('email')
    if not email:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email is required.",
        )
    
    # Check if user exists
    user = await get_user_by_email(email, session)
    if not user:
        # For security reasons, return success even if user doesn't exist
        return {"success": True, "message": "If the email is registered, you will receive a reset link."}
    
    # In production: send an email with a reset link containing a token
    # Later: use SendGrid or AWS SES or SMTP
    
    return {
        "success": True,
        "message": "Password reset link has been sent to your email.",
    }


# ------------- User / Profile --------------


@app.get("/users/me", response_model=UserRead)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@app.put("/users/me", response_model=UserRead)
async def update_me(
    payload: UserUpdate,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    data = payload.model_dump(exclude_unset=True)

    for field, value in data.items():
        setattr(current_user, field, value)

    session.add(current_user)
    await session.commit()
    await session.refresh(current_user)

    return current_user


# ------------- Body Analysis --------------


@app.post("/analysis/body")
async def analyze_body_image(
    file: UploadFile = File(...),
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_optional_user),
):
    try:
        time.sleep(1.2)

        img = _open_image(file)
        w, h = img.size
        aspect_ratio = round(h / w, 3) if w > 0 else 1.0

        upper = img.crop((0, 0, w, h // 2))
        pixels = list(upper.getdata())
        luminances = [sum(p) / 3 for p in pixels]
        avg_lum = statistics.mean(luminances)

        relative_lum = max(0.0, min(1.0, (avg_lum - 80) / (210 - 80)))

        fat_percent = 12 + relative_lum * 16
        muscle_percent = 30 + (1 - relative_lum) * 20
        bmi = 20 + (fat_percent - 12) * (10 / 16)

        if fat_percent <= 13.5:
            body_shape = "Very Athletic"
        elif fat_percent <= 17:
            body_shape = "Athletic"
        elif fat_percent <= 22:
            body_shape = "Balanced"
        elif fat_percent <= 26:
            body_shape = "Full"
        else:
            body_shape = "High Fat"

        if body_shape.startswith("Athletic"):
            advice = (
                "Your body shows good athletic levels. "
                "Continue with the same exercise pattern with attention to sleep and hydration."
            )
        elif body_shape == "Balanced":
            advice = (
                "Your body proportions are approximately balanced. Maintain a regular training program "
                "with a balanced diet to improve results further."
            )
        elif body_shape == "Full":
            advice = (
                "It looks like you have a medium fat percentage. Try reducing calories slightly, "
                "and increase movement and cardio exercises alongside resistance training."
            )
        else:
            advice = (
                "Indicators suggest a relatively high fat percentage. "
                "Focus on reducing sugars and processed fats with daily walking "
                "will make a noticeable difference over time."
            )

        saved = False
        if current_user is not None:
            analysis = BodyAnalysis(
                user_id=current_user.id,
                shape=body_shape,
                body_fat=round(fat_percent, 1),
                muscle_mass=round(muscle_percent, 1),
                bmi=round(bmi, 1),
                aspect_ratio=aspect_ratio,
            )
            session.add(analysis)
            await session.commit()
            saved = True

        return {
            "success": True,
            "shape": body_shape,
            "body_fat": round(fat_percent, 1),
            "muscle_mass": round(muscle_percent, 1),
            "bmi": round(bmi, 1),
            "aspect_ratio": aspect_ratio,
            "advice": advice,
            "saved": saved,
        }

    except Exception as e:
        return JSONResponse(
            {"success": False, "message": f"Error analyzing body: {e}"},
            status_code=500,
        )


# ------------- Food Analysis --------------


@app.post("/analysis/food")
async def analyze_food_image(
    file: UploadFile = File(...),
    session: AsyncSession = Depends(get_session),
    current_user: Optional[User] = Depends(get_optional_user),
):
    try:
        time.sleep(1.4)

        img = _open_image(file)
        pixels = list(img.getdata())

        reds = [p[0] for p in pixels]
        greens = [p[1] for p in pixels]
        blues = [p[2] for p in pixels]

        avg_r = statistics.mean(reds)
        avg_g = statistics.mean(greens)
        avg_b = statistics.mean(blues)
        avg_brightness = (avg_r + avg_g + avg_b) / 3

        yellow_level = ((avg_r + avg_g) / 2) - avg_b
        green_level = avg_g - max(avg_r, avg_b)

        yellow_score = max(0.0, min(1.0, (yellow_level - 0) / 90))
        green_score = max(0.0, min(1.0, (green_level + 20) / 140))
        brightness_norm = max(0.0, min(1.0, (avg_brightness - 60) / 210))

        is_high_cal = yellow_score >= 0.3 and brightness_norm > 0.25
        is_light = green_score >= 0.55 and yellow_score < 0.2

        if is_high_cal and not is_light:
            meal_name = "High-calorie meal"
            calories = 800
            protein = 30
            carbs = 95
            fats = 40
            advice = (
                "This looks like a quick, calorie-rich meal. Try making it an occasional choice, "
                "balance it throughout the day with lighter snacks and more vegetables."
            )
        elif is_light and not is_high_cal:
            meal_name = "Relatively light meal"
            calories = 280
            protein = 10
            carbs = 30
            fats = 8
            advice = (
                "This meal looks relatively light. Make sure to get enough protein "
                "throughout the rest of the day to maintain muscle mass."
            )
        else:
            meal_name = "Moderate-calorie meal"
            calories = 550
            protein = 25
            carbs = 60
            fats = 18
            advice = (
                "This meal is moderate in terms of calories. Choosing healthy cooking methods "
                "and reducing processed sauces makes it a better choice in the long term."
            )

        saved = False
        if current_user is not None:
            analysis = FoodAnalysis(
                user_id=current_user.id,
                meal_name=meal_name,
                calories=calories,
                protein=protein,
                carbs=carbs,
                fats=fats,
            )
            session.add(analysis)
            await session.commit()
            saved = True

        return {
            "success": True,
            "meal_name": meal_name,
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fats": fats,
            "advice": advice,
            "saved": saved,
        }

    except Exception as e:
        return JSONResponse(
            {"success": False, "message": f"Error analyzing meal: {e}"},
            status_code=500,
        )


# ------------- Analysis History -------------


@app.get("/analysis/body/history", response_model=List[BodyAnalysisItem])
async def get_body_history(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(BodyAnalysis)
        .where(BodyAnalysis.user_id == current_user.id)
        .order_by(BodyAnalysis.created_at.desc())
        .limit(100)
    )
    result = await session.execute(stmt)
    items = result.scalars().all()
    return items


@app.get("/analysis/food/history", response_model=List[FoodAnalysisItem])
async def get_food_history(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(FoodAnalysis)
        .where(FoodAnalysis.user_id == current_user.id)
        .order_by(FoodAnalysis.created_at.desc())
        .limit(100)
    )
    result = await session.execute(stmt)
    items = result.scalars().all()
    return items


# ------------- Premium Subscription (Server Only) -------------


@app.get("/subscriptions/me", response_model=SubscriptionStatus)
async def get_my_subscription(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(Subscription)
        .where(Subscription.user_id == current_user.id)
        .order_by(Subscription.created_at.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    sub = result.scalar_one_or_none()

    if not sub:
        return SubscriptionStatus(is_active=False, plan=None, provider=None)

    return SubscriptionStatus(
        is_active=sub.is_active,
        plan=sub.plan,
        provider=sub.provider,
    )


@app.post("/subscriptions/activate-test", response_model=SubscriptionStatus)
async def activate_test_subscription(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    # Simplified: Create a new Test Premium subscription on every call
    sub = Subscription(
        user_id=current_user.id,
        is_active=True,
        plan="premium",
        provider="test",
    )
    session.add(sub)
    await session.commit()
    await session.refresh(sub)

    return SubscriptionStatus(
        is_active=sub.is_active,
        plan=sub.plan,
        provider=sub.provider,
    )


@app.post("/plans/workout", response_model=WorkoutPlanRead)
async def save_workout_plan(
    payload: WorkoutPlanCreate,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(WorkoutPlan)
        .where(WorkoutPlan.user_id == current_user.id, WorkoutPlan.active == True)
        .order_by(WorkoutPlan.created_at.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    prev = result.scalar_one_or_none()
    if prev:
        prev.active = False
        session.add(prev)

    plan = WorkoutPlan(
        user_id=current_user.id,
        duration_weeks=payload.duration_weeks,
        focus=payload.focus,
        active=True,
    )
    session.add(plan)
    await session.commit()
    await session.refresh(plan)
    return plan


@app.get("/plans/workout/current", response_model=WorkoutPlanRead)
async def get_current_workout_plan(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(WorkoutPlan)
        .where(WorkoutPlan.user_id == current_user.id, WorkoutPlan.active == True)
        .order_by(WorkoutPlan.created_at.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="No active workout plan")
    return plan


@app.post("/plans/meal", response_model=MealPlanRead)
async def save_meal_plan(
    payload: MealPlanCreate,
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(MealPlan)
        .where(MealPlan.user_id == current_user.id, MealPlan.active == True)
        .order_by(MealPlan.created_at.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    prev = result.scalar_one_or_none()
    if prev:
        prev.active = False
        session.add(prev)

    plan = MealPlan(
        user_id=current_user.id,
        calories_target=payload.calories_target,
        protein=payload.protein,
        carbs=payload.carbs,
        fats=payload.fats,
        active=True,
    )
    session.add(plan)
    await session.commit()
    await session.refresh(plan)
    return plan


@app.get("/plans/meal/current", response_model=MealPlanRead)
async def get_current_meal_plan(
    session: AsyncSession = Depends(get_session),
    current_user: User = Depends(get_current_user),
):
    stmt = (
        select(MealPlan)
        .where(MealPlan.user_id == current_user.id, MealPlan.active == True)
        .order_by(MealPlan.created_at.desc())
        .limit(1)
    )
    result = await session.execute(stmt)
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="No active meal plan")
    return plan


@app.get("/")
async def root():
    return {"message": "BodyTalk AI server is running"}

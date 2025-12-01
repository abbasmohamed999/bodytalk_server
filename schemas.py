# schemas.py

from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, EmailStr, ConfigDict


# ===== نماذج المستخدم =====

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    activity_level: Optional[str] = None
    goal: Optional[str] = None


class UserCreate(UserBase):
    password: str


class UserRead(UserBase):
    id: int
    created_at: Optional[datetime] = None

    # ضروري مع SQLAlchemy
    model_config = ConfigDict(from_attributes=True)


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    gender: Optional[str] = None
    age: Optional[int] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    activity_level: Optional[str] = None
    goal: Optional[str] = None


# ===== نموذج التوكن (JWT) =====

class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


# ===== نماذج التاريخ (History) =====

class BodyAnalysisItem(BaseModel):
    id: int
    created_at: datetime
    shape: str
    body_fat: float
    muscle_mass: float
    bmi: float
    aspect_ratio: float

    model_config = ConfigDict(from_attributes=True)


class FoodAnalysisItem(BaseModel):
    id: int
    created_at: datetime
    meal_name: str
    calories: float
    protein: float
    carbs: float
    fats: float

    model_config = ConfigDict(from_attributes=True)


# ===== الاشتراك =====

class SubscriptionStatus(BaseModel):
    is_active: bool
    plan: Optional[str] = None
    provider: Optional[str] = None


class WorkoutPlanCreate(BaseModel):
    duration_weeks: int
    focus: str


class WorkoutPlanRead(BaseModel):
    id: int
    created_at: datetime
    duration_weeks: int
    focus: str
    active: bool

    model_config = ConfigDict(from_attributes=True)


class MealPlanCreate(BaseModel):
    calories_target: float
    protein: float
    carbs: float
    fats: float


class MealPlanRead(BaseModel):
    id: int
    created_at: datetime
    calories_target: float
    protein: float
    carbs: float
    fats: float
    active: bool

    model_config = ConfigDict(from_attributes=True)

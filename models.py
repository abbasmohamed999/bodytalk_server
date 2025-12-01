# models.py
from datetime import datetime
from sqlalchemy import (
    Column,
    Integer,
    String,
    DateTime,
    Float,
    Boolean,
    ForeignKey,
)
from sqlalchemy.orm import relationship

from db import Base


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)

    # بيانات تسجيل الدخول
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)

    # بيانات عامة
    full_name = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    # ✅ بيانات الجسم / اللياقة
    gender = Column(String(20), nullable=True)          # male / female / other / عربي
    age = Column(Integer, nullable=True)                # العمر
    height_cm = Column(Float, nullable=True)            # الطول بالسنتيمتر
    weight_kg = Column(Float, nullable=True)            # الوزن بالكيلو
    activity_level = Column(String(50), nullable=True)  # low / medium / high
    goal = Column(String(50), nullable=True)            # lose / gain / maintain

    # العلاقات مع الجداول الأخرى
    body_analyses = relationship("BodyAnalysis", back_populates="user")
    food_analyses = relationship("FoodAnalysis", back_populates="user")
    subscriptions = relationship("Subscription", back_populates="user")
    workout_plans = relationship("WorkoutPlan", back_populates="user")
    meal_plans = relationship("MealPlan", back_populates="user")


class BodyAnalysis(Base):
    __tablename__ = "body_analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    shape = Column(String(100))
    body_fat = Column(Float)
    muscle_mass = Column(Float)
    bmi = Column(Float)
    aspect_ratio = Column(Float)

    user = relationship("User", back_populates="body_analyses")


class FoodAnalysis(Base):
    __tablename__ = "food_analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    meal_name = Column(String(255))
    calories = Column(Float)
    protein = Column(Float)
    carbs = Column(Float)
    fats = Column(Float)

    user = relationship("User", back_populates="food_analyses")


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    is_active = Column(Boolean, default=False)
    plan = Column(String(50), nullable=True)      # example: monthly / yearly / premium
    provider = Column(String(50), nullable=True)  # apple / google / stripe / test
    external_id = Column(String(255), nullable=True)  # ID from store

    user = relationship("User", back_populates="subscriptions")


class WorkoutPlan(Base):
    __tablename__ = "workout_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    duration_weeks = Column(Integer, nullable=False)
    focus = Column(String(100), nullable=False)
    active = Column(Boolean, default=True)

    user = relationship("User", back_populates="workout_plans")


class MealPlan(Base):
    __tablename__ = "meal_plans"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    calories_target = Column(Float, nullable=False)
    protein = Column(Float, nullable=False)
    carbs = Column(Float, nullable=False)
    fats = Column(Float, nullable=False)
    active = Column(Boolean, default=True)

    user = relationship("User", back_populates="meal_plans")

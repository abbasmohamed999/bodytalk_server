# db.py
import os
from typing import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import declarative_base

# يقرأ DATABASE_URL من متغير البيئة
# مثال:
# postgresql+asyncpg://bodytalk_user:strong_password_here@localhost:5432/bodytalk_db
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql+asyncpg://bodytalk_user:Abbas%40999@localhost:5432/bodytalk_db",
)

# تحويل postgresql:// إلى postgresql+asyncpg:// (من أجل Render)
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+asyncpg://", 1)



engine = create_async_engine(
    DATABASE_URL,
    echo=False,      # خليها True لو حاب تشوف SQL في التيرمنال
    future=True,
)

AsyncSessionLocal = async_sessionmaker(
    engine,
    expire_on_commit=False,
    class_=AsyncSession,
)


Base = declarative_base()


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """Dependency لـ FastAPI ترجع جلسة DB غير متزامنة."""
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

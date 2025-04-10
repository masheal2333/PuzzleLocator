from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.api import users, puzzles, algorithms

app = FastAPI(
    title=settings.PROJECT_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# 配置CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # 生产环境需要限制
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 注册路由
app.include_router(users.router, prefix=settings.API_V1_STR)
app.include_router(puzzles.router, prefix=settings.API_V1_STR)
app.include_router(algorithms.router, prefix=settings.API_V1_STR)

@app.get("/")
async def root():
    return {"message": "Welcome to PuzzleLocator API"}

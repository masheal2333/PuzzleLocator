from fastapi import APIRouter, HTTPException, Depends
from typing import List
from app.utils.cache import cache_manager
from app.utils.mock_data import generate_user_data, generate_history_data
from datetime import datetime

router = APIRouter()

@router.post("/register")
async def register_user(username: str, email: str):
    # 生成新用户数据
    users = cache_manager.get("users") or []
    new_user = {
        "id": f"user_{len(users) + 1}",
        "username": username,
        "email": email,
        "created_at": datetime.now().isoformat(),
        "last_login": datetime.now().isoformat()
    }
    users.append(new_user)
    cache_manager.set("users", users)
    return new_user

@router.get("/{user_id}")
async def get_user(user_id: str):
    users = cache_manager.get("users") or []
    user = next((u for u in users if u["id"] == user_id), None)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@router.get("/{user_id}/history")
async def get_user_history(user_id: str):
    history = cache_manager.get(f"history_{user_id}")
    if not history:
        # 生成模拟历史数据
        history = generate_history_data(user_id)
        cache_manager.set(f"history_{user_id}", history)
    return history

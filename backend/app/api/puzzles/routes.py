from fastapi import APIRouter, HTTPException, UploadFile, File
from typing import List
from app.utils.cache import cache_manager
from app.utils.mock_data import generate_puzzle_data, generate_match_result
from datetime import datetime

router = APIRouter()

@router.post("/upload")
async def upload_puzzle(
    name: str = None,
    description: str = None,
    file: UploadFile = File(...)
):
    # 在实际应用中，这里应该处理文件上传
    # 现在我们只是模拟这个过程
    puzzles = cache_manager.get("puzzles") or []
    new_puzzle = {
        "id": f"puzzle_{len(puzzles) + 1}",
        "name": name or f"Puzzle {len(puzzles) + 1}",
        "description": description or f"Description for puzzle {len(puzzles) + 1}",
        "created_at": datetime.now().isoformat(),
        "size": {
            "width": 1000,  # 模拟尺寸
            "height": 1000
        },
        "pieces_count": 500  # 模拟拼图块数
    }
    puzzles.append(new_puzzle)
    cache_manager.set("puzzles", puzzles)
    return new_puzzle

@router.post("/match")
async def match_puzzle(
    puzzle_id: str,
    user_id: str,
    piece_image: UploadFile = File(...)
):
    # 在实际应用中，这里应该调用匹配算法
    # 现在我们只是返回模拟结果
    match_result = generate_match_result(puzzle_id, user_id)
    
    # 保存匹配结果
    results = cache_manager.get(f"results_{user_id}") or []
    results.append(match_result)
    cache_manager.set(f"results_{user_id}", results)
    
    return match_result

@router.get("/{puzzle_id}")
async def get_puzzle(puzzle_id: str):
    puzzles = cache_manager.get("puzzles") or []
    puzzle = next((p for p in puzzles if p["id"] == puzzle_id), None)
    if not puzzle:
        raise HTTPException(status_code=404, detail="Puzzle not found")
    return puzzle

@router.get("/{puzzle_id}/results")
async def get_puzzle_results(puzzle_id: str, user_id: str):
    results = cache_manager.get(f"results_{user_id}") or []
    puzzle_results = [r for r in results if r["puzzle_id"] == puzzle_id]
    return puzzle_results

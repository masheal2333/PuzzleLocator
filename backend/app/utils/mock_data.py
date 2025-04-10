import random
import string
from typing import List, Dict, Any
from datetime import datetime, timedelta

def generate_random_string(length: int = 8) -> str:
    return ''.join(random.choices(string.ascii_letters + string.digits, k=length))

def generate_user_data(count: int = 10) -> List[Dict[str, Any]]:
    users = []
    for i in range(count):
        user = {
            "id": f"user_{i+1}",
            "username": f"user_{generate_random_string(6)}",
            "email": f"user_{i+1}@example.com",
            "created_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
            "last_login": (datetime.now() - timedelta(hours=random.randint(1, 24))).isoformat()
        }
        users.append(user)
    return users

def generate_puzzle_data(count: int = 20) -> List[Dict[str, Any]]:
    puzzles = []
    for i in range(count):
        puzzle = {
            "id": f"puzzle_{i+1}",
            "name": f"Puzzle {i+1}",
            "description": f"Description for puzzle {i+1}",
            "created_at": (datetime.now() - timedelta(days=random.randint(1, 30))).isoformat(),
            "size": {
                "width": random.randint(500, 2000),
                "height": random.randint(500, 2000)
            },
            "pieces_count": random.randint(100, 1000)
        }
        puzzles.append(puzzle)
    return puzzles

def generate_match_result(puzzle_id: str, user_id: str) -> Dict[str, Any]:
    return {
        "id": f"match_{generate_random_string(8)}",
        "puzzle_id": puzzle_id,
        "user_id": user_id,
        "timestamp": datetime.now().isoformat(),
        "confidence": round(random.uniform(0.6, 0.95), 2),
        "position": {
            "x": round(random.uniform(0.1, 0.9), 2),
            "y": round(random.uniform(0.1, 0.9), 2)
        },
        "rotation": random.randint(-15, 15),
        "highlight_rect": {
            "x": round(random.uniform(0.1, 0.9), 2),
            "y": round(random.uniform(0.1, 0.9), 2),
            "width": round(random.uniform(0.1, 0.3), 2),
            "height": round(random.uniform(0.1, 0.3), 2)
        }
    }

def generate_history_data(user_id: str, count: int = 5) -> List[Dict[str, Any]]:
    history = []
    for i in range(count):
        puzzle_id = f"puzzle_{random.randint(1, 20)}"
        match_result = generate_match_result(puzzle_id, user_id)
        history.append({
            "id": f"history_{generate_random_string(8)}",
            "user_id": user_id,
            "puzzle_id": puzzle_id,
            "match_result": match_result,
            "timestamp": (datetime.now() - timedelta(days=i)).isoformat()
        })
    return history

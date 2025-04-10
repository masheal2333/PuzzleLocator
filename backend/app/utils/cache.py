import os
import json
import time
from typing import Any, Dict, Optional
from pathlib import Path
from app.core.config import settings

class CacheManager:
    def __init__(self):
        self.cache_dir = Path(settings.CACHE_DIR)
        self.cache_dir.mkdir(exist_ok=True)
        self.cache_index: Dict[str, Dict[str, Any]] = {}
        self._load_index()

    def _load_index(self):
        index_file = self.cache_dir / "index.json"
        if index_file.exists():
            with open(index_file, "r") as f:
                self.cache_index = json.load(f)

    def _save_index(self):
        index_file = self.cache_dir / "index.json"
        with open(index_file, "w") as f:
            json.dump(self.cache_index, f)

    def get(self, key: str) -> Optional[Any]:
        if key not in self.cache_index:
            return None
        
        cache_info = self.cache_index[key]
        if time.time() > cache_info["expires_at"]:
            self.delete(key)
            return None
        
        cache_file = self.cache_dir / f"{key}.json"
        if not cache_file.exists():
            return None
        
        with open(cache_file, "r") as f:
            return json.load(f)

    def set(self, key: str, value: Any, ttl: int = 3600):
        cache_file = self.cache_dir / f"{key}.json"
        with open(cache_file, "w") as f:
            json.dump(value, f)
        
        self.cache_index[key] = {
            "expires_at": time.time() + ttl,
            "created_at": time.time()
        }
        
        # 清理过期缓存
        self._cleanup()
        self._save_index()

    def delete(self, key: str):
        cache_file = self.cache_dir / f"{key}.json"
        if cache_file.exists():
            cache_file.unlink()
        if key in self.cache_index:
            del self.cache_index[key]
            self._save_index()

    def _cleanup(self):
        current_time = time.time()
        expired_keys = [
            key for key, info in self.cache_index.items()
            if current_time > info["expires_at"]
        ]
        
        for key in expired_keys:
            self.delete(key)
        
        # 如果缓存条目超过最大限制，删除最旧的
        if len(self.cache_index) > settings.MAX_CACHE_SIZE:
            sorted_items = sorted(
                self.cache_index.items(),
                key=lambda x: x[1]["created_at"]
            )
            for key, _ in sorted_items[:len(self.cache_index) - settings.MAX_CACHE_SIZE]:
                self.delete(key)

cache_manager = CacheManager()

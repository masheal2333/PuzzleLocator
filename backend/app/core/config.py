from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # API配置
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "PuzzleLocator API"
    
    # 安全配置
    SECRET_KEY: str = "your-secret-key-here"  # 生产环境需要修改
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # 缓存配置
    CACHE_DIR: str = "cache"
    MAX_CACHE_SIZE: int = 100  # 最大缓存条目数
    
    class Config:
        case_sensitive = True

settings = Settings()

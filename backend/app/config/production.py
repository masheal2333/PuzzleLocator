from app.config.base import BaseConfig

class ProductionConfig(BaseConfig):
    DEBUG = False
    TESTING = False
    
    # 数据库配置
    DATABASE_URL = "postgresql://user:password@localhost:5432/puzzlelocator"
    
    # 缓存配置
    CACHE_TYPE = "redis"
    CACHE_REDIS_URL = "redis://localhost:6379/0"
    
    # 安全配置
    SECRET_KEY = "your-production-secret-key"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # 文件存储配置
    UPLOAD_FOLDER = "/var/www/puzzlelocator/uploads"
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    
    # 日志配置
    LOG_LEVEL = "INFO"
    LOG_FILE = "/var/log/puzzlelocator/app.log"
    
    # 监控配置
    ENABLE_METRICS = True
    PROMETHEUS_MULTIPROC_DIR = "/tmp/puzzlelocator" 
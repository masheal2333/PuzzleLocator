# PuzzleLocator Backend

这是PuzzleLocator应用的后端服务，使用FastAPI框架实现。

## 功能特性

- 用户管理
- 拼图上传和匹配
- 图像处理和特征提取
- 本地缓存支持
- Mock数据生成

## 安装

1. 创建虚拟环境：
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# 或
.\venv\Scripts\activate  # Windows
```

2. 安装依赖：
```bash
pip install -r requirements.txt
```

## 运行

启动开发服务器：
```bash
uvicorn app.main:app --reload
```

API文档将在以下地址可用：
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 项目结构

```
backend/
├── app/
│   ├── api/
│   │   ├── users/
│   │   ├── puzzles/
│   │   └── algorithms/
│   ├── core/
│   ├── models/
│   └── utils/
├── tests/
└── docs/
```

## API端点

### 用户模块
- POST /api/v1/register - 用户注册
- GET /api/v1/{user_id} - 获取用户信息
- GET /api/v1/{user_id}/history - 获取用户历史记录

### 拼图模块
- POST /api/v1/upload - 上传拼图
- POST /api/v1/match - 匹配拼图
- GET /api/v1/{puzzle_id} - 获取拼图信息
- GET /api/v1/{puzzle_id}/results - 获取拼图匹配结果

### 算法模块
- POST /api/v1/process-image - 图像处理
- POST /api/v1/match - 图像匹配
- POST /api/v1/optimize - 结果优化

## 开发说明

- 使用本地缓存存储数据
- 提供mock数据生成功能
- 支持文件上传和处理
- 包含基本的错误处理

## 测试

运行测试：
```bash
pytest
``` 
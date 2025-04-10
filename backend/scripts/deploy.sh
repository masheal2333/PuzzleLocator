#!/bin/bash

# 设置错误时退出
set -e

# 创建必要的目录
mkdir -p /var/www/puzzlelocator/uploads
mkdir -p /var/log/puzzlelocator
mkdir -p /tmp/puzzlelocator

# 安装系统依赖
apt-get update
apt-get install -y python3-pip python3-venv nginx redis-server postgresql

# 创建虚拟环境
python3 -m venv /var/www/puzzlelocator/venv
source /var/www/puzzlelocator/venv/bin/activate

# 安装Python依赖
pip install -r requirements.txt
pip install gunicorn

# 配置Nginx
cp nginx.conf /etc/nginx/sites-available/puzzlelocator
ln -s /etc/nginx/sites-available/puzzlelocator /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx

# 配置PostgreSQL
sudo -u postgres psql -c "CREATE DATABASE puzzlelocator;"
sudo -u postgres psql -c "CREATE USER puzzlelocator WITH PASSWORD 'your-password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE puzzlelocator TO puzzlelocator;"

# 配置Redis
sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
systemctl restart redis

# 配置Gunicorn
cp gunicorn.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

# 设置权限
chown -R www-data:www-data /var/www/puzzlelocator
chown -R www-data:www-data /var/log/puzzlelocator
chown -R www-data:www-data /tmp/puzzlelocator 
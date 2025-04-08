// 自然拟态风格JavaScript功能

document.addEventListener('DOMContentLoaded', function() {
    // 获取当前时间并更新状态栏
    updateStatusBarTime();
    setInterval(updateStatusBarTime, 60000); // 每分钟更新一次
    
    // 设置电池电量显示
    updateBatteryStatus();
    
    // 灵动岛交互效果
    setupDynamicIslandInteraction();
    
    // 添加自然元素动画
    addNatureElements();
    
    // 添加波纹效果到按钮
    addRippleEffects();
    
    // 添加触感反馈
    addHapticFeedback();
});

// 更新状态栏时间
function updateStatusBarTime() {
    const timeElements = document.querySelectorAll('.status-bar .time');
    if (timeElements.length === 0) return;
    
    const now = new Date();
    const hours = now.getHours();
    const minutes = now.getMinutes().toString().padStart(2, '0');
    const timeString = `${hours}:${minutes}`;
    
    timeElements.forEach(el => {
        el.textContent = timeString;
    });
}

// 更新电池状态
function updateBatteryStatus() {
    const batteryIcons = document.querySelectorAll('.status-bar .fa-battery-full');
    
    // 模拟随机电池电量
    const batteryLevel = Math.floor(Math.random() * 100) + 1;
    
    batteryIcons.forEach(icon => {
        // 根据电池电量更改图标
        icon.className = icon.className.replace(/fa-battery[^\s]+/g, '');
        
        if (batteryLevel <= 10) {
            icon.classList.add('fa-battery-empty');
            icon.style.color = '#963e3e'; // 低电量红色
        } else if (batteryLevel <= 20) {
            icon.classList.add('fa-battery-quarter');
            icon.style.color = '#a6853e'; // 低电量橙色
        } else if (batteryLevel <= 50) {
            icon.classList.add('fa-battery-half');
            icon.style.color = '';
        } else if (batteryLevel <= 80) {
            icon.classList.add('fa-battery-three-quarters');
            icon.style.color = '';
        } else {
            icon.classList.add('fa-battery-full');
            icon.style.color = '';
        }
    });
}

// 灵动岛交互效果
function setupDynamicIslandInteraction() {
    const dynamicIslands = document.querySelectorAll('.dynamic-island');
    
    dynamicIslands.forEach(island => {
        island.addEventListener('click', function() {
            this.classList.add('active');
            
            // 模拟内容变化
            const notificationContent = document.createElement('div');
            notificationContent.className = 'island-notification';
            notificationContent.style.opacity = '0';
            notificationContent.style.transition = 'opacity 0.3s';
            
            // 随机选择通知内容
            const notifications = [
                '新消息',
                '正在播放音乐',
                '导航中',
                '录音中'
            ];
            const randomNotification = notifications[Math.floor(Math.random() * notifications.length)];
            notificationContent.textContent = randomNotification;
            
            // 先清除可能存在的旧内容
            while (this.firstChild) {
                this.removeChild(this.firstChild);
            }
            
            this.appendChild(notificationContent);
            
            // 显示动画
            setTimeout(() => {
                notificationContent.style.opacity = '1';
            }, 300);
            
            // 一段时间后恢复
            setTimeout(() => {
                notificationContent.style.opacity = '0';
                setTimeout(() => {
                    this.classList.remove('active');
                    this.innerHTML = '';
                }, 300);
            }, 3000);
        });
    });
}

// 添加自然元素装饰
function addNatureElements() {
    const screenElements = document.querySelectorAll('.screen');
    
    screenElements.forEach(screen => {
        // 添加叶子元素
        for (let i = 0; i < 5; i++) {
            const leaf = document.createElement('div');
            leaf.className = 'nature-leaf';
            
            // 随机位置
            const randomX = Math.floor(Math.random() * 80) + 10; // 10% 到 90%
            const randomY = Math.floor(Math.random() * 80) + 10;
            
            leaf.style.top = `${randomY}%`;
            leaf.style.left = `${randomX}%`;
            
            // 随机旋转
            const randomRotate = Math.floor(Math.random() * 360);
            leaf.style.transform = `rotate(${randomRotate}deg)`;
            
            screen.appendChild(leaf);
        }
        
        // 添加有机波浪
        const waves = document.createElement('div');
        waves.className = 'organic-waves';
        screen.appendChild(waves);
    });
}

// 添加波纹效果到按钮
function addRippleEffects() {
    const buttons = document.querySelectorAll('.neumorphic-button, button');
    
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            // 创建波纹元素
            const ripple = document.createElement('span');
            ripple.className = 'ripple-effect';
            
            // 设置波纹位置
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.width = ripple.style.height = `${size}px`;
            ripple.style.left = `${x}px`;
            ripple.style.top = `${y}px`;
            
            // 添加到按钮
            this.appendChild(ripple);
            
            // 移除波纹
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });
}

// 添加触感反馈
function addHapticFeedback() {
    const interactiveElements = document.querySelectorAll('button, a, .feature-item, .photo-area');
    
    interactiveElements.forEach(element => {
        element.addEventListener('click', function() {
            // 模拟触感反馈
            if (window.navigator && window.navigator.vibrate) {
                navigator.vibrate(5); // 轻微振动5毫秒
            }
        });
    });
}

// 模拟系统通知
function simulateSystemNotification(title, message) {
    const dynamicIsland = document.querySelector('.dynamic-island');
    if (!dynamicIsland) return;
    
    dynamicIsland.classList.add('active');
    
    // 创建通知内容
    const notificationContent = document.createElement('div');
    notificationContent.className = 'island-notification';
    notificationContent.innerHTML = `
        <div style="font-size:12px;color:white;font-weight:bold;">${title}</div>
        <div style="font-size:10px;color:#f8f5f0;opacity:0.9;">${message}</div>
    `;
    notificationContent.style.opacity = '0';
    notificationContent.style.transition = 'opacity 0.3s';
    
    // 清除旧内容
    while (dynamicIsland.firstChild) {
        dynamicIsland.removeChild(dynamicIsland.firstChild);
    }
    
    dynamicIsland.appendChild(notificationContent);
    
    // 显示动画
    setTimeout(() => {
        notificationContent.style.opacity = '1';
    }, 100);
    
    // 一段时间后恢复
    setTimeout(() => {
        notificationContent.style.opacity = '0';
        setTimeout(() => {
            dynamicIsland.classList.remove('active');
            dynamicIsland.innerHTML = '';
        }, 300);
    }, 4000);
}

// 添加波纹动画到页面中心
function addCenterRipple(element) {
    const container = document.createElement('div');
    container.className = 'ripple-container';
    container.style.position = 'absolute';
    container.style.top = '50%';
    container.style.left = '50%';
    container.style.transform = 'translate(-50%, -50%)';
    container.style.zIndex = '1';
    
    for (let i = 0; i < 3; i++) {
        const ripple = document.createElement('div');
        ripple.className = 'ripple';
        container.appendChild(ripple);
    }
    
    element.appendChild(container);
}

// 在点击位置创建波纹效果
function createRipple(element, x, y) {
    const ripple = document.createElement('span');
    ripple.className = 'ripple-effect';
    
    // 设置波纹大小和位置
    const size = Math.max(element.offsetWidth, element.offsetHeight) * 1.5;
    ripple.style.width = ripple.style.height = `${size}px`;
    ripple.style.left = `${x - size/2}px`;
    ripple.style.top = `${y - size/2}px`;
    
    // 设置波纹样式
    ripple.style.position = 'absolute';
    ripple.style.borderRadius = '50%';
    ripple.style.backgroundColor = 'rgba(141, 181, 128, 0.3)';
    ripple.style.transform = 'scale(0)';
    ripple.style.animation = 'ripple-animation 0.8s linear';
    ripple.style.pointerEvents = 'none';
    
    // 添加到元素
    element.appendChild(ripple);
    
    // 动画结束后移除
    setTimeout(() => {
        ripple.remove();
    }, 800);
}

// 导出供其他脚本使用
window.natureNeumorphic = {
    updateStatusBarTime,
    updateBatteryStatus,
    simulateSystemNotification,
    addCenterRipple,
    createRipple
}; 
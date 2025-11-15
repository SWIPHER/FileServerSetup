#!/bin/bash

set -e

# ===========================
# 配置参数
# ===========================
WEBDAV_DIR="/home/veronica"
DAV_USER="veronica"
DAV_PASS="Dage"
DAV_CONF="/etc/apache2/sites-available/webdav.conf"
DAV_PASSFILE="/etc/apache2/dav_password"

# ===========================
# 安装 Apache 和 WebDAV 模块
# ===========================
echo "=== 安装 Apache + WebDAV 模块 ==="
apt update
apt install -y apache2 apache2-utils

echo "=== 启用 WebDAV 模块 ==="
a2enmod dav_fs
a2enmod dav
a2enmod auth_digest

# ===========================
# 创建 WebDAV 用户密码文件
# ===========================
echo "=== 创建 WebDAV 用户密码文件 ==="
htdigest -c $DAV_PASSFILE "WebDAV" $DAV_USER <<EOF
$DAV_PASS
EOF

# ===========================
# 创建共享目录
# ===========================
echo "=== 创建共享目录并设置权限 ==="
mkdir -p $WEBDAV_DIR
chown -R www-data:www-data $WEBDAV_DIR
chmod -R 775 $WEBDAV_DIR

# ===========================
# 创建 Apache 配置文件（端口 8899）
# ===========================
echo "=== 创建 Apache 配置文件 ==="
cat > $DAV_CONF <<EOF
Listen 8899

<VirtualHost *:8899>
    ServerName webdav-server

    Alias /webdav $WEBDAV_DIR

    <Directory $WEBDAV_DIR>
        DAV On
        Options Indexes FollowSymLinks
        AllowOverride None

        AuthType Digest
        AuthName "WebDAV"
        AuthUserFile $DAV_PASSFILE
        Require valid-user

        # 允许 PUT/POST/DELETE/MKCOL 等写操作
        <LimitExcept GET OPTIONS>
            Require valid-user
        </LimitExcept>
    </Directory>
</VirtualHost>
EOF

# ===========================
# 启用站点并重启 Apache
# ===========================
echo "=== 启用站点并重启 Apache ==="
a2dissite 000-default || true
a2ensite webdav
systemctl reload apache2
systemctl restart apache2

# ===========================
# 开放防火墙端口（可选）
# ===========================
if command -v ufw &> /dev/null; then
    echo "=== 放行防火墙端口 8899 ==="
    ufw allow 8899/tcp
fi

echo ""
echo "=== WebDAV 安装完成 ==="
echo "访问地址：http://<你的Ubuntu_IP>:8899/webdav"
echo "用户名：$DAV_USER"
echo "密码：$DAV_PASS"
echo "共享目录 Apache 用户已设置 www-data，可上传文件，macOS 不会再出现 405 错误"

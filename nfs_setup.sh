#!/bin/bash

# =============================
# Ubuntu NFS Server Setup Script
# Share directory: /home/veronica
# =============================

SHARE_DIR="/home/veronica"

echo "=== 1. 安装 NFS 服务端 ==="
sudo apt update
sudo apt install -y nfs-kernel-server

echo "=== 2. 创建共享目录（如果不存在）==="
if [ ! -d "$SHARE_DIR" ]; then
    sudo mkdir -p "$SHARE_DIR"
    echo "-> 已创建目录 $SHARE_DIR"
else
    echo "-> 目录已存在：$SHARE_DIR"
fi

echo "=== 3. 设置共享目录权限 ==="
sudo chown -R nobody:nogroup "$SHARE_DIR"
sudo chmod -R 755 "$SHARE_DIR"

echo "=== 4. 配置 /etc/exports ==="
EXPORT_LINE="$SHARE_DIR *(rw,sync,no_subtree_check,no_root_squash)"

# 检查是否已存在
if grep -Fxq "$EXPORT_LINE" /etc/exports; then
    echo "-> /etc/exports 已存在配置，无需添加"
else
    echo "$EXPORT_LINE" | sudo tee -a /etc/exports > /dev/null
    echo "-> 已写入 /etc/exports"
fi

echo "=== 5. 重载 NFS 配置 ==="
sudo exportfs -arv

echo "=== 6. 重启 NFS 服务 ==="
sudo systemctl restart nfs-kernel-server

echo "=== 7. 检查防火墙 ==="
if command -v ufw &> /dev/null; then
    sudo ufw allow from any to any port nfs
    echo "-> 已放行 NFS (2049)"
else
    echo "-> 未安装 ufw，跳过。"
fi

echo ""
echo "============================="
echo "✔ NFS Server 安装完成"
echo "✔ 共享目录: $SHARE_DIR"
echo "✔ 客户端挂载示例："
echo "    sudo mount -t nfs <server-ip>:$SHARE_DIR /mnt"
echo "============================="

#!/usr/bin/env bash

set -euo pipefail

INSTALL_DIR="/usr/local/bin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FILES=(
    "niri-dms-session"
    "niri-noctalia-session"
)

echo "安装 Niri session 脚本..."
echo

# 检查安装目录
if [ ! -d "$INSTALL_DIR" ]; then
    echo "错误: $INSTALL_DIR 不存在"
    exit 1
fi


for file in "${FILES[@]}"; do

    SOURCE="$SCRIPT_DIR/$file"
    TARGET="$INSTALL_DIR/$file"

    echo "处理: $file"


    # 检查源文件
    if [ ! -f "$SOURCE" ]; then
        echo "找不到文件: $SOURCE"
        exit 1
    fi


    # 检查执行权限
    if [ ! -x "$SOURCE" ]; then
        echo "$file 没有执行权限，正在添加..."
        chmod +x "$SOURCE"
    fi


    echo "  -> $TARGET"


    if sudo ln -sfn "$SOURCE" "$TARGET"; then
        echo "安装成功"
    else
        echo "安装失败"
        exit 1
    fi


    # 验证链接
    if [ "$(readlink "$TARGET")" = "$SOURCE" ]; then
        echo "验证通过"
    else
        echo "验证失败"
        exit 1
    fi

    echo
done


echo "================================"
echo "Niri session 安装完成"
echo

echo "当前链接:"
for file in "${FILES[@]}"; do
    ls -l "$INSTALL_DIR/$file"
done

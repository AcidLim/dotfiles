#!/usr/bin/env bash

set -e

DOTFILES="$HOME/dotfiles"
CONFIG="$HOME/.config"

echo "🐱 Installing dotfiles..."

# 检查 dotfiles
if [ ! -d "$DOTFILES" ]; then
    echo "错误: 找不到 $DOTFILES"
    exit 1
fi

mkdir -p "$CONFIG"

configs=(
    "nvim"
    "niri"
    "kitty"
    "DankMaterialShell"
)

for name in "${configs[@]}"; do

    source="$DOTFILES/$name"
    target="$CONFIG/$name"

    echo ""
    echo "处理: $name"

    # dotfiles中不存在
    if [ ! -e "$source" ]; then
        echo "跳过: $source 不存在"
        continue
    fi


    # 已经是正确链接
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo "已存在正确链接，跳过"
        continue
    fi


    # 删除已有配置
    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "删除已有配置: $target"
        rm -rf "$target"
    fi


    # 创建软链接
    echo "创建链接:"
    echo "$target -> $source"

    ln -s "$source" "$target"

done


echo ""
echo "✅ Dotfiles 安装完成!"
echo ""

echo "当前状态:"
for name in "${configs[@]}"; do
    ls -ld "$CONFIG/$name" 2>/dev/null || true
done

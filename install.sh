#!/usr/bin/env bash
# ==============================================================================
#  dotfiles 安装脚本
#
#    ./install.sh            把 .config/* 与 .local/bin/* 逐项软链接到家目录
#    sudo ./install.sh --system
#                            额外把 bin/* 链接到 /usr/local/bin，
#                            并把 wayland-sessions/*.desktop 安装到
#                            /usr/share/wayland-sessions
#    ./install.sh --check    只校验链接状态，不做任何修改（有异常返回非 0）
#
#  约定：仓库结构镜像家目录
#    dotfiles/.config/  ->  ~/.config/
#    dotfiles/.local/bin/ ->  ~/.local/bin/
# ==============================================================================

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
LOCAL_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
SYSTEM_BIN="/usr/local/bin"
WAYLAND_SESSIONS="/usr/share/wayland-sessions"

MODE="install"
WITH_SYSTEM=0

usage() {
    sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^#\{0,1\} \{0,1\}//'
}

for arg in "$@"; do
    case "$arg" in
        --system) WITH_SYSTEM=1 ;;
        --check)  MODE="check" ;;
        -h|--help) usage; exit 0 ;;
        *) echo "未知参数: $arg" >&2; usage; exit 1 ;;
    esac
done

# 额外的手工链接：<目标文件名>:<仓库内相对路径>
EXTRA_LINKS=(
    "umbriel-screenshot:.config/umbriel/scripts/umbriel-screenshot"
)

FAILED=0

log()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*"; }
err()  { printf '  \033[31m✗\033[0m %s\n' "$*" >&2; }

# 原子地把 target 指向 src（先在同目录建临时链接，再 rename 覆盖）
link_item() {
    local src="$1" target="$2" tmp

    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        ok "$target"
        return 0
    fi

    mkdir -p "$(dirname "$target")"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local bak="$target.bak-$(date +%Y%m%d-%H%M%S)"
        warn "已有实体配置，备份为 $bak"
        mv -- "$target" "$bak"
    fi

    tmp="$(dirname "$target")/.$(basename "$target").dotfiles-tmp.$$"
    rm -f -- "$tmp"
    ln -s "$src" "$tmp"
    mv -Tf -- "$tmp" "$target"
    ok "$target -> $src"
}

# 校验 target 是否已正确指向 src
check_item() {
    local src="$1" target="$2"

    if [ -L "$target" ] && [ -e "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        ok "$target"
        return 0
    fi

    err "异常: $target"
    log "  期望: $target -> $src"
    log "  实际: ${target} -> $(readlink "$target" 2>/dev/null || echo '<非软链接>')"
    return 1
}

# 遍历一个仓库目录下的所有条目，逐项链接/校验到家目录
sync_tree() {
    local src_dir="$1" dst_dir="$2" entry name

    if [ ! -d "$src_dir" ]; then
        warn "跳过: $src_dir 不存在"
        return 0
    fi

    while IFS= read -r entry; do
        name="$(basename "$entry")"
        if [ "$MODE" = "check" ]; then
            check_item "$entry" "$dst_dir/$name" || FAILED=$((FAILED + 1))
        else
            link_item "$entry" "$dst_dir/$name"
        fi
    done < <(find "$src_dir" -mindepth 1 -maxdepth 1 | sort)
}

# 额外的手工链接
sync_extra() {
    local spec name rel src
    for spec in "${EXTRA_LINKS[@]}"; do
        name="${spec%%:*}"
        rel="${spec#*:}"
        src="$DOTFILES/$rel"
        [ -e "$src" ] || { warn "跳过: $src 不存在"; continue; }
        if [ "$MODE" = "check" ]; then
            check_item "$src" "$LOCAL_BIN/$name" || FAILED=$((FAILED + 1))
        else
            link_item "$src" "$LOCAL_BIN/$name"
        fi
    done
}

# 系统级部署（bin/ 与 wayland-sessions/ 不入库，仅本机存在时才处理）
sync_system() {
    local f name

    if [ "$MODE" = "check" ]; then
        log "（--check 模式不校验系统文件）"
        return 0
    fi

    if [ -d "$DOTFILES/bin" ]; then
        for f in "$DOTFILES"/bin/*; do
            [ -f "$f" ] || continue
            name="$(basename "$f")"
            case "$name" in
                install.sh|*.md) continue ;;
            esac
            sudo ln -sfn "$f" "$SYSTEM_BIN/$name"
            ok "$SYSTEM_BIN/$name -> $f"
        done
    else
        warn "跳过: $DOTFILES/bin 不存在"
    fi

    if [ -d "$DOTFILES/wayland-sessions" ]; then
        sudo install -Dm644 "$DOTFILES"/wayland-sessions/*.desktop -t "$WAYLAND_SESSIONS"
        ok "*.desktop -> $WAYLAND_SESSIONS/"
    else
        warn "跳过: $DOTFILES/wayland-sessions 不存在"
    fi
}

echo "dotfiles: $DOTFILES"
[ "$MODE" = "check" ] && echo "模式: 只校验"

# cava 的配色主题由 matugen 生成（模板 templates/cava-colors.ini → themes/your-theme），
# 新机器首次部署时该文件还不存在，cava 会因 “Unable to open theme file” 直接退出，
# 所以先用仓库里的 tricolor 兜底；matugen 跑过一次后会被壁纸配色覆盖。
seed_cava_theme() {
    local theme="$CONFIG_DIR/cava/themes/your-theme"
    local fallback="$DOTFILES/.config/cava/themes/tricolor"

    [ -d "$CONFIG_DIR/cava" ] || return 0
    [ -e "$theme" ] && return 0

    if [ "$MODE" = "check" ]; then
        warn "cava 主题尚未生成: $theme（matugen 还没跑过）"
        return 0
    fi

    [ -f "$fallback" ] || { warn "跳过: $fallback 不存在"; return 0; }
    cp -- "$fallback" "$theme"
    warn "cava 主题缺失，暂用 tricolor 兜底: $theme"
}

echo
echo "==> ~/.config"
sync_tree "$DOTFILES/.config" "$CONFIG_DIR"
seed_cava_theme

echo
echo "==> ~/.local/bin"
sync_tree "$DOTFILES/.local/bin" "$LOCAL_BIN"
sync_extra

if [ "$WITH_SYSTEM" = "1" ]; then
    echo
    echo "==> 系统文件（需要 sudo）"
    sync_system
fi

echo
if [ "$FAILED" -gt 0 ]; then
    err "校验未通过：$FAILED 项异常"
    exit 1
fi
if [ "$MODE" = "check" ]; then
    ok "全部链接正常"
else
    ok "部署完成"
fi

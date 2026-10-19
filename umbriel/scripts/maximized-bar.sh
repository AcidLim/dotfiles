#!/usr/bin/env bash

set -u

BAR_NAME="top_main"
LAST_STATE=""

log() {
    printf '[maximize-bar] %s\n' "$*"
}

update_bar() {
    local windows_json
    local active_window
    local window_title
    local maximized
    local new_state

    windows_json=$(umbriel windows --json) || {
        log "获取窗口失败"
        return
    }

    # 当前聚焦窗口
    active_window=$(
        jq -c '
            .[]
            | select(.active == true)
        ' <<< "$windows_json" | head -n 1
    )

    if [[ -z "$active_window" ]]; then
        log "无法确定当前聚焦窗口，保持当前状态"
        return
    fi

    maximized=$(jq -r '.maximized // false' <<< "$active_window")
    window_title=$(jq -r '.title // .app_id // "unknown"' <<< "$active_window")

    if [[ "$maximized" == "true" ]]; then
        new_state="SMART"
    else
        new_state="NORMAL"
    fi

    # 状态没有变化
    if [[ "$new_state" == "$LAST_STATE" ]]; then
        return
    fi

    log "当前窗口: $window_title"
    log "最大化: $maximized"

    if [[ "$new_state" == "SMART" ]]; then
        if noctalia msg bar-auto-hide-set smart "$BAR_NAME"; then
            LAST_STATE="SMART"
            log "已启用 Smart Auto Hide: $BAR_NAME"
        else
            log "启用 Smart Auto Hide 失败"
        fi
    else
        if noctalia msg bar-auto-hide-set off "$BAR_NAME"; then
            LAST_STATE="NORMAL"
            log "已关闭 Smart Auto Hide: $BAR_NAME"
        else
            log "关闭 Smart Auto Hide 失败"
        fi
    fi
}

log "开始监听 Umbriel 窗口事件"
log "目标 Bar: $BAR_NAME"

# 启动时立即检查一次
update_bar

# 持续监听窗口事件
while IFS= read -r event; do
    update_bar
done < <(umbriel subscribe windows)

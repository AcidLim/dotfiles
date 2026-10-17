
#!/usr/bin/env bash

set -u

BAR_NAME="top_main"
LAST_STATE=""

log() {
    printf '[maximize-bar] %s\n' "$*"
}

update_bar() {
    local workspaces_json windows_json workspace_id max_windows new_state

    # 查询当前最新状态，避免直接使用事件中的短暂中间状态
    workspaces_json=$(umbriel workspaces --json) || {
        log "获取工作区失败"
        return
    }

    windows_json=$(umbriel windows --json) || {
        log "获取窗口失败"
        return
    }

    workspace_id=$(
        jq -r '.[] | select(.focused == true) | .id' \
            <<< "$workspaces_json" | head -n 1
    )

    if [[ -z "$workspace_id" ]]; then
        log "无法确定当前工作区，暂不改变 Bar 状态"
        return
    fi

    max_windows=$(
        jq --arg ws "$workspace_id" \
            '[.[] | select(.workspace == $ws and .maximized == true)] | length' \
            <<< "$windows_json"
    )

    if (( max_windows > 0 )); then
        new_state="HIDDEN"
    else
        new_state="SHOWN"
    fi

    # 状态没变化就不重复调用 Noctalia
    [[ "$new_state" == "$LAST_STATE" ]] && return

    log "工作区: $workspace_id"
    log "检测到最大化窗口: $max_windows"

    if [[ "$new_state" == "HIDDEN" ]]; then
        if noctalia msg bar-hide "$BAR_NAME"; then
            LAST_STATE="HIDDEN"
            log "已隐藏 Bar: $BAR_NAME"
        else
            log "隐藏 Bar 失败"
        fi
    else
        if noctalia msg bar-show "$BAR_NAME"; then
            LAST_STATE="SHOWN"
            log "已显示 Bar: $BAR_NAME"
        else
            log "显示 Bar 失败"
        fi
    fi
}

log "开始监听 Umbriel 工作区与窗口事件"
log "目标 Bar: $BAR_NAME"

# 订阅两个事件源；短暂合并连续事件，再查询最新状态
while IFS= read -r event; do
    while IFS= read -r -t 0.15 next_event; do
        event="$next_event"
    done

    update_bar
done < <(umbriel subscribe workspaces,windows)


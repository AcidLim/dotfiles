#!/usr/bin/env bash
#
# 让 Noctalia 顶栏在「当前聚焦窗口最大化」时进入 Smart Auto Hide，否则关闭。
#
# 为什么写成这样（2026-11 修复「脚本自己退出」）：
#   * `umbriel subscribe windows` 每行是一条 {"event":"windows","data":[...]} 完整快照；
#   * compositor 对「不读数据」的订阅者有 256 KiB 背压上限，超了直接断开
#     （日志：`[ipc] subscriber fd N is not draining (...) , disconnecting`）；
#   * `umbriel subscribe` 收到 EOF 时静默退出（exit 0），旧写法 `while read` 于是自然结束，
#     看起来就是「脚本自己结束了」，没有任何报错。
#   旧写法每条事件都要再跑一次 `umbriel windows --json` + 3 个 jq 子进程（实测约 20 ms/条，
#   而上限约 88 条），拖拽窗口时事件按帧上报，几十秒就能把队列撑爆。
#
#   现在的做法：
#     1. 直接用事件负载里的 `data`，不再二次查询；
#     2. 解析交给 jq 流式处理（实测 1000 条事件约 5 ms），bash 侧只做字符串比较；
#     3. 事件是完整快照，连续到达时只保留最新一条，避免抖动；
#     4. 外层重连：万一仍被断开（compositor 重启、极端风暴），2 秒后自动续上。

set -u

BAR_NAME="${BAR_NAME:-top_main}"
LAST_STATE=""

log() { printf '[maximize-bar] %s\n' "$*"; }

apply_state() {
    local new_state="$1"

    [[ "$new_state" == "$LAST_STATE" ]] && return

    case "$new_state" in
        SMART)
            if noctalia msg bar-auto-hide-set smart "$BAR_NAME"; then
                LAST_STATE="SMART"
                log "已启用 Smart Auto Hide: $BAR_NAME"
            else
                log "启用 Smart Auto Hide 失败"
            fi
            ;;
        NORMAL)
            if noctalia msg bar-auto-hide-set off "$BAR_NAME"; then
                LAST_STATE="NORMAL"
                log "已关闭 Smart Auto Hide: $BAR_NAME"
            else
                log "关闭 Smart Auto Hide 失败"
            fi
            ;;
    esac
}

# 事件流 → 每行一个状态。没有聚焦窗口时 jq 不输出任何内容，保持现状。
watch_once() {
    umbriel subscribe windows | jq --unbuffered -r '
        [ .data[] | select(.active == true) ][0] // empty
        | if .maximized then "SMART" else "NORMAL" end
    '
}

log "开始监听 Umbriel 窗口事件"
log "目标 Bar: $BAR_NAME"

while :; do
    while IFS= read -r state; do
        # 事件是完整快照：积压时只保留最新的一条，不必逐条应用
        # 注意：`read -t 0` 只探测、不读取也不赋值（变量在 set -u 下会未定义），
        # 所以这里给一个极小的超时，命中时才会真正读走一行。
        while IFS= read -r -t 0.01 next; do
            state="$next"
        done
        apply_state "$state"
    done < <(watch_once)

    log "事件流断开，2 秒后重连"
    sleep 2
done

# modules/rule —— 窗口 / 层规则

文件名前缀就是优先级。Umbriel 的合并语义是：

- `[include]` 按列表顺序应用，**包含它的主文件最后应用**；
- `[[window_rule]]` / `[[layer_rule]]` 是**规则数组，跨文件按顺序追加**；
- 同一条窗口上，**每条匹配的规则都贡献字段，同字段"后者胜"**。

## 文件职责

| 文件 | 只负责 |
|---|---|
| `00-defaults.toml` | 无 match 的兜底（`blur = false`、`blur_optimized = false`） |
| `10-float.toml` | `default_floating` |
| `20-size.toml` | `default_floating_size_px/_size`、`default_scrolling_extent(_px)` |
| `30-placement.toml` | `default_position`、`default_focused`、`default_fullscreen` |
| `40-blur.toml` | `[[window_rule]]` 的 `blur*` |
| `50-layer-blur.toml` | `[[layer_rule]]` 的 `blur*`（layer-shell，与窗口规则是两套对象） |
| `60-opacity.toml` | `opacity` |
| `70-decoration.toml` | `corner_radius` / `border_*` / `shadow` / `title_bar` |
| `80-override.toml` | 特殊场景覆写：游戏、媒体播放器、画中画强制不透明/无模糊 |

## 两条约束

1. `00-defaults.toml` 必须最前，`80-override.toml` 必须最后；
2. 其余文件之间**同一 (应用, 字段) 只出现一次**，所以顺序无所谓——
   想让某个应用换行/换尺寸/换透明度，只改对应的那一个文件。

全局模糊参数（passes/radius/noise…）不在这里，在 `modules/appearance.toml` 的 `[appearance.blur]`。

改完校验：`umbriel config validate`。

# Niri / Umbriel × Noctalia Wayland Dotfiles

个人的 CachyOS + Wayland 桌面配置。仓库结构直接**镜像家目录**：

- `dotfiles/.config/` → `~/.config/`
- `dotfiles/.local/bin/` → `~/.local/bin/`

全部通过软链接部署，改仓库即改系统配置；安装脚本逐项、原子地替换链接，不会一次性删光配置。

> **2026-11 重构**：此前是按「Noctalia / DMS 双会话」维护的，现已不再维护 DMS（DankMaterialShell）会话。
> 现在桌面 = **合成器 + Noctalia 外壳** 的组合：
>
> | 组合 | 合成器 | 外壳 | 入口 |
> | --- | --- | --- | --- |
> | **Niri + Noctalia**（主力） | niri | noctalia | `niri-noctalia-session` |
> | **Umbriel + Noctalia** | umbriel | noctalia | `start-umbriel` |
>
> `DankMaterialShell/`、`bin/`、`wayland-sessions/` 不再纳入版本管理，仅在本机保留。

## 📖 简介

- **组合式桌面**：合成器只负责窗口管理，Noctalia 负责面板、启动器、壁纸、配色等外壳能力，两者通过各自的配置解耦。
- **动态主题配色**：Matugen 读取当前壁纸提取主色，生成 kitty / fastfetch / GTK / fuzzel / btop / cava / starship / yazi 等全套配色。
- **配色联动已插件化**：触发方从 `[hooks]` 脚本升级为 Noctalia 插件 [Matugen Themer](https://github.com/AcidLim/matugen-themer)——后台服务轮询壁纸路径，变化即重跑 matugen，并接管视频壁纸取帧；旧脚本机制保留为回退方案。
- **随机动漫壁纸**：`Mod+Shift+F10` 异步下载并切换壁纸，切换后配色自动跟随。
- **镜像家目录的仓库结构**：一眼看出每个文件最终落在系统哪里，迁移、备份、回滚都很直接。

## 🖼️ 效果预览

![Niri + Noctalia](./Preview/niri-noctalia.png)
![Umbriel + Noctalia](./Preview/umbriel-noctalia.png)

## 📁 目录结构

```Plain Text
dotfiles/
├── .config/                       # → ~/.config（逐项软链接）
│   ├── niri/                      # Niri 合成器：noctalia 会话配置
│   │   ├── niri-noctalia.kdl      # 会话主配置（include noctalia/*.kdl）
│   │   ├── noctalia/              # 拆分的模块：layout/binds/blur/…
│   │   ├── cfg/                   # 通用基础片段
│   │   ├── scripts/               # niri 辅助脚本（截图音效、窗口拾取、硬杀窗口）
│   │   ├── dms/                   # DMS 时期的历史片段（保留备用）
│   │   └── config.kdl             # 单文件版历史配置
│   ├── umbriel/                   # Umbriel 合成器配置
│   │   ├── config.toml            # 主配置（include modules/*.toml，autostart 拉起 noctalia）
│   │   ├── modules/               # binds/layout/blur/windowrules/…
│   │   └── scripts/               # maximized-bar.sh、umbriel-screenshot
│   ├── noctalia/                  # Noctalia 外壳配置
│   │   ├── noctalia-config.toml   # 主配置（含 [hooks] 壁纸钩子，回退用）
│   │   ├── colors.json / plugins.json
│   │   └── scripts/               # 旧 matugen 钩子、outputs 生成、mpv 取帧
│   ├── matugen/                   # 动态配色：config.toml + templates/
│   ├── fish/                      # Fish 配置（completions/conf.d/functions）
│   ├── kitty/                     # Kitty 终端配置与主题
│   ├── nvim/                      # Neovim（Lazy）配置
│   ├── superfile/                 # Superfile 文件管理器
│   ├── fastfetch/                 # 系统信息展示（logo 为 ~/Pictures 的链接）
│   ├── xdg-desktop-portal/        # niri-portals.conf
│   ├── mimeapps.list              # 默认应用关联
│   ├── user-dirs.dirs / user-dirs.locale
│   └── xdg-terminals.list
├── .local/bin/                    # → ~/.local/bin（逐项软链接）
│   ├── random-anime-wallpaper-noctalia  # 随机动漫壁纸（当前）
│   └── random-anime-wallpaper-dms       # 随机壁纸（DMS 时期，保留备用）
├── bin/                           # 仅本地：会话启动器 → /usr/local/bin
├── wayland-sessions/              # 仅本地：桌面入口 → /usr/share/wayland-sessions
├── Preview/                       # 效果图
├── patches/umbriel/               # 本地补丁：IPC 背压改为合并快照（见目录内 README）
├── install.sh                     # 一键部署 / 校验
├── .gitignore
└── README.md
```

**只在本机、不入库的部分**（`.gitignore` 中已忽略）：

| 路径 | 用途 |
| --- | --- |
| `bin/` | 会话启动器，部署到 `/usr/local/bin/` |
| `wayland-sessions/` | `.desktop` 入口，部署到 `/usr/share/wayland-sessions/` |
| `.config/DankMaterialShell/` | 已弃用的 DMS 配置，仅本地留存 |
| `.config/kitty/themes`、`fastfetch/config.jsonc` 等 | 运行时由 Matugen 生成 |

另外，配色插件 **Matugen Themer** 的源码在本机 `~/DSH-Workspace/Matugen-Themer`，软链接入 `~/.local/share/noctalia/plugins/matugen-themer`，同样不属于本仓库（见 [配色生成机制](#-配色生成机制)）。

## ⚙️ 安装与校验

```bash
cd ~/dotfiles

./install.sh              # 链接 .config/* → ~/.config，.local/bin/* → ~/.local/bin
sudo ./install.sh --system  # 额外部署 bin/* 与 wayland-sessions/*.desktop
./install.sh --check      # 只校验链接，不改动任何文件
```

安装规则：

1. 逐项处理，不批量删除；
2. 已指向正确位置的链接直接跳过；
3. 旧链接用「临时链接 + rename」原子覆盖，避免出现链接已断的窗口期；
4. 目标位置若是实体文件/目录，先备份为 `<name>.bak-<时间戳>` 再建立链接。

## 🔧 启动链路

```Plain Text
greetd
├─ niri-noctalia.desktop
│   └─ /usr/local/bin/niri-noctalia-session
│       └─ niri -c ~/.config/niri/niri-noctalia.kdl
│           └─ autostart: noctalia（外壳 / 面板 / 壁纸）
└─ umbriel.desktop
    └─ /usr/bin/start-umbriel
        └─ ~/.config/umbriel/config.toml
            └─ autostart: noctalia（外壳 / 面板 / 壁纸）
```

## 🎨 配色生成机制

配色的唯一源头是 `.config/matugen/config.toml` + `.config/matugen/templates/`，区别只在**由谁触发**。目前有两代机制：新一代 Noctalia 插件（当前使用），以及旧的 `[hooks]` 脚本（保留作回退）。

### 当前：Noctalia 插件 `Matugen Themer`

- 仓库：[AcidLim/matugen-themer](https://github.com/AcidLim/matugen-themer)（私有；本机检出在 `~/DSH-Workspace/Matugen-Themer`）
- 身份：`Limwe/matugen-themer` v2.2.1，Noctalia v5 本地插件，依赖 `matugen` + `ffmpeg`
- 为什么要它：Noctalia v5 没有「壁纸变更」事件（`onOutputsChanged()` 只在输出集合/几何变化时触发，`wallpaperPath()` 只是查询），所以插件用一个后台 `themer` 服务定时比对壁纸路径，默认 1 秒一次，开销只是几次进程内取值加一次 `stat`。

它一次性接替了原先三套脚本的活：

| 原本 | 现在 |
| --- | --- |
| `matugen.sh` + `[hooks] wallpaper_changed` | `themer` 服务自己监听壁纸路径 |
| `mpv/mpv-hook.lua` | 服务读 mpvpaper 的 `assignments.json`，ffmpeg 取帧后取色 |
| `mpv/mpvpaper-sync.sh` | 同上，但不用 inotify、不用 jq |

链路：

```Plain Text
壁纸变化
├─ 静态图：逐个输出查询 wallpaperPath（进程内）
└─ 视频：mpvpaper 的 assignments.json（按 mtime stat，变了才解析）
             └─ ffmpeg 取帧 → 帧缓存（可选 setWallpaper 交回外壳）
                        ↓
matugen image <壁纸> --type <方案> --mode <dark|light|auto> --prefer <偏好>
                        ↓
       .config/matugen/config.toml 的 templates 逐个渲染
                        ↓
   kitty / fastfetch / GTK / fuzzel / btop / cava / starship / yazi 即时换色
```

安装（本机已启用；软链指回检出目录，改 `.luau` 会热重载）：

```bash
mkdir -p ~/.local/share/noctalia/plugins
ln -s ~/DSH-Workspace/Matugen-Themer ~/.local/share/noctalia/plugins/matugen-themer
noctalia msg plugins enable Limwe/matugen-themer
noctalia msg plugins list | grep -i matugen
# Limwe/matugen-themer [local] 2.2.1 enabled requires matugen, ffmpeg
```

> `~/.local/share/noctalia/plugins/` 是内置 local source，不用 `source add`。
> 目录名必须是 `matugen-themer`（大小写敏感，对应 id 的 `/` 后半段），否则 enable 会报 `parse error: File could not be opened for reading`。
> 改 `plugin.toml` 后需要 `noctalia msg config-reload`，不生效再 disable + enable；`.luau` 改动保存即热重载。

常用操作：

```bash
noctalia msg plugin Limwe/matugen-themer:themer all refresh   # 立即按当前壁纸重新生成
noctalia msg plugin Limwe/matugen-themer:themer all status    # 查看最近一次状态（含 视频 -> 帧 路径）
noctalia msg settings-open-plugin Limwe/matugen-themer        # 打开插件设置
```

- **控制中心磁贴**：设置 → 控制中心 → 快捷方式 → 添加「Matugen 配色」；左键刷新、右键打开设置，运行中显示忙碌标签。
- **关键设置**：`type`（9 种方案算法）/ `mode`（`dark` / `light` / `auto` 跟随外壳明暗）/ `prefer` / `source_index` / `contrast`；视频相关 `video_mode`、`shell_wallpaper`、`frame_offset`、`frame_width`；`interval`（250–10000ms）、`run_on_start`、`notify_errors`。完整表见插件仓库 README。
- **多显示器**：每个输出单独记录当前画面来源（视频或静态图），谁变了就用谁生成；同一 tick 多个输出变化时优先聚焦输出。
- **与旧 hook 互斥**：插件启用后要注释掉 `[hooks] wallpaper_changed`，并去掉 `mpv_options` 里挂的 `mpv-hook.lua`，否则换一次壁纸会各跑一次、甚至互相覆盖壁纸。
- **日志**：`journalctl --user -f | grep -i matugen`；帧缓存与插件数据在 `~/.local/state/noctalia/plugins/data/Limwe/matugen-themer/`。

### 旧机制：`[hooks]` + 脚本（保留，作回退）

1. 壁纸变化 → Noctalia 触发 `[hooks] wallpaper_changed`
2. 执行 `~/.config/noctalia/scripts/matugen/matugen.sh`
3. 读取 `~/.config/noctalia/scripts/matugen/config.json` 的配色规则
4. Matugen 按 `~/.config/matugen/config.toml` 的模板渲染，写回各应用配置
5. 终端 / GTK / fastfetch / btop / cava 等即时换色

`theme_mode_changed` 钩子预留了 `~/.config/noctalia/theme-sync.sh` 入口（可选，不存在时不影响壁纸配色）。
视频壁纸由 `scripts/mpv/mpv-hook.lua`、`scripts/mpv/mpvpaper-sync.sh` 负责取帧并设成外壳壁纸——这部分功能现已与插件重叠。

### 相关文件

| 文件 | 作用 |
| --- | --- |
| `.config/matugen/config.toml` | 模板与输出路径（两代机制共用） |
| `.config/matugen/templates/` | 各应用的配色模板 |
| `.config/noctalia/scripts/matugen/{matugen.sh,config.json}` | 旧机制脚本与配色规则 |
| `.config/noctalia/scripts/mpv/` | 旧视频壁纸取帧脚本 |
| `~/DSH-Workspace/Matugen-Themer` | 插件源码（本机检出，不在本仓库） |
| `~/.local/share/noctalia/plugins/matugen-themer` | 指向插件源码的软链 |
| `~/.local/state/noctalia/` | 插件帧缓存与设置（state，不入库） |

## 🌊 随机壁纸

- Noctalia：`Mod+Shift+F10` → `~/.local/bin/random-anime-wallpaper-noctalia` → `noctalia msg wallpaper-set` → 由 Matugen Themer 插件自动重载配色（回退机制下则由 `wallpaper_changed` hook 触发 `matugen.sh`）
- DMS 时期：`random-anime-wallpaper-dms`，调用 `dms ipc call wallpaper set`，保留备用

## 📌 依赖

- 合成器：`niri` 或 `umbriel`
- 外壳：`noctalia`（v5+，插件 API 25）
- 配色：`matugen`（4.x）、`ffmpeg`（视频壁纸取帧）
- 插件：`Limwe/matugen-themer`（本地插件，见上）
- 其他：`fish`、`kitty`、`nvim`、`superfile`、`fastfetch`、`fcitx5`、`greetd`
- 环境：Linux（CachyOS）、Wayland

## 🔄 后续计划

- 清理 `niri/dms/`、`config.kdl` 等 DMS 时期遗留配置
- 收尾视频壁纸链路：确认 `shell_wallpaper` 与旧 `mpv-hook.lua` / `mpvpaper-sync.sh` 的取舍，只留一条路径
- 壁纸脚本收敛为单一实现，用参数区分合成器
- 把 Matugen Themer 源码纳入备份（目前只在本机工作区）

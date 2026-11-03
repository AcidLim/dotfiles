# umbriel 本地补丁

## 这是什么

`0001-ipc-coalesce-snapshots.patch` —— 改 `umbriel` compositor 的 IPC 广播策略：

- **原行为**：订阅者（`umbriel subscribe …`）如果没及时读走事件，待发队列超过 256 KiB，compositor 直接
  `removeConnection()`，日志留一行 `[ipc] subscriber fd N is not draining (...) , disconnecting`。
- **补丁后**：超限时不再断开，而是把未发送的尾巴替换成「每个事件族的最新快照」再继续发。
  因为所有事件都是**全量快照**（payload 不是增量），丢中间帧对消费者零损失——它本来就要用最新一条覆盖状态。

补丁只动 `src/server/ipc.cpp` 的 `Ipc::broadcastEvent()`，删掉 `evicted` 的收集与断开循环。

## 为什么需要它

`maximized-bar.sh` 这类脚本、以及 Noctalia 自己的 bar 订阅，都是「慢消费者」：事件按窗口变化成批到达，
拖拽/缩放浮动窗口时位置按帧上报，消费端一慢就会撞上 256 KiB 上限被踢掉；客户端 `umbriel subscribe`
收到 EOF 后静默 `exit 0`，看起来像「自己结束了」。

- 脚本侧已经改成「不二次查询 + 断流自愈」（commit `394c2bb`），**不装这个补丁脚本也能活**。
- 这个补丁解决的是根因本身：让慢消费者只看到「最新状态」而不是被断流，Noctalia 的订阅也一起受益。

## 为什么「每次构建都会自动带上补丁」

补丁文件本身不会自动生效，真正让它每次生效的是 **PKGBUILD 的 `prepare()`**：

```
makepkg 的固定顺序：
  source 拉取 → 校验 → 解包到 $srcdir → prepare() → build() → package() → 装包
                                      ↑ 每次构建都执行，不是只跑一次
```

`umbriel-git` 的 `source` 是 git 仓库，每次构建都会把源码重新检出/更新到 `$srcdir/umbriel`（干净树），
于是 `prepare()` 里的 `patch` 每次都打在干净源码上，不会出现「第二次报 already applied」。
前提是**这次构建用的是你自己这份 PKGBUILD**（本目录的），见下一节。

## 用法：本目录就是构建目录

本目录自带 `PKGBUILD`（AUR 原版 + 一处 `prepare()`）：

```bash
cd ~/dotfiles/patches/umbriel
makepkg -si          # 需要 sudo；装完必须退出会话重新登录才生效
```

`prepare()` 只有三行：

```bash
prepare() {
  cd "$srcdir/umbriel"
  patch -Np1 -i "$startdir/0001-ipc-coalesce-snapshots.patch"
}
```

`-Np1` 对应 git diff 的 `a/` `b/` 前缀。几个目录变量（本机实测）：

| 变量 | 含义 | 本例取值 |
| --- | --- | --- |
| `$startdir` | 运行 `makepkg` 的目录；makepkg 要求 PKGBUILD 必须就在当前目录（`-p` 指向别处会直接报错），所以它就等于 PKGBUILD 所在目录 | `~/dotfiles/patches/umbriel` |
| `$srcdir` | 解包/检出源码的位置，默认 `$startdir/src`；`prepare()` 执行时 makepkg 已经把 cwd 切到这里 | `~/dotfiles/patches/umbriel/src` |
| `$pkgdir` | 打包暂存目录，默认 `$startdir/pkg` | `~/dotfiles/patches/umbriel/pkg` |

不想在 dotfiles 里留构建产物，把 `PKGBUILD` 和补丁一起复制到别处（如 `~/build/umbriel/`）构建即可，
`$startdir` 会随之变成那个目录。

### 构建产物都落在本目录，已全部忽略

`makepkg` 默认把东西都写进构建目录，所以这里会多出：

| 路径 | 是什么 |
| --- | --- |
| `src/` | 源码检出（含 `src/umbriel/build/`），即 `$srcdir` |
| `pkg/` | 打包暂存，即 `$pkgdir` |
| `umbriel/` | VCS 源码的裸镜像：`makepkg` 先 `git clone --mirror` 到 `$SRCDEST/<name>`，再从它检出到 `src/`；`$SRCDEST` 默认就是构建目录，所以每次构建都会更新这一份 |
| `*.pkg.tar.*` | 打好的包 |

以上都已写进 `.gitignore`（`/patches/*/src/`、`/patches/*/pkg/`、`/patches/umbriel/umbriel/`、
`/patches/*/*.pkg.tar.*`），`git status` 保持干净。

如果想彻底不让这些东西落在仓库里，在 `~/.config/pacman/makepkg.conf` 里设置
`BUILDDIR`、`SRCDEST`、`PKGDEST` 指向仓库外即可（例如 `BUILDDIR=/tmp/makepkg`）。

## 为什么不能用 paru 重建

`paru -S umbriel-git`（**包括 `--rebuild`**）每次都会：

1. 同步 `~/.cache/paru/clone/umbriel-git` 里的 AUR 仓库，PKGBUILD 以 AUR 上的版本为准；
2. 用那份 PKGBUILD 跑 makepkg。

所以：在 AUR 缓存目录里加的 `prepare()` 会被覆盖，补丁不会生效；而本目录的 PKGBUILD paru 根本不会读。
**要装带补丁的包只能用本目录的 `makepkg`；要装/升级官方版才用 paru。**

## 上游更新时怎么办

| 情况 | 处理 |
| --- | --- |
| 只是源码推进（最常见） | 不用动：`source` 是 `git+…#branch=main`，每次 `makepkg` 都会拉最新；只要补丁还能干净应用 |
| 补丁 context 变了 | 下面的 `--dry-run` 会失败，按新的 `broadcastEvent()` 重新生成 diff，思路不变 |
| AUR 的 PKGBUILD 本身变了（依赖 / 构建参数） | `paru -Gp umbriel-git > /tmp/PKGBUILD.aur`，与本目录 PKGBUILD diff，把新增项合并进来，保留 `prepare()` |
| 完全离线构建 | 把 source 换成本地缓存：`source=('umbriel::git+file:///home/acid/.cache/paru/clone/umbriel-git/umbriel#branch=main')`（该缓存由 paru 更新） |

## 验证与排错

```bash
# 补丁是否还能干净应用（上游改动后 context 可能变）
cd /tmp && git clone ~/.cache/paru/clone/umbriel-git/umbriel umbriel-check
cd umbriel-check && patch -Np1 --dry-run -i ~/dotfiles/patches/umbriel/0001-ipc-coalesce-snapshots.patch

# 装上之后：正常情况不该再出现 disconnecting
journalctl --no-pager -b | grep -i 'ipc.*subscriber'
# 落后时会变成：subscriber fd N fell ... bytes behind, coalescing to the newest snapshots
```

基于版本：AUR `umbriel-git 1:0.1.0.r1504.e0da106-1`（源码 HEAD `e0da1063`）。补丁已按该版本重新生成
（0 offset），并用 AUR 当前的构建参数（`-Db_ndebug=true -Dtests=disabled -Dharness=disabled`）
编译验证通过。

## 撤销

```bash
paru -S --rebuild umbriel-git   # 这次反而正确：paru 会用不带 prepare() 的 AUR PKGBUILD 重装
```

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

## 为什么「每次编译都会自动带上补丁」

补丁文件放在这里只是**存档**，真正让它每次生效的是 **PKGBUILD 的 `prepare()`**：

```
makepkg 的固定顺序：
  source 拉取 → 校验 → 解包到 $srcdir → prepare() → build() → package() → 装包
                                      ↑ 每次构建都执行，不是只跑一次
```

`umbriel-git` 的 `source` 是 git 仓库，每次构建都会把源码重新检出/更新到 `$srcdir/umbriel`（干净树），
于是 `prepare()` 里那条 `patch` 每次都作用在干净源码上，再进 `build()`——所以不会出现「第二次 `patch`
报 already applied」的问题，也不需要手动记得打补丁。AUR 助手（paru/yay）本身**不认识**本目录，
它只是按 PKGBUILD 执行；「自动」来自 `prepare()`，不是来自 dotfiles。

基于版本：`umbriel-git 1:0.1.0.r1398.d9497f36-1`（AUR 的 git 源 HEAD `d9497f36`），
已在该版本上 `meson setup` + `ninja` 编译验证通过。

## 用法（推荐：独立构建目录，不被 AUR 更新覆盖）

```bash
# 1) 把 AUR 的 PKGBUILD 复制到这里（本目录已有补丁）
cp ~/.cache/paru/clone/umbriel-git/PKGBUILD ~/dotfiles/patches/umbriel/

# 2) 在 PKGBUILD 里加 prepare()，在 build() 之前
prepare() {
  cd "$srcdir/umbriel"
  patch -Np1 -i "$startdir/0001-ipc-coalesce-snapshots.patch"
}

# 3) 构建并安装（要 sudo；装完必须重新登录会话才生效）
cd ~/dotfiles/patches/umbriel
makepkg -si
```

`$startdir` 是 `makepkg` 被调用的目录，也就是放着 PKGBUILD 和补丁的本目录；`-Np1` 对应 git diff 的
`a/` `b/` 前缀。

如果不想在 dotfiles 里留构建产物，把 `PKGBUILD` 和补丁一起复制到别处（如 `~/build/umbriel/`）构建，
把 `$startdir` 换成补丁的绝对路径即可。

### 另一种方式（省事但会被覆盖）

直接改 `~/.cache/paru/clone/umbriel-git/PKGBUILD`，加上同样的 `prepare()`，然后：

```bash
paru -S --rebuild umbriel-git     # 同 pkgver 时必须 --rebuild，否则会跳过
```

缺点：AUR 更新 PKGBUILD 时 paru 会提示合并/覆盖，补丁可能丢，需要重打。

## 验证与排错

```bash
# 补丁是否还能干净应用（上游改动后 context 可能变）
cd /tmp && git clone ~/.cache/paru/clone/umbriel-git/umbriel umbriel-check
cd umbriel-check && patch -Np1 --dry-run -i ~/dotfiles/patches/umbriel/0001-ipc-coalesce-snapshots.patch

# 装上之后：正常情况不该再出现 disconnecting
journalctl --no-pager -b | grep -i 'ipc.*subscriber'
# 落后时会变成：subscriber fd N fell ... bytes behind, coalescing to the newest snapshots
```

如果上游把这段代码改掉了，补丁会 `--dry-run` 失败——按新的 `broadcastEvent()` 重新生成 diff 即可，
思路不变：**超限时用最新快照替换未发送队列，而不是断开连接**。

## 撤销

```bash
paru -S --rebuild umbriel-git   # 用不带 prepare() 的 PKGBUILD 重装，回到上游行为
# 或把新版包装回去
```

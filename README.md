# My Dotfiles 配置管理仓库

个人 Linux 环境配置文件统一管理仓库，用于备份、同步、迁移桌面环境配置，实现多设备配置一键恢复。

## 当前设备环境

- **操作系统**：CachyOS

- **窗口管理器**：Niri

- **终端 Shell**：DankMaterialShell

- **代码编辑器**：Neovim

- **终端模拟器**：Kitty

## 仓库目录结构

```Plain Text
dotfiles/
├── nvim/                # Neovim 完整配置
├── niri/                # Niri 窗口管理器配置
├── kitty/               # Kitty 终端配置
├── DankMaterialShell/   # DMS Shell 配置
├── install.sh          # 一键软链接安装脚本
└── README.md           # 仓库说明文档
```

# 一、首次初始化 Dotfiles（配置迁移）

## 1\.1 创建仓库根目录

在用户家目录创建 `dotfiles` 文件夹，用于统一存放所有配置文件：

```Plain Text
mkdir ~/dotfiles
cd ~/dotfiles
```

## 1\.2 迁移本地已有配置

将系统 `.config` 目录下的个人配置移动到 dotfiles 仓库目录：

```Plain Text
# 迁移 Neovim 配置
mv ~/.config/nvim ~/dotfiles/nvim

# 迁移 Niri 窗口管理器配置
mv ~/.config/niri ~/dotfiles/niri

# 迁移 Kitty 终端配置
mv ~/.config/kitty ~/dotfiles/kitty

# 迁移 DankMaterialShell 配置
mv ~/.config/DankMaterialShell ~/dotfiles/DankMaterialShell
```

# 二、创建配置软链接

通过软链接让系统默认配置目录 `~/.config` 关联到 `~/dotfiles` 仓库，后续修改仓库配置即可实时生效，无需重复复制文件。

```Plain Text
# 创建 Neovim 软链接
ln -s ~/dotfiles/nvim ~/.config/nvim

# 创建 Niri 软链接
ln -s ~/dotfiles/niri ~/.config/niri

# 创建 Kitty 软链接
ln -s ~/dotfiles/kitty ~/.config/kitty

# 创建 DMS 软链接
ln -s ~/dotfiles/DankMaterialShell ~/.config/DankMaterialShell
```

## 验证软链接

执行以下命令查看链接状态：

```Plain Text
ls -l ~/.config
```

输出包含 `xxx -> /home/用户名/dotfiles/xxx` 即代表软链接创建成功。

# 三、初始化本地 Git 仓库

进入仓库目录，初始化 Git 版本管理：

```Plain Text
cd ~/dotfiles

# 初始化本地仓库
git init

# 添加所有配置文件到暂存区
git add .

# 首次提交版本
git commit -m "initial dotfiles: 初始化个人环境配置"
```

# 四、配置 GitHub SSH 密钥

## 4\.1 检查已有密钥

```Plain Text
ls ~/.ssh
```

若存在 `id_ed25519`、`id_ed25519.pub`，可直接使用现有密钥。

## 4\.2 生成新 SSH 密钥

替换为你的 GitHub 注册邮箱：

```Plain Text
ssh-keygen -t ed25519 -C "你的GitHub邮箱"
```

## 4\.3 配置 GitHub 公钥

查看并复制公钥内容：

```Plain Text
cat ~/.ssh/id_ed25519.pub
```

进入 GitHub 官网：`Settings → SSH and GPG keys → New SSH key`，粘贴公钥并保存。

## 4\.4 测试 SSH 连接

```Plain Text
ssh -T git@github.com
```

提示 `Hi 用户名! You've successfully authenticated` 即配置成功。

# 五、关联远程 GitHub 仓库

## 5\.1 绑定远程仓库

替换为你的 GitHub 仓库地址：

```Plain Text
git remote add origin git@github.com:你的用户名/dotfiles.git
```

## 5\.2 验证远程地址

```Plain Text
git remote -v
```

## 5\.3 首次推送代码

```Plain Text
# 设置默认主分支
git branch -M main

# 推送到远程仓库
git push -u origin main
```

# 六、日常配置更新与同步

修改配置后，通过以下命令同步到远程仓库：

```Plain Text
# 查看文件修改状态
git status

# 查看详细修改内容
git diff

# 提交所有修改
git add .
git commit -m "update: 更新xxx配置"

# 同步到 GitHub
git push
```

# 七、配置 Git 忽略文件

## 7\.1 创建 \.gitignore 文件

```Plain Text
nvim .gitignore
```

## 7\.2 基础忽略规则

```Plain Text
# DMS 独立插件目录（子仓库无需上传）
DankMaterialShell/plugins/
# 缓存文件
.cache/
# 日志文件
*.log
```

## 7\.3 清理已提交的子仓库文件

DMS 插件多为独立 Git 子仓库，直接提交会触发 `embedded git repository` 报错，执行以下命令仅从 Git 移除记录、保留本地文件：

```Plain Text
git rm -r --cached -f DankMaterialShell/plugins
```

# 八、新设备环境迁移恢复

## 8\.1 安装基础依赖软件

新设备需提前安装对应环境软件：`git、nvim、niri、kitty、DankMaterialShell`

## 8\.2 克隆远程配置仓库

```Plain Text
git clone git@github.com:你的用户名/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 8\.3 执行一键安装脚本

```Plain Text
# 赋予脚本执行权限
chmod +x install.sh

# 运行配置恢复脚本
./install.sh
```

脚本会自动删除系统默认配置、创建全局软链接，一键恢复个人定制环境。

# 九、多设备配置同步更新

其他设备需要同步最新配置时，执行拉取命令即可，软链接配置会实时生效：

```Plain Text
cd ~/dotfiles
git pull
```

> （注：部分内容可能由 AI 生成）

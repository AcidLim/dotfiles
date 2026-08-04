if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting "Welcome back, Acid."
set -p PATH ~/.local/bin
starship init fish | source
zoxide init fish --cmd cd | source
# 111
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
		builtin cd -- "$cwd"
	end
	rm -f -- "$tmp"
end

function cat 
	command bat $argv
end
function ls
	command eza --icons=auto --color=auto $argv
end

function lt
	command eza --icons --tree $argv
end
# grub
abbr grub 'LANGUAGE=en_US.UTF-8 LANG=en_US.UTF-8 sudo grub-mkconfig -o /boot/grub/grub.cfg'
# 小黄鸭补帧 需要steam安装正版小黄鸭
abbr lsfg 'LSFG_PROCESS="miyu"'
# fa运行fastfetch
abbr fa fastfetch
abbr reboot 'systemctl reboot'
function sl 
	command sl | lolcat	
end
function 滚
	sysup 
end
function raw
	command ~/.local/bin/random-anime-wallpaper-dms $argv
end

function 安装
	command yay -S $argv
end

function 卸载
	command yay -Rns $argv
end 

function hmcl
	bash /home/acid/Games/Minecraft/HMCL/hmcl.sh &; disown
end

function steam-fix
    set -x STEAM_WEBKIT_DISABLE_COMPOSITING_MODE 1
    set -x GDK_BACKEND x11
    set -x __GL_THREADED_OPTIMIZATIONS 0

    steam
end

function mirror-update
	sudo cachyos-rate-mirrors
end

function reboot-win
    # 获取所有 Windows Boot Manager EFI 启动项
    set win_entries (efibootmgr | grep -i 'Windows Boot Manager')

    if test (count $win_entries) -eq 0
        echo "未找到 Windows Boot Manager EFI 启动项"
        return 1
    end

    echo "检测到以下 Windows 启动项："
    echo

    set ids

    for i in (seq (count $win_entries))
        set entry $win_entries[$i]

        # 提取 BootXXXX
        set id (string match -r 'Boot[0-9A-Fa-f]+' $entry | string replace 'Boot' '')

        set ids $ids $id

        echo "$i) Boot$id - $entry"
    end

    echo

    read -P "请选择启动项编号: " choice

    if not string match -qr '^[0-9]+$' $choice
        echo "无效选择"
        return 1
    end

    if test $choice -lt 1 -o $choice -gt (count $ids)
        echo "选择超出范围"
        return 1
    end

    set selected $ids[$choice]

    echo "选择 Windows 启动项: Boot$selected"

    if not read -P "确认重启进入 Windows？(Enter继续 Ctrl+C取消): "
        echo "已取消"
        return 1
    end

    sudo efibootmgr --bootnext $selected

    if test $status -ne 0
        echo "设置 BootNext 失败"
        return 1
    end

    echo "正在重启..."
    systemctl reboot
end

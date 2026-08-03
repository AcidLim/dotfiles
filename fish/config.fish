if status is-interactive
    # Commands to run in interactive sessions can go here
end
set fish_greeting ""
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
	command eza --icons $argv
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
    # 获取 Windows Boot Manager EFI 启动项编号
    set win_boot (efibootmgr | grep -i 'Windows Boot Manager' | grep -o 'Boot[0-9]*' | head -n 1 | sed 's/Boot//')

    if test -z "$win_boot"
        echo "未找到 Windows Boot Manager EFI 启动项"
        return 1
    end

    echo "检测到 Windows 启动项 ID: $win_boot"

    read -P "下次启动进入 Windows，按 Enter 继续，Ctrl+C 取消: "

    sudo efibootmgr --bootnext $win_boot

    if test $status -ne 0
        echo "设置 BootNext 失败"
        return 1
    end

    echo "正在重启..."
    systemctl reboot
end

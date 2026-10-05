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
#function raw
#	command ~/.local/bin/random-anime-wallpaper-dms $argv
#end

function hmcl
	bash /home/acid/Games/Minecraft/HMCL/hmcl.sh &; disown
end

function mirror-update
	sudo cachyos-rate-mirrors
end

#cava custom
function cava1
  cava -p ~/.config/cava/config1
end

# pnpm
set -gx PNPM_HOME '/home/acid/.local/share/pnpm'
if not string match -q -- "$PNPM_HOME/bin" $PATH
  set -gx PATH "$PNPM_HOME/bin" $PATH
end
# pnpm end

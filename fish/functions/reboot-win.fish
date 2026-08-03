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

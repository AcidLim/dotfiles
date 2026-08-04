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

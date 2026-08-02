function reboot-win
	sudo grub-reboot "Windows Boot Manager （位于 /dev/nvme0n1p1）" && systemctl reboot
end

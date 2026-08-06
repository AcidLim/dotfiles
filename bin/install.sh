#!/usr/bin/env bash

sudo ln -sfn "$(pwd)/niri-dms-session" /usr/local/bin/niri-dms-session
sudo ln -sfn "$(pwd)/niri-noctalia-session" /usr/local/bin/niri-noctalia

echo "已安装至/usr/local/bin/"

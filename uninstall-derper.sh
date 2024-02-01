#!/bin/bash

base_url="/usr/local/bin"

# 删除临时文件
rm -rf /tmp/tailscale-derp.tar.gz

# 停止并删除开机服务
systemctl stop tailscale-derp.service

# 删除服务文件
rm /etc/systemd/system/tailscale-derp.service

# 重新加载 systemd 的配置
systemctl daemon-reload

# 关闭进程占用
if pgrep derper >/dev/null; then
    kill -9 "$(pgrep derper)"
fi

# 删除文件
rm -rf ${base_url}/tailscale-derp

echo tailscale derp 卸载完成

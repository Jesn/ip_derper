#!/bin/bash

# 获取最新的版本号
VERSION=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Jesn/ip_derper/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

ARCH=$(uname -m)

echo $ARCH

# 根据不同的系统架构下载不同的压缩包
if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch64"* ]] || [[ "$ARCH" == *"arm64"* ]]; then
    URL="https://github.com/Jesn/ip_derper/releases/download/${VERSION}/tailscale-derp-arm.tar.gz"
elif [[ "$ARCH" == *"x86_64"* ]]; then
    URL="https://github.com/Jesn/ip_derper/releases/download/${VERSION}/tailscale-derp-amd.tar.gz"
else
    echo "Unsupported architecture"
    exit 1
fi

# 使用 wget 下载文件
wget -O /tmp/tailscale-derp.tar.gz $URL

# 解压文件到/usr/local/bin/并且重命名为tailscale-derp
tar zxvf /tmp/tailscale-derp.tar.gz -C /usr/local/bin/
# 删除临时文件
rm -rf /tmp/tailscale-derp.tar.gz

echo '#!/bin/bash
bash /usr/local/bin/tailscale-derp/build_cert.sh 127.0.0.1 /usr/local/bin/tailscale-derp/certs /usr/local/bin/tailscale-derp/san.conf && \
/usr/local/bin/tailscale-derp/derper --hostname=127.0.0.1 \
     --certmode=manual \
     --certdir=/usr/local/bin/tailscale-derp/certs \
     --stun-port=58160 \
     --stun=true  \
     --a=:58161 \
     --http-port=58162 \
     --verify-clients=false
' >/usr/local/bin/tailscale-derp/startup.sh
chmod +x /usr/local/bin/tailscale-derp/startup.sh

# 创建开机自启动服务并添加日志记录
echo "[Unit]
Description=Tailscale Derp
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/local/bin/tailscale-derp/startup.sh
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
" >/etc/systemd/system/tailscale-derp.service

# 重启开机服务并加载当前任务
systemctl daemon-reload
systemctl enable tailscale-derp.service
systemctl start tailscale-derp.service

echo tailscale derp 服务已启动,服务状态

systemctl status tailscale-derp.service

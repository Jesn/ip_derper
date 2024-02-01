#!/bin/bash

ARCH=$(uname -m)
ip=$(curl -s ipconfig.io)
base_url="/usr/local/bin"

hostname=127.0.0.1
stun=true
stun_port=58160
derp_port=:58161
http_port=58162
verify_clients=false

# 对每一个端口检查用户的输入
echo "请输入新的stun_port, 或者按enter键保持默认值($stun_port):"
read -r new_stun_port
if [ -n "$new_stun_port" ]; then
    stun_port=$new_stun_port
fi
printf "stun_port的值为: %s\n" "$stun_port"

echo "请输入新的derp_port, 或者按enter键保持默认值($derp_port):"
read -r new_derp_port
if [ -n "$new_derp_port" ]; then
    if [[ $new_derp_port != *":"* ]]; then
        new_derp_port=:$new_derp_port
    fi
    derp_port=$new_derp_port
fi
printf "derp_port的值为: %s\n" "$derp_port"

echo "请输入新的http_port, 或者按enter键保持默认值($http_port):"
read -r new_http_port
if [ -n "$new_http_port" ]; then
    http_port=$new_http_port
fi
printf "http_port的值为: %s\n" "$http_port"

echo "请输入新的verify_clients (true 或 false), 或者按enter键保持默认值($verify_clients):"
read -r new_verify_clients
# 验证用户输入的是否为布尔值
if [[ ${new_verify_clients,,} == "true" ]] || [[ ${new_verify_clients,,} == "false" ]]; then
    verify_clients=$new_verify_clients
fi
printf "verify_clients的值为: %s\n" "$verify_clients"

# 获取最新的版本号
VERSION=$(wget -qO- -t1 -T2 "https://api.github.com/repos/Jesn/ip_derper/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')

# 根据不同的系统架构下载不同的压缩包
if [[ "$ARCH" == *"arm"* ]] || [[ "$ARCH" == *"aarch64"* ]] || [[ "$ARCH" == *"arm64"* ]]; then
    down_url="https://github.com/Jesn/ip_derper/releases/download/${VERSION}/tailscale-derp-arm.tar.gz"
elif [[ "$ARCH" == *"x86_64"* ]]; then
    down_url="https://github.com/Jesn/ip_derper/releases/download/${VERSION}/tailscale-derp-amd.tar.gz"
else
    echo "Unsupported architecture"
    exit 1
fi

# 使用 wget 下载文件
wget -O /tmp/tailscale-derp.tar.gz "$down_url"

# 解压文件到/usr/local/bin/并且重命名为tailscale-derp
tar zxvf /tmp/tailscale-derp.tar.gz -C "$base_url"
# 删除临时文件
rm -rf /tmp/tailscale-derp.tar.gz

cat >${base_url}/tailscale-derp/startup.sh <<END
#!/bin/bash
bash ${base_url}/tailscale-derp/build_cert.sh ${hostname} ${base_url}/tailscale-derp/certs ${base_url}/tailscale-derp/san.conf && \\
${base_url}/tailscale-derp/derper --hostname=${hostname} \\
     --certmode=manual \\
     --certdir=${base_url}/tailscale-derp/certs \\
     --stun-port=$stun_port \\
     --stun=$stun  \\
     --a=$derp_port \\
     --http-port=$http_port \\
     --verify-clients=$verify_clients
END
chmod +x ${base_url}/tailscale-derp/startup.sh

# 创建开机自启动服务并添加日志记录
cat >/etc/systemd/system/tailscale-derp.service <<END
[Unit]
Description=Tailscale Derp
After=network.target
StartLimitIntervalSec=0
[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=${base_url}/tailscale-derp/startup.sh
StandardOutput=journal
StandardError=journal
[Install]
WantedBy=multi-user.target
END

# 重启开机服务并加载当前任务
systemctl daemon-reload
systemctl enable tailscale-derp.service
systemctl start tailscale-derp.service

# 输出tailscale acl 节点配置信息，InsecureForTests 忽略域名证书的效验一定要设置为true
echo "服务器公网IP是: $ip，防火墙请开放以下端口 $stun_port $derp_port $http_port"
echo tailscale acl 节点配置信息，如果公网IP不固定可以改成对应的域名
cat <<END
{
    "904": {
        "RegionID":   904,
        "RegionCode": "rk",
        "RegionName": "rk01",
        "Nodes": [
            {
                "Name":             "rk01-derp",
                "RegionID":         904,
                "HostName":         "$ip",
                "stunport":         $stun_port,
                "derpport":         $derp_port,
                "stunonly":         false,
                "InsecureForTests": true,
            }
        ]
    }
}
END

# 查看服务状态
echo tailscale derp 服务已启动,服务状态
systemctl status tailscale-derp.service

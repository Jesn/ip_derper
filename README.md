# tailscale ip derper 部署,支持amd和arm架构

## 一键启动
```
bash <(curl -Ls https://raw.githubusercontent.com/Jesn/ip_derper/main/install-derper.sh)
```

## 一键删除
```
bash <(curl -Ls https://raw.githubusercontent.com/Jesn/ip_derper/main/uninstall-derper.sh)
```

## Docker部署
```
docker run --restart always \
  --name derper -p 58161:58161 -p 58162:58162 -p 58160:58160/udp \
  -e STUN_PORT=58160 \
  -e DERP_ADDR=:58161 \
  -e DERP_HTTP_PORT=58162 \
  -e DERP_STUN=true \
  -e DERP_VERIFY_CLIENTS=false \
  -d richpeople/ip_derper:latest
```

## 启动Derp命令

``` bash
bash ./build_cert.sh 127.0.0.1 ./certs ./san.conf && \
     ./derper --hostname=127.0.0.1 \
     --certmode=manual \
     --certdir=./certs \
     --stun-port=58160 \
     --stun=true  \
     --a=:58161 \
     --http-port=58162 \
     --verify-clients=false
```

## 防火墙开放端口
开放一下端口 `58160` `58161` `58162`

## tailscale acl 添加配置
``` 
"904": {
	"RegionID":   904,
	"RegionCode": "rk",
	"RegionName": "rk01",
	"Nodes": [
		{
			"Name":             "rk01-derp",
			"RegionID":         904,
			"HostName":         "换成你的公网IP或者域名",
			"stunport":         58160,
			"derpport":         58161,
			"stunonly":         false,
			"InsecureForTests": true,
		}
	]
}
```


![image](https://github.com/Jesn/ip_derper/assets/5728274/e9150aaa-6980-4855-9f3c-6b46d70fe0ad)

![image](https://github.com/Jesn/ip_derper/assets/5728274/120338ea-15e2-4712-a940-bc9e86c783ba)


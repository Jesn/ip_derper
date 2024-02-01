

## 启动Derp

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

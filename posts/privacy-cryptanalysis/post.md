# Eth Piracy: Cryptanalysis

<p style="text-align: right">_- last update 07/11/2021 -_</p>

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


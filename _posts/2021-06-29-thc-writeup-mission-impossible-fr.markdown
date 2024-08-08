---
title: "THC 2021 - Write-Up : Mission Impossible"
lang: fr
ref: thc-2021-writeup-mission-impossible
---

Ce post fait parti d'une série de write-ups faisant suite au CTF de la [Toulouse
Hacking Convention](https://thcon.party/) auquel j'ai eu la chance d'avoir
participé en équipe avec [\@0x_Seb](https://twitter.com/0x_Seb).

Je souhaite remercier également le créateur du challenge, **cryptax**. Nous
avons pris beaucoup de plaisir sur ce challenge qui nous a motivé à écrire notre
premier writup. Si vous souhaitez réaliser le challenge avant ou pendant la
lecture de l'article, vous pouvez télécharger l'APK ici:
[mission-impossible.apk](/assets/2021-06-29/mission-impossible.apk)

![Instructions du challenge Mission Impossible](/assets/2021-06-29/chall-instructions.png)

Le 4ème challenge de la catégorie reverse est un challenge Android. L'énoncé ne
donne pas beaucoup d'indices sur l'emplacement du flag, nous allons donc tout
simplement commencer par exécuter l'application après l'avoir téléchargée.

```bash
> curl -O https://challenges.thcon.party/reverse-axelleapvrille-mission-impossible/mission-impossible.apk
```
```txt
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 5696k  100 5696k    0     0  7336k      0 --:--:-- --:--:-- --:--:-- 7331k
```

Nous avons un smartphone Android sous la main et le plus simple lorsque l'on est
sous Linux est d'utiliser la commande ADB (Android Debug Bridge) fournie par la majorité des
gestionnaires de packets. (L'option `-t` est nécessaire car le package est en
[testOnly](https://developer.android.com/guide/topics/manifest/application-element#testOnly)):

```bash
> adb -t install mission-impossible.apk
```
```txt
Performing Streamed Install
Success
```

L'application est maintenant installée sur le téléphone. Elle affiche simplement
l'image d'une cassette audio et trois boutons qui nous permettent de contrôler
la lecture d'une piste audio: le thème de mission impossible.

![Screenshot de l'application](/assets/2021-06-29/app-screen.jpeg)

Nous savons maintenant que l'APK embarque très probablement une piste
audio stockée localement, mais aucune autre information ne semble intéressante pour le moment. Le
travail de rétro-conception va pouvoir commencer.

Le format APK n'est qu'une archive qui contient du bytecode compatible avec la
machine virtuelle d'Android. C'est une sorte de langage intermédiaire qui va être
interprété dynamiquement pour générer du véritable code machine. Une fois extrait, ce
bytecode à la particularité d'être très facilement décompilable en un ensemble
de fichiers source très proche de ceux écrits par les développeurs. Nous
pourrions utiliser la commande `unzip` puis un décompileur sur chaque fichier
et chercher les bons arguments pour obtenir le code java d'origine. Heureusement
pour nous, le projet open source [jadx](https://github.com/skylot/jadx)
automatise tout ce processus en analysant le fichier `AndroidManifest.xml`
contenu dans l'APK.
```bash
> jadx mission-impossible.apk 
```
```txt
INFO  - loading ...
INFO  - processing ...
INFO  - done
```

Le résultat est un dossier `mission-impossible` contenant la structure d'un
projet Android entièrement recompilable.
```bash
> tree -L 2 mission-impossible
```
```txt
mission-impossible
├── resources
│   ├── AndroidManifest.xml
│   ├── assets
│   ├── classes2.dex
│   ├── classes3.dex
│   ├── classes.dex
│   ├── META-INF
│   └── res
└── sources
    ├── android
    ├── androidx
    ├── com
    └── thcon21

9 directories, 4 files
```

Nous savons que les flags du CTF auront le format `THCon21{...}`. Le premier réflexe est
alors de chercher le format du flag dans l'arborescence de fichiers :
```bash
> grep -r THCon21 mission-impossible/
```
```txt
grep: mission-impossible/resources/assets/MissionImpossibleTheme.mp3: binary file matches
```

Un seul match dans la totalité du code correspond au format du flag et il se
trouve dans le fichier mp3. Hourra ? La commande `strings` nous permettra
d'extraire ce qui semble être le flag :
```bash
> strings MissionImpossibleTheme.mp3 | grep THCon21                
```
```txt
THCon21{DUMMY-SEARCH-MORE}
```

Malheureusement, la célébration était un peu prématurée. Cependant, le fichier ne
semble pas contenir qu'une piste audio. Listons un peu le texte qui se trouve
autour de notre pseudo-flag.
```bash
> strings MissionImpossibleTheme.mp3 | grep -A 10 -B 10 THCon21
```
```txt
(Ljavax/crypto/IllegalBlockSizeException;
%Ljavax/crypto/NoSuchPaddingException;
$Ljavax/crypto/spec/GCMParameterSpec;
!Ljavax/crypto/spec/SecretKeySpec;
Lthcon21/ctf/payload/MIRead;
Lthcon21/ctf/payload/smalldex;
MIRead.java
MMcjCaXX2AAY20H
MissionImpossible
R3JlZXR6RnJvbUNyeXB0YXgK
THCon21{DUMMY-SEARCH-MORE}
UTF-8
VEhDb24yMQo=
VILL
[Ljava/lang/String;
append
args
cipher
ciphertext
d0_you_acc3pt_it
decode
```

Les chaînes parlent de Java, de cryptographie et de ciphertext. Il semble donc
que l'on ait du code compilé dans le fichier mp3. Malheureusement, l'outil
`binwalk` ne détecte aucune signature spécifique sur le fichier :
```bash
> binwalk MissionImpossibleTheme.mp3
```
```txt
DECIMAL       HEXADECIMAL     DESCRIPTION
--------------------------------------------------------------------------------

```

Il va donc falloir y aller à la main pour extraire ce code. On ouvre le fichier mp3 avec Vim et on entre la
commande `:%!xxd` pour l'éditer au format hexadécimal. On se rend rapidement
compte que la piste contient bien du bytecode avec une signature qui commence
par `.dex`, le tout encadré par des nullbytes :

![Recherche des addresses de début et de fin du code](/assets/2021-06-29/hexa.gif)

On note donc les octets de début et de fin de la séquence :
```bash
0x0032d770 => 3331952
0x0032e580 => 3335552
```

La taille de la zone qui nous concerne est de `3335552 - 3331952 = 3600` octets. La commande
`dd` va nous permettre d'extraire cette partie du binaire :
```bash
> dd bs=1 skip=3331952 count=3600 if=MissionImpossibleTheme.mp3 of=out.bin
```
```txt
3600+0 records in
3600+0 records out
3600 bytes (3.6 kB, 3.5 KiB) copied, 0.0297562 s, 121 kB/s
```

La commande file va nous permettre de savoir à quel type de fichier nous avons à
faire :
```bash
> file out.bin
```
```txt
out.bin: Dalvik dex file version 035
```

Nous voilà donc face à un fichier "Dalvik". C'est une forme de bytecode Java que
l'on retrouve au sein des APK. Après un peu de recherches, nous avons découvert
l'outil `dexdump` qui permet d'extraire des informations sur la structure du
fichier dex.
```bash
> dexdump out.bin
```
```txt
Processing 'out.bin'...
dexdump E 06-19 13:36:32  1634  1634 dexdump.cc:1884] Failure to verify dex file 'out.bin': Bad file size (3600, expected 3616)
```

Le format Dalvik supporte une forme de contrôle d'intégrité qui permet à dexdump
de nous indiquer que 16 octets sont manquants au fichier. Il nous suffit
simplement de réutiliser `dd` en mettant à jour nos options pour extraire le code avec la
partie manquante cette fois-ci.
```bash
> dd bs=1 skip=3331952 count=3616 if=MissionImpossibleTheme.mp3 of=out.dex
```
```txt
3616+0 records in
3616+0 records out
3616 bytes (3.6 kB, 3.5 KiB) copied, 0.0103355 s, 350 kB/s
```

Maintenant, `dexdump` est en mesure de lire le fichier en entier et nous donne
les informations suivantes :
```bash
> dexdump out.dex
```
```txt
Processing 'out.dex'...
Opened 'out.dex', DEX version '035'
Class #0            -
  Class descriptor  : 'Lthcon21/ctf/payload/MIRead;'
  Access flags      : 0x0001 (PUBLIC)
  Superclass        : 'Ljava/lang/Object;'
  Interfaces        -
  Static fields     -
    #0              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'CIPHER_ALGO'
      type          : 'Ljava/lang/String;'
      access        : 0x001a (PRIVATE STATIC FINAL)
      value         : "AES/GCM/NoPadding"                             # (1)
    #1              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'IV'
      type          : 'Ljava/lang/String;'
      access        : 0x001a (PRIVATE STATIC FINAL)
      value         : "your_m1ssi0n"                                  # (2)
    #2              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'KEY'
      type          : 'Ljava/lang/String;'
      access        : 0x001a (PRIVATE STATIC FINAL)
      value         : "d0_you_acc3pt_it"                              # (3)
  Instance fields   -
    #0              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'cipher'                                        # (4)
      type          : 'Ljavax/crypto/Cipher;'
      access        : 0x0002 (PRIVATE)
    #1              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'parameterSpec'
      type          : 'Ljavax/crypto/spec/GCMParameterSpec;'
      access        : 0x0002 (PRIVATE)
    #2              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'secretKeySpec'
      type          : 'Ljavax/crypto/spec/SecretKeySpec;'
      access        : 0x0002 (PRIVATE)
  Direct methods    -
    #0              : (in Lthcon21/ctf/payload/MIRead;)
      name          : '<init>'
      type          : '()V'
      access        : 0x10001 (PUBLIC CONSTRUCTOR)
      code          -
      registers     : 5
      ins           : 1
      outs          : 3
      insns size    : 44 16-bit code units
      catches       : (none)
      positions     : 
        0x0000 line=26
        0x0003 line=27
        0x0014 line=28
        0x001c line=29
        0x002b line=30
      locals        : 
        0x0000 - 0x002c reg=4 this Lthcon21/ctf/payload/MIRead; 
  Virtual methods   -
    #0              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'decrypt'                                       # (5)
      type          : '(Ljava/lang/String;)Ljava/lang/String;'
      access        : 0x0001 (PUBLIC)
      code          -
      registers     : 7
      ins           : 2
      outs          : 4
      insns size    : 33 16-bit code units
      catches       : (none)
      positions     : 
        0x0000 line=39
        0x000b line=40
        0x0015 line=41
        0x001b line=42
      locals        : 
        0x000b - 0x0021 reg=0 valueDecoded [B 
        0x001b - 0x0021 reg=1 plaintext [B 
        0x0000 - 0x0021 reg=5 this Lthcon21/ctf/payload/MIRead; 
        0x0000 - 0x0021 reg=6 ciphertext Ljava/lang/String; 
    #1              : (in Lthcon21/ctf/payload/MIRead;)
      name          : 'encrypt'                                       # (6)
      type          : '(Ljava/lang/String;)Ljava/lang/String;'
      access        : 0x0001 (PUBLIC)
      code          -
      registers     : 6
      ins           : 2
      outs          : 4
      insns size    : 33 16-bit code units
      catches       : (none)
      positions     : 
        0x0000 line=32
        0x000a line=33
        0x0016 line=34
      locals        : 
        0x0016 - 0x0021 reg=0 encryptedBytes [B 
        0x0000 - 0x0021 reg=4 this Lthcon21/ctf/payload/MIRead; 
        0x0000 - 0x0021 reg=5 plaintext Ljava/lang/String; 
  source_file_idx   : 36 (MIRead.java)

Class #1            -
  Class descriptor  : 'Lthcon21/ctf/payload/smalldex;'
  Access flags      : 0x0001 (PUBLIC)
  Superclass        : 'Ljava/lang/Object;'
  Interfaces        -
  Static fields     -
  Instance fields   -
  Direct methods    -
    #0              : (in Lthcon21/ctf/payload/smalldex;)
      name          : 'main'
      type          : '([Ljava/lang/String;)V'
      access        : 0x0009 (PUBLIC STATIC)
      code          -
      registers     : 8
      ins           : 1
      outs          : 2
      insns size    : 58 16-bit code units
      catches       : (none)
      positions     : 
      locals        : 
        0x0000 - 0x003a reg=7 args [Ljava/lang/String; 
    #1              : (in Lthcon21/ctf/payload/smalldex;)
      name          : 'testFlag'
      type          : '()V'
      access        : 0x0009 (PUBLIC STATIC)
      code          -
      registers     : 7
      ins           : 0
      outs          : 2
      insns size    : 81 16-bit code units
      catches       : 1
        0x0005 - 0x0038
          Ljavax/crypto/NoSuchPaddingException; -> 0x004b
          Ljava/security/NoSuchAlgorithmException; -> 0x0046
          Ljava/security/InvalidAlgorithmParameterException; -> 0x0044
          Ljava/security/InvalidKeyException; -> 0x0042
          Ljava/io/UnsupportedEncodingException; -> 0x003d
          Ljavax/crypto/BadPaddingException; -> 0x003b
          Ljavax/crypto/IllegalBlockSizeException; -> 0x0039
      positions     : 
      locals        : 
        0x000f - 0x0039 reg=3 encrypted Ljava/lang/String; 
        0x0013 - 0x0039 reg=4 decrypted Ljava/lang/String; 
        0x003e - 0x0042 reg=0 e Ljava/lang/Exception; 
        0x0047 - 0x004a reg=0 e Ljava/security/GeneralSecurityException; 
        0x004c - 0x004f reg=0 e Ljavax/crypto/NoSuchPaddingException; 
        0x0004 - 0x0051 reg=1 dummyFlag Ljava/lang/String; 
        0x0005 - 0x0051 reg=2 mission Lthcon21/ctf/payload/MIRead; 
  Virtual methods   -
  source_file_idx   : -1 (unknown)
```

La sortie de `dexdump` est très riche en informations sur les classes Java
d'origine du binaire. Nous sommes bien en présence d'un code manipulant de la
cryptographie et beaucoup d'informations utiles sont alors accessibles :

* CIPHER_ALGO: AES/GCM/NoPadding (`1`)
* IV: your_m1ssi0n (`2`)
* KEY: d0_you_acc3pt_it (`3`)

Nous sommes en possession de la clef et du vecteur d'initialisation d'AES. Nous
sommes donc en mesure de déchiffrer toutes données que cet algorithme aurait
traité. Malheureusement, nous n'avons pour l'instant pas de donnée à déchiffrer
et le champ `cipher` (`4`) de la classe n'est pas accessible par dexdump.

Pour aller plus loin nous allons devoir utiliser à nouveau l'outil `jadx` pour
retrouver le code Java à partir de notre fichier Dalvik.
```bash
> jadx out.dex
```
```txt
INFO  - loading ...
INFO  - processing ...
INFO  - done
```

Jadx génère une arborescence et fait apparaître les deux classes que dexdump
avait déjà détecté.
```bash
> tree .  
```
```txt
.
├── out
│   └── sources
│       └── thcon21
│           └── ctf
│               └── payload
│                   ├── MIRead.java
│                   └── smalldex.java
└── out.dex
```

La fonction `main` de `smalldex.java` est très intéressante. Elle utilise des
techniques d'obfuscation pour construire une chaîne de caractères qui semble
être encodée en base64 sans laisser fuiter de façon évidente la donnée dans le
binaire.
```bash
> cat out/sources/thcon21/ctf/payload/smalldex.java | grep -A 18 main
```
```java
public static void main(String[] args) {
    testFlag();
    String str = args[0];
    do {
    } while (0 != 0);
    StringBuilder sb = new StringBuilder();
    sb.append("IkUegPuai+gfBce7nTf");
    if ("IkUegPuai+gfBce7nTf" != "VEhDb24yMQo=") {
        sb.append("CkMZzZSwne3X3mnyrc5oBcD2yGHUXy");
        sb.append("MMcjCaXX2AAY20H");
        String sb2 = sb.toString();
        if (str.equals("MissionImpossible")) {
            System.out.println(sb2);
            return;
        }
        return;
    }
    sb.append("MissionImpossible");
}
```

Sans prendre beaucoup de risque, nous pouvons partir du principe que le
ciphertext est notre chaîne résultante :

```txt
IkUegPuai+gfBce7nTfCkMZzZSwne3X3mnyrc5oBcD2yGHUXyMMcjCaXX2AAY20H
```

Il ne reste plus qu'à déchiffrer ce ciphertext avec les informations que l'on a
récupéré sur le reste du code. Pour cela, il y a deux méthodes.

## Fin alternative 1

On utilise les informations récupérées jusqu'ici pour déchiffrer le ciphertext à
l'aide de python :
```python
from Crypto.Cipher import AES
from base64 import b64decode

key = b'd0_you_acc3pt_it'
iv = b'your_m1ssi0n'

ciphertext = b64decode('IkUegPuai+gfBce7nTfCkMZzZSwne3X3mnyrc5oBcD2yGHUXyMMcjCaXX2AAY20H')
print(AES.new(key, AES.MODE_GCM, iv).decrypt(ciphertext))
```
```python
b'THCon21{Th1s-Was-Poss1ble-For-U}\x8c\x0c\xdab\xbc\x92\x13V\xee5m\xa0\xfeE}c'
```

## Fin alternative 2

On s'inspire du code java extrait du fichier Dalvik pour créer une classe qui
permet de déchiffrer le ciphertext :
```java
import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.util.Base64;


public class Main 
{
  private static final String CIPHER_ALGO = "AES/GCM/NoPadding";
  private static final String IV = "your_m1ssi0n";
  private static final String KEY = "d0_you_acc3pt_it";


  public static void main(String[] args)  {
    try {
      Main programm = new Main();
      System.out.println(programm.decrypt("IkUegPuai+gfBce7nTfCkMZzZSwne3X3mnyrc5oBcD2yGHUXyMMcjCaXX2AAY20H"));
    } catch (Exception e) {}
  }

  public String decrypt(String str) throws Exception{
    Base64.Decoder dec = Base64.getDecoder();
    byte[] decode = dec.decode(str.getBytes("UTF-8"));
    GCMParameterSpec parameterSpec = new GCMParameterSpec(128, IV.getBytes("utf-8"));
    SecretKeySpec secretKeySpec = new SecretKeySpec(KEY.getBytes("utf-8"), "AES");
    Cipher cipher = Cipher.getInstance(CIPHER_ALGO);
    cipher.init(2, secretKeySpec, parameterSpec);
    return new String(cipher.doFinal(decode));
  }
}
```

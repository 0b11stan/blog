# Share a folder between Windows host and GNU/Linux guest (hyperv)

guest: arch linux
host: windows 10

sources :
* https://dzone.com/articles/install-arch-linux-on-windows-10-hyper-v
* https://unix.stackexchange.com/questions/124342/mount-error-13-permission-denied
* https://wiki.archlinux.org/title/Hyper-V

## On Windows host

1. Right click on folder
2. clic on properties
3. clic sur "Partage"
4. clic sur "Partage avancé..."
5. cocher "Partager ce dossier"
6. clic sur "Appliquer"
7. voir sur l'onglet "Sécurité" pour configurer les droits

## On GNU/Linux guest

You will need some infos

```bash
WINDOWS_HOSTNAME=
HOST_MOUNTPOINT=
GUEST_MOUNTPOINT=
CREDENTIALS_FILE_PATH=
HOST_USER=
HOST_PASS=
HOST_DOMAIN=
```

Install required packages

```bash
sudo pacman -S cifs-utils smbclient
```

Create an empty configuration file for samba

```bash
sudo mkdir -p /etc/samba/ && touch /etc/samba/smb.conf
```

Enregistrer les credentials dans le fichier de conf:

```bash
cat > $CREDENTIALS_FILE_PATH <<EOF
username=$HOST_USER
password=$HOST_PASS
domain=$HOST_DOMAIN
EOF
```

Monter le dossier:

```bash
sudo mount -t cifs "//$WINDOWS_HOSTNAME/$HOST_MOUNTPOINT" "$GUEST_MOUNTPOINT" \
  -o credentials=$CREDENTIALS_FILE_PATH,ip=$(nmblookup $WINDOWS_HOSTNAME | head -n 1 cut -d ' ' -f 1)
```

# Install Metasploit On archlinux

[Archlinux's wiki on Metasploit](https://wiki.archlinux.org/title/Metasploit_Framework)
is outdated for the "Installation" part, here is a simpler guide to install
metasploit and use it's database:

First install metasploit and postgresql

```bash
sudo pacman -S metasploit postgresql
```

Then, init and configure postgres as described in [the wiki](https://wiki.archlinux.org/title/PostgreSQL).

```bash
sudo -u postgres -- initdb -D /var/lib/postgres/data
sudo systemctl start postgresql
```

You can now init your msf database:

```bash
msfdb --connection-string postgresql://postgres:@localhost:5432/postgres init
```

Test that everything worked well:

```text
> msfconsole -q
msf6 > db_status
[*] Connected to msf. Connection type: postgresql.
```

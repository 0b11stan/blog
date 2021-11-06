# Network Scanning

## NMAP

Principaux arguments:

* `-sV`: détermine la version der services qui tournent
* `-p PORT | -p-RANGE`: scan un port ou une range de port spécifiques
* `-Pn`: désactive la découverte des hotes et se contente de scanner les ports
         (cool pour éviter de la charge, gagner du temps, ...)
* `-A`: "agressif" tente de découvrir la version et le type du système d'exploitation
* `-sC`: utilise les script par défaut
* `-v`: verbose
* `-sU`: scan UDP
* `-sS`: TCP SYN scan

toujous sauvegarder avec un `-oN` _output normal_ (ou `-oG` pour _output
greppable_) au cas ou on à besoin de revenir sur le scan

on fait un file sur le binaire pour voir que c'est du dalvik donc on se renseigne

on essaie de faire un dexdump du fichier poru récupérer les infos mais ça passe pas

(+16 octets manquants )

dd bs=1 skip=3331952 count=3616 if=MissionImpossibleTheme.mp3 of=out.dex

la le dexdump est passé et nous montre plein d'infos sur la classe java

Depuis le .dex --> avec 'enjarify' j'ai généré un .jar

Depuis le .jar --> avec jadx  j'ai décompilé pour récupérer les deux fichiers .java

on comprend comment le ciphertext est généré (Stringbuilder)

== FIN ALTERNATIVE 1

on récupère les infos de dexdump + le ciphertext et on écrit l'algo de déchifrfrement en python

== FIN ALTERNATIVE 2

on compile les infos des deux classes java pour en créer une valide qui permet d'appeler les infos et décrypt le ciphertext

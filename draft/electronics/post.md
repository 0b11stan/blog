# Tips & Tricks & Knowledges : Electronique

<p style="text-align: right">_- last update 17/09/2021 -_</p>

#### Ce qu'il faut avoir

* [ ] batterie
* [ ] resistance
* [ ] LED
* [ ] batteries holders (emplacement pour piles)
* [ ] pinces coupantes
* [ ] quelques switch (on/off)
* [ ] push buttons
* [ ] un grand breadboard
* [ ] des files (précoupés si possible)

pour acheter :

* bricorama ?
* https://jclelectrome.fr/
* amazon ?

## Ressources

* [beginner electronics, 31 ep](https://www.youtube.com/watch?v=r-X9coYTOV4&list=PLah6faXAgguOeMUIxS22ZU4w5nDvCl5gs&index=1)
* [poster cheat sheet](https://tinkrlearnr.com/wp/wp-content/uploads/2015/07/Fundamentals-v1p6-01.png)

a tester:

* https://www.nutsvolts.com/magazine/article/microcontrollers_are_great

autre:

* [from web dev to elec hobbyist](https://collapseos.org/skills.html)
* [nutsvolts.com](https://www.nutsvolts.com/)
* [learn hox to repare](https://www.repairfaq.org/REPAIR/F_tshoot.html)
* [grosse banque de données](https://www.repairfaq.org/)
* [collapseos](https://collapseos.org/)

## Connaissances

### Courant Alternatif

ce qu'on trouve sur les prises murales

les gros trucs (frigo, télé, ...)

peut être transformé en courant direct

le courant change très régulièrement de sens 

### Courant Direct

ce que l'on trouve à la sortie des batteries / piles

les petits trucs (telephone, ordi, ...)

pour l'electronique il faut souvent ça

le courant va toujours dans le même sens

### Circuit

**attention** il y à deux sens: le sens des électrons (- vers +) et le sens
conventionel du courant (+ vers -)

anode : le courant entre (sens conventionel)
cathode : le courant sort(sens conventionel)

ouvert : il n'y à pas de chemin qui va du point négatif au positif

fermé : forme un chemin du pole négatif au positif

l'electricité c'est juste le déplacement d'électrons dans le materiau

voltage (volts) (v): est un peu comme la pression de l'eau, pression des electrons
dans le fil

courant (amperes) (amps) (I) : combient d'electrons sont poussés à travers le fil,
un peut comme le débit de l'eau

resistance (ohms) : c'est un peut comme mesurer la différence de "taille" des
tuyaux pour de l'eau, c'est dirrectement lié avec le débit (courant) et dans le 
cas de l'electricité c'est le type de materiel qui joue sur la résitance

ohm's law:
V = IR 

Power (watts) = V * I

### Schémas

dans le schéma de l'alim :

* grande barre : borne positive
* petite barre : borne négative

### Components

#### Resistor

1 ohm
1 kohm -> 1 000 ohms
1 mohm -> 1 000 000 ohms

Il y à un code couleur pour savoir combien il y à de résistance sur un résistor

color chart : https://codenmore.github.io/resources/resistorcodes.html

première bande (b1) : premier chiffre
deuxième bande (b2) : deuxième chiffre
troisième bande (b3) : multiplier
quatrieme bande (b4) : tolerance

on calcule la résistance comme ça :

( b1*10 + b2) * b3 [+ ou - b4%]

Comment je sais si j'ai besoin d'une résistance et quelle résistance il me
faut ?

pour ça il faut les infos suivante:

* voltage (vsrc) de la source d'électricité
* Forward Voltage du composant (cfv) > sur la fiche technique du fournisseur
* Combien d'amperes le composant utilise (cma) > sur la fiche technique du fournisseur

Ensuite on peut calculer la résistance nécessaire :

R = (vsrc - cfv) / cma

**Attention, cma c'est en amperes et pas en mA ou autre**

C'est pas grave si on à pas de résistance qui fait exactement R, on peut mettre
plus sans danger et moins en s'approchant le plus possible

on peut mettre les resistances avant ou après les composants, il faut juste qu'il
soit sur la route

#### LED

Light-Emitting Diode

elles ont quasiment toujours besoin d'une résistance devant sinon elles vont
êtres grillés

Il y à deux branches :

* la plus longue s'appelle l'anode et doit être branchée a la borne positive du circuit
* la plus courte s'appelle la cathode et doit être branchée a la borne negative du circuit

#### Breadboard

les parties exterieurs du board sont les "power rails", on y place la source
d'énergie

les lignes y sont connecté mais pas les collones 

dans la partie centrale du board est divisée en 2 parties, ces deux parties sont
isolée l'une de l'autre mais au sein de chacune, les colones qui sont connecté

#### Multimettre

calcule des valeurs entre deux points du circuit

il faut un multimettre qui s'auto-configure parceque sinon c'est chiant

pour calculer les amperes (le courant) il faut que le multimettre face parti du
circuit (branché en série)

pour le voltage et la résistance on peut le mettre en dérivation (sur le poles
qu'on veu tester

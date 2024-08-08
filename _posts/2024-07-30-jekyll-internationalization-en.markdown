---
title: Internationalisation d'un site Jekyll (minima)
lang: en
ref: jekyll-internationalization
---

Cet article est principalement mon adaptation de "[Making Jekyll multilingual](https://sylvaindurand.org/making-jekyll-multilingual/)" pour le theme [minima](https://github.com/jekyll/minima) donc merci à Sylvain Durand pour son article !

Je ne reviens pas sur les conceptes de bases de jekyll mais je mettrais des liens vers [la documentation techniques](https://jekyllrb.com/docs/) qui est complète et très bien faite.
Le moteur de templating utilisé par jekyll est [liquid](https://github.com/Shopify/liquid), sa syntaxe est simple mais un tour sur la doc peut être également nécessaire pour comprendre certaines parties.


## Ajout d'un switch sur les postes & pages

Jekyll utilise les block [front matter](https://jekyllrb.com/docs/front-matter/) pour renseigner des métadonnées sur le contenu.
Certain attributs sont propre à jekyll comme `layout` ou `title` pour renseigner le titre de la page, mais nous pouvons aussi ajouter les notres.
On va donc s'en servir pour renseigner la langue de chaque article dans un attribut `lang`.
Un autre attribut `ref` nous permettra de signifier quels fichiers markdown sont des traductions d'un même article.

Par exemple, pour la page actuelle, mon block front matter contient les attributs suivants.

```yaml
lang: fr
ref: jekyll-internationalization
```

Pour ajouter notre switch, il faudra modifier le [layout](https://github.com/jekyll/minima) du thème.
Attention, sur jekyll il y à une différence entre un "poste" (ce sont les articles qui sont en général datés et consituent le contenu principale) et une "page" (par exemple la page *about* en haut a droite); les layouts sont donc différents.

Pour éviter de répéter du code dans les 2 layouts, utilisons un [include](https://jekyllrb.com/docs/includes/) avec comme argument la liste de tous les postes ou pages.
Il peut être ajouté à votre convenance au début du fichier `_layouts/post.html` et `_layouts/page.html`.

```liquid
<!-- pour _layouts/post.html -->
{% raw %}{%- include switcher.html target=site.posts -%}{% endraw %}

<!-- pour _layouts/page.html -->
{% raw %}{%- include switcher.html target=site.pages -%}{% endraw %}
```

On va maintenant utiliser les attributs définis plus haut dans le contenu du fichier `_includes/switcher.html`.

```liquid
{% raw %}<div>
    {% assign items=include.target | where:"ref", page.ref | sort: 'lang' %}
    {% for item in items %}
        {%- if item.lang != page.lang -%}
            <a class="lang-flag" href="{{ item.url }}">
                <img width=50 src="/assets/base/{{ item.lang }}.svg" />
            </a>
        {%- endif -%}
    {% endfor %}
</div>{% endraw %}
```

Ce bout de code va selectionner tous les postes qui ont la même référence (`ref`) que le poste actuel et pour chaque nouvelle langue, il va générer un drapeau cliquable.
Les images des drapeaux ont été récupéré sur l'excellent site [flagicons](https://flagicons.lipis.dev/).

Un petit peu de CSS pour l'intégrer au reste du blog et le tour est joué

```css
.lang-flag { position: static; float: right; margin-left: 10px; }
.lang-flag img { border: solid #fff 2px; border-radius: 6px; }
```

Il est maintenant possible de créer 2 postes, par exemple `test-en.md` et `test-fr.md` avec le même attribut `ref` et une `lang` différente pour vérifier que la solution fonctionne, YAY !

Malheureusement, en se rendant sur la homepage, on se rend compte que le template minima n'a pas consicence de notre attribut `ref` et nous présente l'article en double... attaquons nous à ce problème.

## Correction de la homepage

Le layout pour la homepage se trouve dans `_layouts/home.html`.
Pour mieux comprendre, voici un diff des modification par rapport à la page par défaut.

```diff
{% raw %}16c16,17
<         {%- for post in site.posts -%}
---
>         {%- assign refs = site.posts | map: "ref" | uniq -%}
>         {%- for ref in refs -%}
17a19,27
>             {%- assign posts = site.posts | where: "ref", ref -%}
>             {%- assign languages = posts | map: "lang" -%}
>
>             {%- if languages contains "en" -%}
>             {%- assign post = posts | where: "lang", "en" | first -%}
>             {%- else -%}
>             {%- assign post = posts | first -%}
>             {%- endif -%}{% endraw %}
```

Plutôt que d'itérer dans la liste des postes comme le fait le code de base, on préfèrera itérer dans la liste des rérérences uniques.
Le reste n'est qu'un peu de logique pour privilégier l'anglais lorsque la langue est disponible.

## Ajout d'un indicateur de langues disponibles

Toujours sur notre homepage, il serait utile d'indiquer les langues disponibles à chaque poste pour faciliter la navigation.
Pour cela, on peut s'inspirer du switch réalisé plus haut et ajouter autant de drapeau cliquable qu'il y à de langue disponible pour chaque référence.

```liquid
{% raw %}<div class="post-lang">
    {% for lang in languages %}
        {%- assign post = posts | where: "lang", lang | first -%}
        <a class="lang-flag" href="{{ post.url | relative_url }}">
            <img width=30 src="/assets/base/{{ lang }}.svg" />
        </a>
    {% endfor %}
</div>{% endraw %}
```

Enfin il reste à ajouter un peu de CSS pour que notre drapeau rende correctement sur chaque élément de notre liste de poste.

```css
.post-list .post-meta { display: block; }
.post-list h3         { display: inline-block; }
.post-list .post-lang { display: inline; }
```

## Wrapup

S'il vous manque du contexte pour comprendre comment les différents éléments interagissent entre eux, vous trouverez ces explications mises en pratique sur le github de ce blog : [github.com/0b11stan/0b11stan.github.io](https://github.com/0b11stan/0b11stan.github.io/blob/3a99bb3f13e22e8ec68d3380d94a87260df01cac/_layouts/home.html).

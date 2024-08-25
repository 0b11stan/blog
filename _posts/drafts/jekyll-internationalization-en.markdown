---
title: Jekyll website internationalization (minima)
lang: en
ref: jekyll-internationalization
---

This article is mainly my adaptation of "[Making Jekyll multilingual](https://sylvaindurand.org/making-jekyll-multilingual/)" for the [minima](https://github.com/jekyll/minima) theme, so thanks to Sylvain Durand for his article!

I won't go back over the basic concepts of jekyll, but I will link to the [technical documentation](https://jekyllrb.com/docs/), which is complete and very well done.
The templating engine used by jekyll is [liquid](https://github.com/Shopify/liquid), its syntax is simple but a look at the documentation may also be necessary to understand certain parts.

## Adding a switch to posts & pages

Jekyll uses [front matter](https://jekyllrb.com/docs/front-matter/) blocks to fill in content metadata.
Certain attributes are specific to Jekyll, such as `layout` or `title`, but we can also add our own.
We're going to use them to enter the language of each article in a `lang` attribute.
Another `ref` attribute will allow us to indicate which Markdown files are translations of the same article.

For example, for the current page, the front matter block contains the following attributes.

```yaml
lang: fr
ref: jekyll-internationalization
```

To add our switch, we'll need to modify the theme's [layout](https://github.com/jekyll/minima).
Please note that on jekyll, there's a difference between a "post" (articles, which are generally dated and constitute the main content) and a "page" (for example, the *about* page in the top right-hand corner); the layouts are therefore different.

To avoid repeating code in the 2 layouts, let's use an [include](https://jekyllrb.com/docs/includes/) with the list of all posts or pages as argument.
This can be added at the beginning of `_layouts/post.html` and `_layouts/page.html`.

```liquid
<!-- pour _layouts/post.html -->
{% raw %}{%- include switcher.html target=site.posts -%}{% endraw %}

<!-- pour _layouts/page.html -->
{% raw %}{%- include switcher.html target=site.pages -%}{% endraw %}
```

We're now going to use the attributes defined above in the contents of `_includes/switcher.html`.

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

This piece of code will select all posts that have the same reference (`ref`) as the current post, and for each new language, it will generate a clickable flag.
The flag images have been taken from the excellent [flagicons](https://flagicons.lipis.dev/) site.

A little bit of CSS to integrate it with the rest of the blog and you're done.

```css
.lang-flag { position: static; float: right; margin-left: 10px; }
.lang-flag img { border: solid #fff 2px; border-radius: 6px; }
```

It is now possible to create 2 posts, for example `test-en.md` and `test-fr.md` with the same `ref` attribute and a different `lang` to check that the solution works, YAY!

Unfortunately, when we go to the homepage, we realize that the template minima doesn't take our `ref` attribute into account and presents us with a duplicate article... let's tackle this problem.

## Correcting the homepage

The layout for the homepage can be found in `_layouts/home.html`.
For a better understanding, here's a diff of the changes from the default page.

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

Rather than iterate through the list of items as the original code does, we prefer to iterate through the list of unique references.
The rest is just a bit of logic to give preference to English when the language is available.

## Available languages indicator

Still on our homepage, it would be useful to indicate available languages for each item to facilitate navigation.
To do this, we can take our inspiration from the switch above and add as many clickable flags as there are languages available for each reference.

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

Finally, we need to add a little CSS so that our flag renders correctly on each item in our post list.

```css
.post-list .post-meta { display: block; }
.post-list h3         { display: inline-block; }
.post-list .post-lang { display: inline; }
```

## Wrapup

If you're lacking the context to understand how the various elements interact, you'll find these explanations put into practice on this blog's github: [github.com/0b11stan/blog](https://github.com/0b11stan/blog).

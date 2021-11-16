# blog.tic.sh

This is my own little handcrafted blog using only markdown, pandoc and shell 
utilities. It's quite minimalistic but I like it this way. It's somewhat of a 
[suckless](https://suckless.org/) kind of website. If you think that it sucks
anyway, please, reach out to me I'll be glad to know how to make it suck less.

To build the blog for developement:

```bash
make www
podman build -t blog .
podman run --rm -d -p 8000:80 -v $(pwd)/www:/srv/www/ blog
```

Then go to http://localhost:8000/

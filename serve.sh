podman build -t blog .

podman run \
  --rm -it \
  --volume $PWD:/srv/ \
  --publish 4000:4000 blog \
  jekyll serve --host 0.0.0.0

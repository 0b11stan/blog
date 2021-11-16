#!/bin/bash

outdir=$1

for path in $(find posts -name '*.md'); do

  mkdir -p $outdir/$(echo $path | cut -d '/' -f '2-' | xargs -n 1 dirname)

  pandoc $path --standalone \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --include-before-body="templates/post.html" \
    --css="/style.css" \
    --data-dir="$(dirname $path)" \
    --output="$outdir/$(echo $path | cut -d '/' -f '2-' | sed 's/md$/html/')"

  cp templates/style.css $outdir

done

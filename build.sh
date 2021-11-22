#!/bin/bash

outdir=$1

cp -r posts/* $outdir

for path in $(find $outdir -name '*.md'); do

  echo "build $path..."
  pandoc $path --standalone --toc \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --include-before-body="templates/post.html" \
    --css="/style.css" \
    --data-dir="$(dirname $path)" \
    --output="$outdir/$(echo $path | cut -d '/' -f '2-' | sed 's/md$/html/')"

  cp templates/style.css $outdir

done

#!/bin/bash

outdir=www

rm -r $outdir && mkdir $outdir
echo '# Articles' > posts/index.md

for post in $(ls -p posts | grep '/$' | tr -d '/'); do

  pandoc posts/$post/post.md --standalone \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --css="/style.css" \
    --data-dir="posts/$post" \
    --output="$outdir/$post.html"

  mkdir -p $outdir/static/$post
  cp templates/style.css $outdir
  echo "- [$post](./$post.html)" >> posts/index.md

  # copy only files that are linked in the post
  static_files=$(sed -n 's!.*\[[^\[]*](./\([^(]*\))!\1!p' posts/$post/post.md)
  for file in $static_files; do cp posts/$post/$file $outdir/static/$post/; done

  # replace all internal html links with `./myfile.ext` to `/static/mypost/myfile.ext`
  sed -i "s!\(href\|src\)=\"\./\([^\"]*\)\"!\1=\"/static/$post/\2\"!" $outdir/$post.html
done

pandoc posts/index.md -s -H templates/header.html -c /style.css -o $outdir/index.html

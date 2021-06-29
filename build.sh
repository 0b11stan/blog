#!/bin/bash

outdir=www

rm -r $outdir
mkdir $outdir
cp templates/index.html $outdir/index.html

for post in $(ls posts); do
  pandoc posts/$post/post.md --standalone \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --css="/style.css" \
    --data-dir="posts/$post" \
    --output="$outdir/$post.html"
  mkdir -p $outdir/static/$post
  # find all local files that are linked in the post
  static_files=$(sed -n 's!.*\[[^\[]*](./\([^(]*\))!\1!p' posts/$post/post.md)
  for file in $static_files; do cp posts/$post/$file $outdir/static/$post/; done
  cp templates/style.css $outdir
  # replace all internal html links with `./myfile.ext` to `/static/mypost/myfile.ext`
  sed -i "s!\(href\|src\)=\"\./\([^\"]*\)\"!\1=\"/static/$post/\2\"!" $outdir/$post.html
  echo "<li><a href=\"$post.html\">$post</a></li>" >> $outdir/index.html
done

echo "</ul></body></html>" >> $outdir/index.html

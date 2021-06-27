#!/bin/zsh

outdir=www

rm -r $outdir
mkdir -p $outdir/img
cp templates/index.html $outdir/index.html

for post in $(ls posts); do
  pandoc posts/$post/post.md --standalone \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --css="/style.css" \
    --data-dir="posts/$post" \
    --output="$outdir/$post.html"
  mkdir $outdir/img/$post
  cp posts/$post/*.(jpeg|gif|png|html) $outdir/img/$post
  cp templates/style.css $outdir
  sed -i "s!img src=\".!img src=\"/img/$post/!" $outdir/$post.html 
  echo "<li><a href=\"$post.html\">$post</a></li>" >> $outdir/index.html
done

echo "</ul></body></html>" >> $outdir/index.html

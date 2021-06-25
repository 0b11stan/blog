#!/bin/zsh

rm -r dist
mkdir -p dist/img
cp templates/index.html dist/index.html

for post in $(ls posts); do
  #pushd posts/$post
  pandoc posts/$post/post.md --standalone \
    --highlight-style="breezedark" \
    --include-in-header="templates/header.html" \
    --css="/style.css" \
    --data-dir="posts/$post" \
    --output="dist/$post.html"
  #popd
  mkdir dist/img/$post
  cp posts/$post/*.(jpeg|gif|png|html) dist/img/$post
  cp templates/style.css dist
  sed -i "s!img src=\".!img src=\"/img/$post/!" dist/$post.html 
  echo "<li><a href=\"$post.html\">$post</a></li>" >> dist/index.html
done

echo "</ul></body></html>" >> dist/index.html

#!/bin/bash

rm -r dist

prefix=$(cat templates/post.html)
suffix='</body></html>'


mkdir -p dist/img
cp templates/style.css dist/
cp templates/index.html dist/index.html

for post in $(ls posts); do
  pushd posts/$post
  pandoc post.md -o post.html
  echo "$prefix$(cat post.html)$suffix" > post.html
  popd
  mkdir dist/img/$post
  cp posts/$post/*.jpeg posts/$post/*.gif posts/$post/*.png dist/img/$post
  mv posts/$post/post.html dist/$post.html
  sed -i "s!img src=\".!img src=\"/img/$post/!" dist/$post.html 
  echo "<li><a href=\"$post.html\">$post</a></li>" >> dist/index.html
done

echo "</ul>$suffix" >> dist/index.html


#!/bin/bash

# find the position of the summary
pos=$(grep -n '^#[# ].*Summary' posts/$1/post.md | cut -d ':' -f 1)
if [[ -z "$pos" ]]; then return; fi
((pos = $pos + 2))

# for each title
for title in $(grep '^##[# ]' posts/$1/post.md | grep -v 'Summary' | tr ' ' '_'); do

  # find the title's depth
  title=$(echo $title | tr '_' ' ')
  ((level = $(echo $title | cut -d ' ' -f '1' | wc -c) - 3 ))

  # generate a the markdown text
  title=$(echo $title | cut -d ' ' -f '2-')
  anchor="#$(echo $title | tr -d '()' | tr ' [:upper:]' '-[:lower:]')"
  md="- [$title]($anchor)"

  # generate spaces for title depth
  if [ $level -eq 0 ]; then
    line=$md
  else
    line="$(printf -- ";%${level}s $md" ' ')"
  fi

  # write the summary
  sed -i "${pos}i;$line" posts/$1/post.md
  sed -i "${pos}s/^;[;]*//" posts/$1/post.md
  ((pos = $pos + 1))
done

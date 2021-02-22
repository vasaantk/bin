#! /bin/bash

# Accepts a file name and searches the current dir for the file. If it
# finds the file, it runs aspell on the file.

inp_name=$1
find_file=$(find . -type f -name "$inp_name")
aspell -c --mode=html "$find_file"
backup="$find_file".bak

if [[ -f  "$backup" ]]; then
   ls "$(find . -type f -name "$inp_name")".bak
fi

echo "Spell check complete"

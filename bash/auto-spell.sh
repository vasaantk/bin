#! /bin/bash

inp_name=$1

if [[ -z "$inp_name" ]]; then
    echo '# Accepts a file name and searches the current dir for the file. If it'
    echo '# finds the file, it runs aspell on the file. If corrections are made,'
    echo '# it tells you the name of the .bak file that was produced.'
    echo '#'
    echo '# Usage:'
    echo '#     -->$ autospell.sh input.txt'
else
    find_file=$(find . -type f -name "$inp_name")
    aspell -c --mode=html "$find_file"
    backup="$find_file".bak

    if [[ -f  "$backup" ]]; then
       ls "$(find . -type f -name "$inp_name")".bak
    fi

    echo "Spell check complete"
fi

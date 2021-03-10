#! /bin/bash

USR_DIR=$1

findrep(){
    local funcarg=$1
    local second=false
    for word in $(lynx --dump $funcarg)
    do
        first=$(echo "$word" | tr -s " ")
        # if [[ "$first" == "$second" ]] && [[ "$first" != "|" ]]; then
        if [[ "$first" == "$second" ]]; then
            echo $funcarg '===>' $first $second
        fi
        second=$first
    done
}

if [[ -z "$USR_DIR" ]]; then
    echo '# Accepts either a dir or a single file as an argument. For each html'
    echo '# file (in the dir), it searches for double-words (e.g. " mop mop ").'
    echo '#'
    echo '# Usage:'
    echo '#     -->$ repwor.sh usr_dir'
    echo '#     -->$ repwor.sh usr_file'
else
    if [[ -d $USR_DIR ]]; then
        for INP_FILE in $(find $USR_DIR -type f -name "*.htm")
        do
            findrep $INP_FILE
        done
    else
        find_file=$(find . -type f -name "$USR_DIR")
        findrep "$find_file"
    fi
fi

#! /bin/bash

# repwor.sh accepts either a dir or a single file as an argument. For
# each file (in the dir), it searches for double-words (e.g. " target
# target ").

USR_DIR=$1

findrep(){
    local funcarg=$1
    local second=false
    for word in $(cat $funcarg)
    do
        first=$(echo "$word" | tr -s " ")
        if [ "$first" == "$second" ] ; then
            echo $funcarg '===>' $first $second
        fi
        second=$first
    done
}

if [ -d $USR_DIR ]; then
    for INP_FILE in $(find $USR_DIR -type f -name "*.htm")
    do
        findrep $INP_FILE
    done
else
    findrep $USR_DIR
fi

#! /bin/bash

# A kludge to automatically open the latest version of Echoview 12 on
# my system.

echoVer=-1
cd /mnt/c/Echoview\ 12/
for item in .
do
    if [ -d "$item" ]; then
        for ver in $(ls $item | cut -f 2 -d ' ' | cut -f 3 -d '.')
        do
            if [ "$ver" -gt "$echoVer" ]; then
                echoVer="$ver"
            fi
        done
    fi
done
Echoview\ 12.0.$echoVer*/WIN64_RELEASE/Echoview.exe

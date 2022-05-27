#! /bin/bash

# Delete all but the latest version of Echoview on my system.

source open-echo

echoview_files_dir="/mnt/c/Echoview 13"
echoview_dir_prefix="Echoview 13.0"


main(){
    local ev_files_dir=$1
    local ev_dir_prefix=$2

    latest_ev_version_index=$(get_latest_ev_version "$ev_files_dir" "$ev_dir_prefix")
    latest_echo_dirname=$(get_latest_echo_dirname "$ev_files_dir" "$ev_dir_prefix" "$latest_ev_version_index")
    wipe-echoes "$ev_files_dir" "$ev_dir_prefix" "$latest_echo_dirname"
}


get_latest_echo_dirname(){
    local root_dir=$1
    local ev_dir_prefix=$2
    local latest_version=$3

    basename "$(ls -d "$root_dir"/"$ev_dir_prefix"."$latest_version"*)"
}


wipe-echoes(){
    local root_dir=$1
    local ev_dir_prefix=$2
    local latest_echo_version=$3

    for file in "$root_dir"/*; do
        dirname=$(basename "$(ls -d "$file")")
        if [[ "$dirname" != "$latest_echo_version" ]]; then
            echo "Deleting" "$root_dir"/"$dirname"
            rm -rf "$root_dir"/"$dirname"
        fi
    done
    ls -lahd "$root_dir"/*
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$echoview_files_dir" "$echoview_dir_prefix"
fi

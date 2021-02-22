#! /bin/bash

inp_name=$1
aspell -c "$(find . -type f -name "$inp_name")"
ls "$(find . -type f -name "$inp_name")".bak

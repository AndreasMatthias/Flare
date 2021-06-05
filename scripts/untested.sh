#!/bin/bash

scriptname=$(basename $0)

if [ $# -eq 0 ]; then
    for file in flare*.lua
    do
        $0 $file
    done
    exit
fi

# call this script for each file individually
if [ $# -gt 1 ]; then
    for file in $*
    do
        $0 $file
    done
    exit
fi

# files
file=$(basename $1)
test_files=$(find test/ -regex "test/test-$(basename $file .lua)[0-9]*.lua")

# collect all functions
funcs=$(cat $file | sed -n -e 's/^function \+\([^[:space:](]\+\) *(.*/\1/p')

# check if test functions exist
missing=""
for func in $funcs
do
    found=0
    for test_file in $test_files
    do
        grep "test('$func" $test_file > /dev/null
        if [ $? -eq 0 ]; then
            found=1
            break
        fi
    done
    if [ $found -eq 0 ]; then
        missing="$missing $func"
    fi
done

msg_file="\033[1m$file:\033[0m"
msg_ok="\033[1;32mOk\033[0m"
msg_missing="\033[1;31mmissing tests\033[0m"

# output missing function
echo "-------------------------------------"
if [ "$missing" == "" ]; then
    echo -e "$msg_file $msg_ok"
else
    echo -e "$msg_file $msg_missing"
    for func in $missing
    do
        echo "   $func"
    done
fi

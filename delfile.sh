#########################################################################
# File Name: delfile.sh
# Author: liuxiang
# mail: lxiangb@ankki.com
# Created Time: 2018??05??03?? ?????? 10ʱ43??02??
#########################################################################
#!/bin/bash
#set -x

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 dirname"
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "$1 is not a directory"
    exit 1
fi

delete_directory()
{
    if [[ $# -ne 1 ]]; then
        echo "input para num error"
        exit 1
    elif [[ ! -d $1 ]]; then
        echo "$1 is not a directory"
        exit 1
    fi
    echo "start deleting file"
    local filelist=`ls $1`
    local file=
    cd $1
    for file in $filelist
    do
        if [[ -d $file ]]; then
            cd $file
            echo "start deleting dir $file ..."
            delete_directory $file
            cd ..
            rm -rf $1
        elif [[ -f $file ]]; then
            echo -ne "\rdeleting file $file ..."
            rm -f $file
        fi
    done
    echo "deleting files in $1 successfully"
    cd ..
    rm -rf $1
    echo "deleting directory $1 successfully .."
}

FILELIST=`ls $1`
cd $1
for FILE in $FILELIST
do
    if [[ -d $FILE ]]; then
        echo "deleting dir $FILE ..."
        delete_directory $FILE
    else
        echo -ne "\rdeleting file $FILE"
        rm -f $FILE
    fi
done
cd ..
rm -rf $1
mkdir $1

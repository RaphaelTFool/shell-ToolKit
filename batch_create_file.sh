#########################################################################
# File Name: create_file.sh
# Author: liuxiang
# mail: lxiangb@ankki.com
# Created Time: 2018??05??02?? ?????? 11ʱ30??03??
#########################################################################
#!/bin/bash
#set -x

create_N_files()
{
    if [[ $# -ne 2 ]]; then
        echo "Usage $0 file count."
        exit 1
    else
        expr $2 "+" 10 &> /dev/nul
        if [[ $? -ne 0 ]]; then
            echo "$1 is not a number, exit"
            exit 1
        elif [[ ! -z $1 ]]; then
            touch $1
            if [[ $? -ne 0 ]]; then
                echo "create $1 failed"
                exit 1
            fi
        fi
    fi
    local FILE=
    if [[ $1 = "." ]]; then
        FILE="test"
    else
        FILE=$1
    fi
    local NUM=$2
    local i=0
    echo "create files ..."
    for((i=0; i<${NUM}; i++))
    do
        echo -ne "\r${FILE}_$i"
        touch ${FILE}_$i
    done
    echo ""
    echo "${NUM} files ${FILE} created success"
}

if [[ $# -ne 3 ]]; then
    echo "Usage: $0 Fatherdirectory ChilddirectoryCount[if equal 0, touch file in father directory] fileCount"
    exit 1
fi

if [[ ! -d $1 ]]; then
    echo "$1 not exist, creating it ..."
    mkdir $1
fi
cd $1
DIR_NAME="test"
expr $2 "+" 10 &> /dev/nul
if [[ $? -ne 0 ]]; then
    echo "$2 is not a number, exit"
    exit 1
fi
DIR_NUM=$2
expr $3 "+" 10 &> /dev/nul
if [[ $? -ne 0 ]]; then
    echo "$3 is not a number, exit"
    exit 1
fi
FILE_NUM=$3

echo "starting create files ..."
if [[ ${DIR_NUM} -eq 0 ]]; then
    dir="."
    create_N_files $dir ${FILE_NUM}
fi

for((j=0; j<${DIR_NUM}; j++))
do
    dir=${DIR_NAME}_$j
    if [[ ! -d $dir ]]; then
        mkdir $dir
    fi
    cd $dir
    create_N_files $dir ${FILE_NUM}
    cd ..
done
echo "created successfully"

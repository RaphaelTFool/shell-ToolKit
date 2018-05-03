#########################################################################
# File Name: pstackForAll.sh
# Author: liuxiang
# mail: lxiangb@ankki.com
# Created Time: 2018??04??03?? ???ڶ? 17ʱ27??17??
#########################################################################
#!/bin/bash

OUTPUT="./pstack_log"

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 processName"
    exit 1
fi

AS_PID=`pidof $1`

if [[ -z ${AS_PID} ]]; then
    echo "no process $1 exist, exit..."
    exit 1
else
    echo "processing, please wait ..."
    let i=1
    for pid in ${AS_PID}
    do
        echo -ne "\r${i} "
        echo >> ${OUTPUT}
        echo >> ${OUTPUT}
        echo "result $i ----> ${pid}:" >> ${OUTPUT}
        pstack ${pid} 2>&1 >> ${OUTPUT}
        echo >> ${OUTPUT}
        echo >> ${OUTPUT}
        let i=${i}+1
    done
    echo "pstack ${i} ${1} successfully ..."
fi

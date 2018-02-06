# !/bin/bash

NIC_PATH="/sys/class/net"
RESULT="/tmp/result.temp"

check_pci()
{
	local UDEV=

	if [[ $# -ne 1 ]]; then
		echo "parameter invalid ..."
		echo "Usage check para"
		exit 1
	fi
	if [[ -f /sbin/udevadm ]]; then
		UDEV="/sbin/udevadm info"
	elif [[ -f /usr/bin/udevinfo ]]; then
		UDEV="/usr/bin/udevinfo"
	fi

	if [[ -z $UDEV ]]; then
		echo "systools NOT found, maybe distribution NOT support..."
		exit 1
	fi
	${UDEV} -a -p ${NIC_PATH}/$1 | grep -i looking | sed -n '2p'
}

PCI_RET=
get_pci_num()
{
	if [[ $# -ne 1 ]]; then
		echo "parameter invalid ..."
		echo "Usage check para"
		exit 1
	fi
}

# get all NIC device name of this system
DEV_NAME=
get_NIC_list()
{
	if [[ -f /sbin/ip ]]; then
		DEV_NAME=`/sbin/ip -o link | cut -d":" -f2`
	else
		DEV_NAME=`/sbin/ifconfig -a | grep -o ^[a-z0-9]*`
	fi
}

echo > ${RESULT}
get_NIC_list

for nic in ${DEV_NAME}
do
output=`check_pci ${nic}`
if [[ -z ${output} ]]; then
	continue
fi
output=`echo ${output} | awk -F 'pci' '{ print $2 }' | tr -cd [0-9a-zA-Z]`
echo -e "${nic}\t${output}" >> ${RESULT}
done

PEMAP=`cat ${RESULT} | sort -k2`
echo "${PEMAP}"

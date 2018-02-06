#!/bin/sh
########################################
# filename:	setNetCardOrder.sh
# description:  auto sort NIC by a 
#		specified map file
#
# Author: 	Ral
# modified time:2018/02/05
########################################

# Mention:: Different system version may have different rule in default naming NIC
# For example in centos7 name it as "enpxxxxx"

# set -x

WORK_DIR="/home/setNICorder"
MAP_DIR="${WORK_DIR}/map"
LOG_DIR="${WORK_DIR}/log"
RULE_FILE="/etc/udev/rules.d/70-persistent-net.rules"
MAC_INFO_FILE="/tmp/mac_info.log"
MAC_SORT_FILE="/tmp/mac_sort.log"
DONE_FLAG="${LOG_DIR}/restore_default_eth_config"
OVER_FLAG="${LOG_DIR}/sort_eth_successfully"
ERROR_PROMPT="${LOG_DIR}/ERROR"

BOOT_SHELL="/etc/rc.d/rc.local"
SELF_SCRIPT="${WORK_DIR}/setNetCardOrder.sh"
RUN_SELF="sh ${SELF_SCRIPT}"
RUN_SELF_PAT="sh \/home\/setNICorder\/setNetCardOrder.sh"


# ensure running this script after reboot thus dmesg can get the essential info
# the command below may failed because of different board modify it by yourself
dmesg | grep -i eth | grep -i pci | grep -Po 'eth[0-9]+:|[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]:[a-fA-F0-9][a-fA-F0-9]'| xargs -n 2 > ${MAC_INFO_FILE}

> ${MAC_SORT_FILE}


# this script now can work for centos6 and centos7, other os may have trouble
os_flag=
OS_ver_check()
{
	local os=`cat /etc/redhat-release | grep -i centos`
	if [[ -z ${os} ]]; then
		echo
		echo "this system is not centos"
	fi
	local ver=`cat /etc/redhat-release | grep -Po "[0-9]" | head -n1`
	if [[ ${ver} -lt 6 ]]; then
		echo
		echo "version is lower than 6"
	fi
	os_flag=1
	echo "this OS can use this script, congratulations!"
	echo
}


cad_Ret=
check_and_delete()
{
	if [[ $# -ne 2 ]]; then
		echo
		echo "ERROR: get eth parttern failed .."
		echo "Usage: check_and_delete pattern file .."
		exit 1
	fi

	if [[ -n $1 && -f $2 ]]; then
		local doit=`cat $2 | grep $1`
		if [[ -n ${doit} ]]; then
			sed -i "s/$1//" $2
			if [[ $? -eq 0 ]]; then
				echo "modify success"
			else
				echo "modify $2 failed, exit .."
				exit 1
			fi
		else
			cad_Ret=1
			echo "in function check_and_delete do nothing"
		fi
	else
		echo "ERROR: parameter invalid .."
		exit 1
	fi
}


# make NIC name can be modified
dpe_Ret=
disable_permanent_eth()
{
	local kernel_config="/etc/default/grub"
	local config_info1="net.ifnames=0"
	local config_info2="biosdevname=0"
	local doit=
	
	if [[ -f ${kernel_config} ]]; then
		check_and_delete ${config_info1} ${kernel_config}
		check_and_delete ${config_info2} ${kernel_config}
		if [[ -z ${cad_Ret} ]]; then
			grub2-mkconfig -o /boot/grub2/grub.cfg
			if [[ $? -ne 0 ]]; then
				echo
				echo "modify config file FILED, exit .."
				exit 1
			fi
		else
			dpe_Ret=1
			echo "in function disable_permanent_eth do nothing"
		fi
	else
		echo "${kernel_config} NOT found in this system, continue .."
	fi
}


# order file check
MAP_ERROR=
order_file_check()
{
	if [[ $# -ne 2 ]]; then
		echo
		echo "ERROR: parameter INVALID .."
		echo "Usage: order_file_check file nicnum .."
		exit 1
	fi

	if [[ ! -f $1 ]]; then
		echo "ERROR: File $1 NOT exist .."
		exit 1
	fi

	local order_num=`cat $1 | cut -d ' ' -f 2 | sort | uniq | wc -l`
	if [[ ${order_num} -eq $2 ]]; then
		echo "There may be no error in order file .."
		echo "$1 MAY be the right config file, Please check .." >> ${ERROR_PROMPT}
	else
		echo "Wrong config file $1, Please check .." >> ${ERROR_PROMPT}
		MAP_ERROR=1
	fi
}


# choose the correct NIC map file number of NIC equals to number of map relation
NIC_MAP=
MAP_NUM=
get_nic_map()
{
	local NIC_NUM=`cat ${MAC_INFO_FILE} | wc -l`
	local flag=
	if [[ -d ${MAP_DIR} ]]; then
		local map=`ls ${MAP_DIR}`
		echo "search the suitable map file ..."
		for NIC_MAP in ${map}
		do
			local map_file="${MAP_DIR}/${NIC_MAP}"
			MAP_NUM=`cat ${map_file} | grep -v "^$" | wc -l`
			if [[ ${MAP_NUM} -eq ${NIC_NUM} ]]; then
				order_file_check ${map_file} ${NIC_NUM}
				if [[ -z ${MAP_ERROR} ]]; then
					flag=1
					break
				else
					MAP_ERROR=
				fi
			fi
		done
		if [[ ${flag} -eq 1 ]]; then
			echo "map file FOUND: ${NIC_MAP} .."
		else
			echo
			echo "map file NOT found, please CHECK, exit .."
			cat ${ERROR_PROMPT}
			exit 1
		fi
	else
		echo 
		echo "Directory ${MAP_DIR} NOT exist, exit .."
		exit 1
	fi
}


# get default kernel eth name pattern such as ens* or eth* or enp*
ePattern=
get_default_pattern()
{
	# not suit for redhat 5.8
	local ret=`ls -l /sys/class/net/ | grep -i pci | grep -Po "[a-zA-Z0-9]+ ->" | grep -Po "[a-zA-Z][a-zA-Z]+" | uniq | wc -l`
	if [[ $? -ne 0 ]]; then
		echo
		echo "ERROR: get eth parttern failed .."
		exit 1
	fi

	if [[ ret -ne 1 ]]; then
		ePattern="e"
	else
		ePattern=`ls -l /sys/class/net/ | grep -i pci | grep -Po "[a-zA-Z0-9]+ ->" | grep -Po "[a-zA-Z][a-zA-Z]+" | uniq`
	fi
	echo "The kernel eth name pattern is \"${ePattern}\""
}


# here the string KERNEL=="enp*" should be modified by yourself
set_nic_name()
{
	if [[ $# -ne 3 ]]; then
		echo
		echo "ERROR: parameter invalid ..."
		echo "Usage set_nic_name index macaddr config_file"
		exit 1
	fi

	if [[ -z ${ePattern} ]]; then
		echo
		echo "kernel eth pattern invalid .."
		exit 1
	fi

	if [[ -f $3 ]]; then
		echo "SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${2}\", ATTR{type}==\"1\", KERNEL==\"${ePattern}*\", NAME=\"eth${1}\"" >> ${3}
	else
		echo
		echo "$3 not found .."
		exit 1
	fi
}


# iMac is the return value of get_nic_mac
iMac=
get_nic_mac()
{
	if [[ $# -ne 1 ]]; then
		echo
		echo "ERROR: parameter invalid ..."
		echo "Usage get_nic_mac index"
		exit 1
	fi

	local row=
	((row=$1+1))
	local ETH=
	ETH=`cat ${MAP_DIR}/${NIC_MAP} | sed -n ${row}p | awk '{ print $2 }'`
	if [[ -z ${ETH} ]]; then
		echo
		echo "$1 NOT found in map .."
		exit 1
	fi

	iMac=`cat ${MAC_INFO_FILE} | grep ${ETH}: | awk '{ print $2 }'`
	if [[ -z ${iMac} ]]; then
		echo
		echo "mac address of ${ETH} NOT found .."
		exit 1
	fi
	echo -n "${ETH}:" >> ${MAC_SORT_FILE} 
}


if [[ $# -ne 0 ]]; then
	echo
	echo "ERROR: parameter INVALID .."
	echo "Usage sh $0"
	exit 1
fi

if [[ -d ${WORK_DIR} ]]; then
	echo "go into directory ${WORK_DIR}"
	cd ${WORK_DIR}
else
	echo "$0"
	echo
	echo "Please ensure script in the right directory \"/home/audit\", exit"
	exit 1
fi

if [[ ! -f ${SELF_SCRIPT} ]]; then
	echo
	echo "${SELF_SCRIPT} NOT found, please dont change this script name, exit"
	exit 1
fi

if [[ ! -d ${LOG_DIR} ]]; then
	echo "${LOG_DIR} NOT exist, creating it ..."
	mkdir -p ${LOG_DIR}
fi

# disable kernel permanent naming feature if we can
OS_ver_check
if [[ ${os_flag} -eq 1 && ! -f ${DONE_FLAG} ]]; then
	get_nic_map
	disable_permanent_eth
	echo "add a task at boot ..."
	# if it was already added to the rc.local file the below command could be deleted
	#echo ${RUN_SELF} >> ${BOOT_SHELL}
	echo "make a mark ..."
	touch ${DONE_FLAG}
	if [[ -z ${dpe_Ret} ]]; then
		echo "rebooting system, please wait ..."
		reboot
	fi
fi

touch ${DONE_FLAG}

if [[ -f ${DONE_FLAG} && ! -f ${OVER_FLAG} && -d ${MAP_DIR} ]]; then
	get_nic_map
	get_default_pattern
	echo "starting write system config file ..."
	> ${RULE_FILE}
	for ((i = 0; i < ${MAP_NUM}; i++)) do
		iMac=
		get_nic_mac $i
		echo " ${iMac}" >> ${MAC_SORT_FILE}
		set_nic_name $i ${iMac} ${RULE_FILE}
	done
	echo "write END ..."
	rm -f ${MAC_INFO_FILE}
	rm -f ${MAC_SORT_FILE}
	echo "delete the task ..."
	# function use trigger error
	# check_and_delete ${RUN_SELF_PAT} ${BOOT_SHELL}
	# this command should be written right
	sed -i "s/${RUN_SELF_PAT}//" /etc/rc.d/rc.local
	echo "make a mark"
	touch ${OVER_FLAG}
	#rm -rf ${LOG_DIR}
	echo "rebooting system, please wait ..."
	reboot
else
	echo 
	if [[ ! -d ${MAP_DIR} ]]; then
		echo "Directory $1 NOT found, please CHECK .."
	elif [[ ! -f ${DONE_FLAG} ]]; then
		echo "kernel config wrong .."
	elif [[ -f ${OVER_FLAG} ]]; then
		echo "set NIC order already successfully!"
	else
		echo "UNKNOW ERROR happens .."
	fi

	if [[ -f ${ERROR_PROMPT} ]]; then
		cat ${ERROR_PROMPT}
	fi
	exit 1
fi

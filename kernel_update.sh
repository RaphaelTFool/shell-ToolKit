#! /bin/bash
########################################
# filename:	kernel_update.sh
# description:  auto update kernel
#
# Author: 	Ral
# modified time:2018/01/19
########################################

#set -x
#kernel version and bug cause
allow_version='2.6.32-431.el6.x86_64'
netns=`ps aux | grep netns | grep -v grep`
kernel_conf="/root/update/grub.conf"

# exit the whole script
export TOP_PID=$$
trap 'exit 1' TERM
exit_script()
{
	echo "EXIT ..."
	kill -s TERM $TOP_PID
	echo "Usage: `basename ${0}` filename"
}

# find kernel index for modify configure file
get_index()
{
        if [[ -f $1 ]]; then
                cat $1 | grep title | grep -n title | grep update | awk -F ":" '{ print $1 }'
        else
                echo "$1 not exist!!!"
		exit_script
        fi
}

# modify the kernel configure file
modify_index()
{
        if [[ -f $1 ]]; then
                sed -i -e "0,/default=([0-9]+)/s/default=([0-9]+)/default=$2/" $1
        else
                echo "$1 not exist!"
		exit_script
        fi
}


# decompress patch file
decompress()
{
	local patch_file=""
	for patch_file in $*
	do
	if [[ -f ${patch_file} ]]; then
		# delete suffix
		local patch_dir=${patch_file%.*}
		# delete .tar suffix
		patch_dir=${patch_dir/%.tar/}
		if [[ -d ${patch_dir} ]]; then
			echo "${patch_dir} existed, delete it ..."
			rm -rf ${patch_dir}
		fi

		local file_type=${patch_file##*.}
		case $file_type in
		bz2 | gz)
		echo "Using tar to decompress..."
		tar -xvf ${patch_file}
		echo "decompress finished!"
		;;
		
		zip)
		echo "Using unzip to decompress..."
		unzip ${patch_file}
		echo "decompress finished!"
		;;

		*)
		echo "Unknow filetype, exit..."
		exit_script
		;;
		esac
	fi
	done
}

#install rpm package
rpm_install()
{
	local rpm_zip=""
	for rpm_zip in $*
	do
		# delete suffix
		local rpm_dir=${rpm_zip%.*}	
		# delete .tar suffix
		rpm_dir=${rpm_dir/%.tar/}	
		if [[ -d ${rpm_dir} ]]; then
			cd ${rpm_dir}
			rpm -ivh --force *.rpm
			if [[ ${?} -ne 0 ]]; then
				echo "rpm install FAILED, please check your files and try to UPDATE again!!!"
				exit_script
			fi
		else
			echo "maybe decompress failed..."
			exit_script
		fi
	done
	echo "rpm install successfully"
}

if [[ "$#" -eq "0" ]]; then
	echo "no input parameter, please specify patch file name!"
	exit_script
else
	kernel_version=`uname -r`
	if [[ ${kernel_version}x != ${allow_version}x ]]; then
		echo "local kernel_version is ${kernel_version}, update forbid!"
		exit_script
	fi
	if [[ ${netns}x == x ]]; then
		echo "this kernel do NOT need update!"
		exit_script
	fi
	echo "decompressing compressed file..."
	decompress $*
	echo "installing rpm package file..."
	rpm_install $*
	echo "processing kernel config file..."
	echo "kernel config file is ${kernel_conf}"
	index=`get_index ${kernel_conf}`
	((index=${index}-1))
	modify_index ${kernel_conf} ${index}
	echo "update successfully, please REBOOT your system to enable this update!!!"
fi

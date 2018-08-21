#! /bin/sh

#set -x
FTP="/usr/bin/ftp"
FTPDIR=`date +%Y-%m-%d`

SERVER="x.x.x.x"
USER="aaa"
PASSWD="bbb"

if [[ ! $# -eq 1 ]]; then
	echo "parameter invalid: $# parameters"
	echo "Usage: $0 filename"
	exit 1
fi

if [[ ! -e ${FTP} ]]; then
	echo "ftp tools not exist, please download and install!"
	exit 1
fi


function get_ftp_file()
{
${FTP} -v -n ${SERVER}<<EOF
user ${USER} ${PASSWD}
binary
prompt
cd ${FTPDIR}
mget ${1}
bye
EOF
}

if [[ ! -d $1 ]]; then
	get_ftp_file $1
else
	FILELIST=`ls ${1}`
	for file in ${FILELIST}
	do
	echo "get file ${file}"
	get_ftp_file ${file}
	done
fi

echo "download from fte server successfully!"

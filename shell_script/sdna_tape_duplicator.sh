#!/bin/sh

# First we define the function
function ConfirmOrExit() {
	while true
	do
		echo "Please confirm (y or n) :"
		read CONFIRM
		case $CONFIRM in
			y|Y) break ;;
			n|N)
				echo Aborting - you entered $CONFIRM
				exit
				;;
			*) echo Please enter only y or n
		esac
	done
	echo You entered $CONFIRM. Continuing ...
}

#variable declaraions
app_path=""
force_format="false"
log_path=""
declare -a myarr
tape_found=""

source_tape_device=""
target_tape_device=""

source_tape_serial=""
source_tape_serials=""
target_tape_serial=""
target_tape_serials=""


usage_str="Usage: sdna_tape_duplicator.sh -s source-tape-device-id -t target-tape-device-id [-force] sourceserial1:targetserial1 [sourceserial2:targetserial2 ...]"

#environment checks for mac versus linux
if [ -d "/Applications/StorageDNA/accessDNA.app/Contents/MacOS" ]; then
	app_path="/Applications/StorageDNA/accessDNA.app/Contents/MacOS/"
	log_path="/sdna_fs/ADMINISTRATORDROPBOX/primary/"
fi

if [ -z "$app_path" -a "${app_path+xxx}" = "xxx" ]; then
	if [ -d "/opt/sdna/bin" ]; then
		app_path="/opt/sdna/bin"
		log_path="/sdna_fs/ADMINISTRATORDROPBOX/primary/"
	fi
fi

if [ -z "$app_path" -a "${app_path+xxx}" = "xxx" ]; then
	echo "Unable to find StorageDNA installation"
	exit 7;
fi

#parsing arguments see usage above for command line
while [ $# -ge 1 ];
do
	case $1 in
		-s)
			shift;
			source_tape_device=$1;;
		-t)
			shift;
			target_tape_device=$1;;
		-force)
			force_format="true";;
		-*)
			echo ${usage_str}
			exit 2;;
		*)
			len=`echo $1 | awk '{print length}'`
			if [ "$len" -ne 13 ]; then
				if [ "$len" -ne 17 ]; then
					echo "Invalid tape serial found: " $1
					exit 1;
				fi
			fi
			tape_found="true";
			myarr[${#myarr[*]}]=$1;;
	esac
	shift;
done

#check for required arguments
if [ -z "$source_tape_device" -a "${source_tape_device+xxx}" = "xxx" ]; then
	echo "Missing source tape device."
	echo ${usage_str}
	exit 4;
fi

if [ -z "$target_tape_device" -a "${target_tape_device+xxx}" = "xxx" ]; then
	echo "Missing target tape device."
	echo ${usage_str}
	exit 5;
fi

if [ -z "$tape_found" -a "${tape_found+xxx}" = "xxx" ]; then
	echo "No tape serials specified."
	exit 6
fi

#Invalid options checks
# Source tape device should not equal target tape device
if [ "$source_tape_device" = "$target_tape_device" ]; then
	echo "Source and target device cannot be the same device."
	echo ${usage_str}
	exit 8;
fi

# Source and target serials must not be repeated
echo "ifs is [ $IFS ]"
oldIFS="$IFS"
IFS=":"
declare -a serialarr
for i in "${myarr[@]}"; do

	#split each element in the list to test the conditions
	set -- $i
    COUNTER=0
    for s in $@
    do
		if [ $COUNTER == 0 ]; then
			source_tape_serial=$s
		else
			target_tape_serial=$s
		fi

		COUNTER=`expr $COUNTER + 1`
    done

    echo "source serial $source_tape_serial"
    echo "target serial $target_tape_serial"

	if echo "$source_tape_serials" | grep -q $source_tape_serial; then
		echo "You have specified a source tape serial multiple times, DNAevolution can only support making one duplicate of a tape."
		echo ${usage_str}
		exit 9;
	else
		source_tape_serials=$source_tape_serials";"$source_tape_serial
	fi

	echo $i | cut -d':' -f2 | read target_tape_serial
	if echo "$target_tape_serials" | grep -q $target_tape_serial; then
		echo "You have specified a target serial multiple times which might be a mistake, please check the tape serials and rerun.."
		echo ${usage_str}
		exit 10;
	else
		target_tape_serials=$target_tape_serials";"$target_tape_serial
	fi
done


echo ""
echo "*****************************"
echo "LTO Tape Duplication settings"
echo "*****************************"
echo Force format option: $force_format
echo Source tape device id: $source_tape_device
echo Target tape device id: $target_tape_device
echo ""
echo "Tape serials { ORIGINAL-SOURCE:DUPLICATED-TARGET }:"

for i in "${myarr[@]}"; do  # echoes one line for each element of the array.
  echo $i
done

echo ""
echo "The duplication tool is provided with no warranty.  This script is soley for the use of authorized support representitives of StorageDNA.  By confirming you awcknowledge that you are authorized to run this tool and do not hold StorageDNA responsible for any loss of data.  It is highly recommended that you lock all the original source tapes so that there is no accidental loss of information."
echo "Ready to format?"
ConfirmOrExit
result=""

for i in $"${myarr[@]}"; do

	#split each element in the list to process the duplication
	 set -- $i
    COUNTER=0
    for s in $@
    do
		if [ $COUNTER == 0 ]; then
			source_tape_serial=$s
		else
			target_tape_serial=$s
		fi

		COUNTER=`expr $COUNTER + 1`
    done
	 echo ""

	 #Call ltfs copy with the arguments specified
	 echo "Loading tapes to duplicate ${source_tape_serial} to ${target_tape_serial}"
	 result=`${app_path}/ltfs_copy -source ${source_tape_device} -sourceserial ${source_tape_serial} -target ${target_tape_device} -targetserial ${target_tape_serial}`
	 rc=$?
	 if [[ $rc != 0 ]] ; then
		  echo "Unable to load tape $i from device ${tape_device} [$rc]"
		  echo $result;
		  exit $rc 
	 fi 

#  echo "Checking tape $i in ${tape_device} to ensure it is unmounted..."
#   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -lock`
#   rc=$?
#   if [[ $rc != 0 ]] ; then
#	echo "Unable to ensure tape is unmounted $i from device ${tape_device} [$rc]"
#	echo $result;
#	exit $rc 
#   fi 
  
#  echo "Formatting tape $i in ${tape_device} [force=${force_format}]..."
#   if [ ${force_format} == "true" ]; then
#   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -force -lock`
#   else
#   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -lock`
#   fi
#   rc=$?
#   if [[ $rc != 0 ]] ; then
#	echo "Unable to format tape $i from device ${tape_device} [$rc]"
#	echo result
#	exit $rc 
#   fi 

#  echo "Unloading tape $i from ${tape_device}..."
#   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -unloadtape -lock`
#   rc=$?
#   if [[ $rc != 0 ]] ; then
#	echo "Unable to unload tape $i from device ${tape_device} [$rc]"
#	echo $result
#	exit $rc 
#   fi 

done

#reset IFS variable
IFS="$oldIFS"

echo "Duplication completed."

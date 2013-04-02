#!/bin/sh

#List of variables used in the script.
#Configuration Files
Config_file="ConfigFile"
CCFile="Changer_ConfigFile"
#Temporary Files
DNAltman_Output="Tapes.xml"
Temp_Device_file=".temp_device_holder"
Temp_Source_Selected_Device=".temp_source_selected_device"
Temp_Target_Selected_Device=".temp_target_selected_device"
Temp_tape_file=".temp_tape_holder"
User_Temp_tape_file=".user_temp_tape_file"
Wrong_Tapes=".wrong_tapes"
User_Temp_tape_file_Sorted=".user_temp_tape_file_sorted"
#Final_Formatting_Tapes=".tapes_to_be_formatted"
#Commands
DNA_lock_scripter="/opt/sdna/bin/dna_lock_scripter"
#Colors
Red_Color='\033[01;31m'
Blue_Color='\033[01;34m'
Green_Color='\033[07;32m'
Green_Blink='\033[05;32m'
Reset_Color='\033[00;00m'
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

echo ""
echo -e "${Blue_Color}************************${Reset_Color}"
echo -e "${Blue_Color}Tape Duplicating Script${Reset_Color}"
echo -e "${Blue_Color}************************${Reset_Color}"

# First we define the function
function ConfirmOrExit() {
	while true
	do
	echo ""
	read -p 'Please confirm (yes or no) : ' CONFIRM
	case $CONFIRM in
		y|Y|yes|YES|Yes) break ;;
		n|N|no|NO|No)
			echo -e "${Red_Color}Aborting - you entered $CONFIRM...${Reset_Color}"
			exit
			;;
		*) echo -e "${Red_Color}Please answer yes or no.${Reset_Color}";;
		esac
	done
	echo -e "You entered ${Green_Blink}$CONFIRM${Reset_Color}. Continuing..."
}

function clean_temp_files() {
rm -f $Temp_Device_file
rm -f $Temp_Source_Selected_Device
rm -f $Temp_Target_Selected_Device
rm -f $Temp_tape_file
rm -f $User_Temp_tape_file
rm -f $Wrong_Tapes
rm -rf $User_Temp_tape_file_Sorted
}

if [ -s $Config_file ];
then
echo ""
echo "Reading list of devices to be analysed..."
All_Devices=`awk '{
        {ORS = " "}
        device = $0
        print device
}' $Config_file`


#Running dna_lock_scripter to find the devices which are free.
./dna_lock_scripter -d $All_Devices > $Temp_Device_file
#$DNA_lock_scripter -d $All_Devices > $Temp_Device_file

echo ""
echo -e "Tape devices which are free :"
echo -e "-----------------------------${Green_Color}"
cat $Temp_Device_file
echo -e "${Reset_Color}"

while true; do
#Source device.
echo ""
read -p 'For duplicating the tapes please select the source device you want to use (e.g. st0), then press Enter : ' source_tape_device
if [ "$source_tape_device" == "" ]
then
echo -e "${Red_Color}You have not entered any source Device ids, Please re-enter it...${Reset_Color}"
else
#Check entered selected device is null or not.
if grep -w $source_tape_device $Temp_Device_file > $Temp_Source_Selected_Device
then
echo -e "You have selected source device : ${Green_Blink}$source_tape_device${Reset_Color}"
echo ""
ConfirmOrExit

#Target device.
echo ""
echo -e "Target tape devices which are free :"
echo -e "------------------------------------${Green_Color}"
cat $Temp_Source_Selected_Device | sed s'/'$source_tape_device'//g' | sed s'/,/ /g'
echo -e "${Reset_Color}"

while true; do
echo ""
read -p 'For duplicating the tapes please select the target device you want to use (e.g. st0), then press Enter : ' target_tape_device
if [ "$target_tape_device" == "" ]
then
echo -e "${Red_Color}You have not entered any target Device ids, Please re-enter it...${Reset_Color}"
else
#Check entered selected device is null or not.
if grep -w $target_tape_device $Temp_Device_file > $Temp_Target_Selected_Device
then
echo -e "You have selected source device : ${Green_Blink}$target_tape_device${Reset_Color}"
echo ""
ConfirmOrExit

#Invalid options checks
# Source tape device should not equal target tape device
if [ "$source_tape_device" = "$target_tape_device" ]; then
	echo ""
        echo -e "${Red_Color}Source and target device cannot be the same device.${Reset_Color}"
        echo ${usage_str}
        exit 8;
fi

#########################################Running dnaltman Script for finding the tapes which are available###########################################
#$DNAltman gettapemap -a `< $CCFile` > $DNAltman_Output
cat $DNAltman_Output | sed s'/tapeid/\ntapeid/g' | grep 'tapeid' | cut -d= -f2 | cut -d\" -f2 | sort -n | awk '{if (length($0) == 6 ) print $0 }' > $Temp_tape_file

#Formatting tape forcefully or not.
while true; do
echo ""
echo -e "${Blue_Color}Do you want to format the tape forcefully? Enter${Red_Color} true${Blue_Color} for formatting forcefully otherwise enter${Green_Blink} false${Reset_Color}."
read -p 'Enter your choice : ' force_format
case $force_format in
true) echo "You have chosen to format the tape forcefully by selecting $force_format..."
ConfirmOrExit
break;;
false) echo "You have chosen to format the tape normally by selecting $force_format..."
break;;
* ) echo -e "${Red_Color}Please answer true or false only.${Reset_Color}";;
esac
done


function user_entry_of_tapes() {
echo ""
echo -e "Following is the list of the tapes which are available, select tape serials from this list...${Green_Color}"
cat $Temp_tape_file
echo -e "${Reset_Color}"
echo "Please specify the list of source tape serials you want to duplicate from the above list. Use the comma delimited (e.g. sourceserial1:targetserial1 sourceserial2:targetserial2 sourceserial3:targetserial3 sourceserial4:targetserial4)."
read -p 'Then press Enter. : ' tapes
if [ "$tapes" == "" ]
then echo " "
echo -e "${Red_Color}You have not entered any Tape Serials, Please re-enter it...${Reset_Color}" > $Wrong_Tapes
else
echo $tapes | sed s'/ /\n/g'| sort -n > $User_Temp_tape_file
cat $User_Temp_tape_file | sed s'/:/\n/g' | sort -u > $User_Temp_tape_file_Sorted
diff -u $Temp_tape_file $User_Temp_tape_file_Sorted | grep "^+" | cut -d+ -f2 | awk '{if (length($0) > 0 ) print $0 }' > $Wrong_Tapes
fi
}


function tape_duplicate() {
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

	tape_found="true";
	IFS=$'\n' read -d '' -r -a myarr < $User_Temp_tape_file

# Source and target serials must not be repeated
#echo "ifs is [ $IFS ]"
oldIFS="$IFS"
IFS=":"
declare -a serialarr
for i in "${myarr[@]}"; do

        #split each element in the list to test the conditions
        set -- $i
    COUNTER=0
#echo "$@"
    for s in $@
    do
                if [ $COUNTER == 0 ]; then
                        source_tape_serial=$s
                else
                        target_tape_serial=$s
                fi

                COUNTER=`expr $COUNTER + 1`
    done

    #echo "source serial $source_tape_serial"
    #echo "target serial $target_tape_serial"

        if echo "$source_tape_serials" | grep -q $source_tape_serial; then
                echo -e "${Red_Color}You have specified a source tape serial multiple times, DNAevolution can only support making one duplicate of a tape.${Reset_Color}"
                #echo ${usage_str}
                echo ""
		exit 9;
else
                source_tape_serials=$source_tape_serials";"$source_tape_serial
        fi

        echo $i | cut -d':' -f2 | read target_tape_serial
        if echo "$target_tape_serials" | grep -q $target_tape_serial; then
                echo -e "${Red_Color}You have specified a target serial multiple times which might be a mistake, please check the tape serials and rerun..${Reset_Color}"
                echo ""
                #echo ${usage_str}
                exit 10;
        else
                target_tape_serials=$target_tape_serials";"$target_tape_serial
        fi
done


#parsing arguments see usage above for command line
#while [ $# -ge 1 ];
#do
#	case $1 in
#		-s)
#			shift;
#			source_tape_device=$1;;
#		-t)
#			shift;
#			target_tape_device=$1;;
#		-force)
#			force_format="true";;
#		-*)
#			echo ${usage_str}
#			exit 2;;
#		*)
#			len=`echo $1 | awk '{print length}'`
#			if [ "$len" -ne 13 ]; then
#				if [ "$len" -ne 17 ]; then
#					echo "Invalid tape serial found: " $1
#					exit 1;
#				fi
#			fi
#			tape_found="true";
#			myarr[${#myarr[*]}]=$1;;
#	esac
#	shift;
#done

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


echo ""
echo -e  "${Blue_Color}*****************************"
echo -e "LTO Tape Duplication settings"
echo -e "*****************************${Reset_Color}"
echo -e Force format option: ${Blue_Color}$force_format${Reset_Color}
echo -e Source tape device id: ${Blue_Color}$source_tape_device${Reset_Color}
echo -e Target tape device id: ${Blue_Color}$target_tape_device${Reset_Color}
echo ""
echo "Tape serials { ORIGINAL-SOURCE:DUPLICATED-TARGET }:"

for i in "${myarr[@]}"; do  # echoes one line for each element of the array.
  echo -e ${Blue_Color}$i${Reset_Color}
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
	 #echo "Loading tapes to duplicate ${source_tape_serial} to ${target_tape_serial}"
	 echo -e "Loading tapes to duplicate ${Green_Blink}${source_tape_serial}${Reset_Color} to ${Green_Blink}${target_tape_serial}${Reset_Color}"
	 result=`${app_path}/ltfs_copy -source ${source_tape_device} -sourceserial ${source_tape_serial} -target ${target_tape_device} -targetserial ${target_tape_serial}`
	 rc=$?
clean_temp_files
	 if [[ $rc != 0 ]] ; then
		  #echo "Unable to load tape $i from device ${tape_device} [$rc]"
		  echo -e "${Red_Color}Unable to load tape $i from device ${tape_device} [$rc]${Reset_Color}"
		  echo -e ${Red_Color}$result${Reset_Color};
		clean_temp_files
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
}



user_entry_of_tapes
while true; do
#Checking if the user has entered wrong ID of the tapes...
words=`wc -m $Wrong_Tapes | cut -d. -f1`
if [ $words -eq 0 ]
then echo -e "Following tapes combination are going to be duplicated [ORIGINAL-SOURCE-TAPE:DUPLICATED-TARGET-TAPE]${Green_Blink}"
cat $User_Temp_tape_file
echo -e "${Reset_Color}"
ConfirmOrExit
tape_duplicate
else

echo -e "${Red_Color}You have entered the invalid tape serials or entered in wrong format, please check in your choices of source and target tapes. :"
cat $Wrong_Tapes
echo -e "${Reset_Color}"
echo "Please correct the above tape serials..."
echo "Eg. sourceserial1:targetserial1 sourceserial2:targetserial2 sourceserial3:targetserial3 sourceserial4:targetserial4"
user_entry_of_tapes
fi
done


else
echo -e "${Red_Color}You have entered wrong target device, Please enter the name of the free target device correctly!${Reset_Color}"
fi

fi
done

else
echo -e "${Red_Color}You have entered wrong source device, Please enter the name of the free source device correctly!${Reset_Color}"
fi

fi
done


else
echo -e "${Red_Color}Configuraton file not found...${Reset_Color}"
echo "Please enter the name of the devices you want to check in the Configuration file named as ConfigFile separated by new line."
fi


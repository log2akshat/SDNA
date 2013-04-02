#!/bin/sh

#List of variables used in the script.
#Configuration Files
Config_file="ConfigFile"
CCFile="Changer_ConfigFile"
#Temporary Files
DNAltman_Output="Tapes.xml"
Temp_Device_file=".temp_device_holder"
Temp_Selected_Device=".temp_selected_device"
Temp_tape_file=".temp_tape_holder"
User_Temp_tape_file=".user_temp_tape_file"
Wrong_Tapes=".wrong_tapes"
#Final_Formatting_Tapes=".tapes_to_be_formatted"
#Commands
DNA_lock_scripter="/opt/sdna/bin/dna_lock_scripter"
#Colors
Red_Color='\033[01;31m'
Blue_Color='\033[01;34m'
Green_Color='\033[07;32m'
Green_Blink='\033[05;32m'
Reset_Color='\033[00;00m'

echo -e "${Blue_Color}**********************${Reset_Color}"
echo -e "${Blue_Color}Tape Formatting Script${Reset_Color}"
echo -e "${Blue_Color}**********************${Reset_Color}"

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
echo "Reading list of devices to be analysed..."
All_Devices=`awk '{
        {ORS = " "}
        device = $0
        print device
}' $Config_file`


#Running dna_lock_scripter to find the devices which are free.
./dna_lock_scripter -d $All_Devices > $Temp_Device_file
#$DNA_lock_scripter -d $All_Devices > $Temp_Device_file

echo -e "Tape devices which are free : ${Green_Color}"
cat $Temp_Device_file
echo -e "${Reset_Color}"


while true; do
read -p 'Please select the device you want to use for formatting the tapes (e.g. st0), then press Enter : ' tape_device
if [ "$tape_device" == "" ]
then
echo -e "${Red_Color}You have not entered any Device ids, Please re-enter it...${Reset_Color}"
else
#Check entered selected device is null or not.
if grep -w $tape_device $Temp_Device_file > $Temp_Selected_Device
then
echo -e "You have selected device : ${Green_Blink}$tape_device${Reset_Color}"
ConfirmOrExit

#########################################Running dnaltman Script for finding the tapes which are available###########################################
#$DNAltman gettapemap -a `< $CCFile` > $DNAltman_Output
cat $DNAltman_Output | sed s'/tapeid/\ntapeid/g' | grep 'tapeid' | cut -d= -f2 | cut -d\" -f2 | sort -n | awk '{if (length($0) == 6 ) print $0 }' > $Temp_tape_file

while true; do
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
echo -e "Following is the list of the tapes which are available, select tape serials from this list...${Green_Color}"
cat $Temp_tape_file
echo -e "${Reset_Color}"
read -p 'Please provide the list of tape serials you want to format from the above list. Use the comma delimited (e.g. TAPE01,TAPE02,TAPE03). Then press Enter. : ' tapes
if [ "$tapes" == "" ]
then echo " "
echo -e "${Red_Color}You have not entered any Tape Serials, Please re-enter it...${Reset_Color}" > $Wrong_Tapes
else
echo $tapes | sed s'/,/\n/g'| sort -n > $User_Temp_tape_file
diff -u $Temp_tape_file $User_Temp_tape_file | grep "^+" | cut -d+ -f2 | awk '{if (length($0) > 0 ) print $0 }' > $Wrong_Tapes
#cat $User_Temp_tape_file | sed ':a;N;$!ba;s/\n/ /g' > $Final_Formatting_Tapes
fi
}

function tape_format()
{
changer_device=""
#tape_device=""
#force_format="false"
tape_found=""
declare -a myarr
app_path=""

if [ -d "/Applications/StorageDNA/accessDNA.app/Contents/MacOS" ]; then
   app_path="/Applications/StorageDNA/accessDNA.app/Contents/MacOS/"
fi
if [ -z "$app_path" -a "${app_path+xxx}" = "xxx" ]; then
	if [ -d "/opt/sdna/bin" ]; then
	   app_path="/opt/sdna/bin"
	fi
fi

if [ -z "$app_path" -a "${app_path+xxx}" = "xxx" ]; then
   echo -e "${Red_Color}Unable to find StorageDNA installation${Reset_Color}"
   exit 7;
fi

usage_str="Usage: format_changer.sh -tape tape-device-id [-force] tape-serial-1 [tape-serial-2 ...]"

#while [ $# -ge 1 ]; do
#        case $1 in
#                -changer)
#                        shift;
#                        changer_device=$1;;
#                -tape)
#			shift;
#                        tape_device=$1;;
#		-force)
#			force_format="true";;
#                -*)
#			echo ${usage_str}
#                        exit 2;;
#                *)
#			#len=`echo $1 | awk '{print length}'`
#			echo "Tapes in case loop : " $tapes_to_be_formatted
#			len=`echo $tapes | awk '{print length}'`
#			if [ "$len" -ne 6 ]; then
#				if [ "$len" -ne 8 ]; then
#					#echo "Invalid tape serial found: " $1
#					echo "Invalid tape serial found: " $tapes_to_be_formatted
#					exit 1;
#				fi
#			fi
#			tape_found="true";
#			#myarr[${#myarr[*]}]=$1;;
#			myarr[${#myarr[*]}]=$tapes_to_be_formatted;;
#       esac
#        shift;
#done

echo "Force Format Option : $force_format"

                        tape_found="true";
			IFS=$'\n' read -d '' -r -a myarr < $User_Temp_tape_file


if [ -z "$tape_device" -a "${tape_device+xxx}" = "xxx" ]; then
	echo ${usage_str}
	exit 5;
fi

if [ -z "$tape_found" -a "${tape_found+xxx}" = "xxx" ]; then
	echo "No tape serials specified."
	exit 6
fi

echo ""
echo -e "${Blue_Color}*****************************"
echo -e "Formatter settings"
echo -e "*****************************"${Reset_Color}
echo -e Force option: ${Blue_Color}$force_format${Reset_Color}
echo -e Tape device id: ${Blue_Color}$tape_device${Reset_Color}
echo ""
echo Tape serials:

for i in "${myarr[@]}"; do  # echoes one line for each element of the array.
   echo -e "${Green_Color}$i${Reset_Color}"
done

echo ""
echo "The formatting tool is provided with no warranty.  This script is soley for the use of authorized support representitives of StorageDNA.  By confirming your format you awcknowledge that you are authorized to run this tool."
echo "Ready to format?"
ConfirmOrExit
result=""

for i in $"${myarr[@]}"; do

   echo ""
   echo -e "Loading tape ${Green_Color}$i${Reset_Color} in ${Green_Color}${tape_device}${Reset_Color}..."
   result=`${app_path}/dnaltman mounttape -d ${tape_device} -t $i -nomount -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo -e "Unable to load tape ${Green_Color}$i${Reset_Color} from device ${Green_Color}${tape_device}${Reset_Color} [$rc]"
	echo $result;
	exit $rc 
   fi 

   echo -e "Checking tape ${Green_Color}$i${Reset_Color} in ${Green_Color}${tape_device}${Reset_Color} to ensure it is unmounted..."
   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo -e "Unable to ensure tape is unmounted ${Green_Color}$i${Reset_Color} from device ${Green_Color}${tape_device}${Reset_Color} [$rc]"
	echo $result;
	exit $rc 
   fi 
   
   echo -e "Formatting tape ${Green_Color}$i${Reset_Color} in ${Green_Color}${tape_device}${Reset_Color} [force=${force_format}]..."
   if [ ${force_format} == "true" ]; then
   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -force -lock`
   else
   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -lock`
   fi
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo -e "Unable to format tape ${Green_Color}$i${Reset_Color} from device ${Green_Color}${tape_device}${Reset_Color} [$rc]"
	echo result
	exit $rc 
   fi 

   echo -e "Unloading tape ${Green_Color}$i${Reset_Color} from ${Green_Color}${tape_device}${Reset_Color}..."
   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -unloadtape -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo -e "Unable to unload tape ${Green_Color}$i${Reset_Color} from device ${Green_Color}${tape_device}${Reset_Color} [$rc]"
	echo $result
	exit $rc 
   fi 

done
clean_temp_files
echo "Formatting completed."
}


user_entry_of_tapes
while true; do
#Checking if the user has entered wrong ID of the tapes...
words=`wc -m $Wrong_Tapes | cut -d. -f1`
if [ $words -eq 0 ]
then echo -e "Following tapes are going to be formatted...${Green_Blink}"
cat $User_Temp_tape_file
echo -e "${Reset_Color}"
ConfirmOrExit
tape_format
else

echo -e "${Red_Color}You have entered the invalid tape serials... :"
cat $Wrong_Tapes
echo -e "${Reset_Color}"
echo "Please correct the above tape serials..."
user_entry_of_tapes
fi
done


else
echo -e "${Red_Color}You have entered wrong device, Please enter the name of the free device correctly!${Reset_Color}"
fi

fi
done

else
echo -e "${Red_Color}Configuraton file not found...${Reset_Color}"
echo "Please enter the name of the devices you want to check in the Configuration file named as ConfigFile separated by new line."
fi

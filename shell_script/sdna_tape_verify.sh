#!/bin/bash

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
#Commands
DNA_lock_scripter="/opt/sdna/bin/dna_lock_scripter"
Tape_Validate="/opt/sdna/bin/tape_validate"
DNAltman="/opt/sdna/bin/dnaltman"
#Colors
Red_Color='\033[01;31m'
Blue_Color='\033[01;34m'
Green_Color='\033[07;32m'
Green_Blink='\033[05;32m'
Reset_Color='\033[00;00m'

echo -e "${Blue_Color}*********************${Reset_Color}"
echo -e "${Blue_Color}Tape Verifying Script${Reset_Color}"
echo -e "${Blue_Color}*********************${Reset_Color}"

#Checking Configuration file is present or not.
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
read -p 'Please select the device you want to use for verification (e.g. st0), then press Enter : ' selected_device
if [ "$selected_device" == "" ]
then
echo -e "${Red_Color}You have not entered any Device ids, Please re-enter it...${Reset_Color}"
else
#Check entered selected device is null or not.
if grep -w $selected_device $Temp_Device_file > $Temp_Selected_Device
then
echo -e "You have selected device : ${Green_Blink}$selected_device${Reset_Color}"
while true; do
read -p "Do you want to continue? (y/n) : " option
case $option in
y|Y|yes|YES|Yes)
echo -e "You entered ${Green_Blink}$option${Reset_Color}. Continuing..."
#########################################Running dnaltman Script for finding the tapes which are available###########################################
#$DNAltman gettapemap -a `< $CCFile` > $DNAltman_Output
cat $DNAltman_Output | sed s'/tapeid/\ntapeid/g' | grep 'tapeid' | cut -d= -f2 | cut -d\" -f2 | sort -n | awk '{if (length($0) == 6 ) print $0 }' > $Temp_tape_file

function user_entry_of_tapes() {
echo -e "Following is the list of the tapes which are available, select tape ids from this list...${Green_Color}"
cat $Temp_tape_file
echo -e "${Reset_Color}"
read -p 'Please provide the list of tape serials you want to verify from the above list. Use the comma delimited (e.g. TAPE01,TAPE02,TAPE03). Then press Enter. : ' tapes
if [ "$tapes" == "" ]
then echo " "
echo -e "${Red_Color}You have not entered any Tape ids, Please re-enter it...${Reset_Color}" > $Wrong_Tapes
else
echo $tapes | sed s'/,/\n/g'| sort -n > $User_Temp_tape_file
diff -u $Temp_tape_file $User_Temp_tape_file | grep "^+" | cut -d+ -f2 | awk '{if (length($0) > 0 ) print $0 }' > $Wrong_Tapes
fi
}

function tape_verify()
{
while true; do
read -p "Do you want to verify these tapes? (y/n) : " opt
case $opt in
y|Y|yes|YES|Yes)
echo -e "You entered ${Green_Blink}$opt${Reset_Color}. Continuing..."
echo -e "${Blue_Color}>>>> You can cancel the tape verification process at any time by pressing ^C....${Reset_Color}"
$Tape_Validate -d $selected_device -t $tapes -md5
exit;;
n|N|no|NO|No) echo -e "${Red_Color}You have cancelled the tape verification process...${Reset_Color}"
exit;;
* ) echo -e "${Red_Color}Please answer yes or no.${Reset_Color}";;
esac
done
echo "Tape verification completed."
}

user_entry_of_tapes
while true; do
#Checking if the user has entered wrong ID of the tapes...
words=`wc -m $Wrong_Tapes | cut -d. -f1`
if [ $words -eq 0 ]
then echo -e "Following tapes are going to be verified...${Green_Blink}"
cat $User_Temp_tape_file
echo -e "${Reset_Color}"
#echo "HELP : tape_validate -d <device id> -t <tape serials comma-delimited> [-md5] [-skipltfs] [-progress <progress-guid>] -o output folder"
tape_verify
else

echo -e "${Red_Color}You have entered the wrong tape ids... :"
cat $Wrong_Tapes
echo -e "${Reset_Color}"
echo "Please correct the above tape ids..."
user_entry_of_tapes
fi
done

#Device selection case for No.
exit;;
n|N|no|NO|No) echo -e "${Red_Color}You have aborted the operation...${Reset_Color}"
exit;;
* ) echo -e "${Red_Color}Please answer yes or no.${Reset_Color}";;
esac
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

echo "Cleaning up Temporary files..."
rm -f $Temp_Device_file
rm -f $Temp_Selected_Device
rm -f $Temp_tape_file
rm -f $User_Temp_tape_file
rm -f $Wrong_Tapes
echo "Cleaned Temporary files..."

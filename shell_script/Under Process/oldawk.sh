#!/bin/bash
echo "Tape Verifying Script"

Config_file="ConfigFile"
CCFile="Changer_ConfigFile"
Temp_file=".temp_device_holder"
DNAltman_Output="Tapes.xml"
Temp_tape_file=".temp_tape_holder"
User_Temp_tape_file=".user_temp_tape_file"
if [ -s $Config_file ];
then
echo "Reading list of devices to be analysed..."
All_Devices=`awk '{
        {ORS = " "}
        device = $0
        print device
}' $Config_file`
./dna_lock_scripter -d $All_Devices > $Temp_file
echo "Tape devices free :"
cat $Temp_file
read -p 'Please select the device you want to use for verification (e.g. st0), then press Enter : ' selected_device
if grep -w $selected_device $Temp_file
then
echo "You have selected device : "$selected_device
while true; do
read -p "Do you want to continue? (y/n) : " option
case $option in
[Yy]* )
#yes=y
#no=n
#if [[ $option == $yes ]]
#then
###############################Running dnaltman Script for finding the tapes which are available########################
#/opt/sdna/bin/dnaltman gettapemap -a < $CCFile > $DNAltman_Output
cat $DNAltman_Output | sed s'/tapeid/\ntapeid/g' | grep 'tapeid' | cut -d= -f2 | cut -d\" -f2 | sort -n | awk '{if (length($0) == 6 ) print $0 }' > $Temp_tape_file
echo "Following is the list of the tapes which are available :"
cat $Temp_tape_file
read -p 'Please provide the list of tape serials you want to verify from the above list. Use the comma delimited (e.g. TAPE01,TAPE02,TAPE03). Then press Enter. : ' tapes
#awk -f test_awk $Temp_tape_file
#LTO_Tapes_Serial=`awk -F "," '{ for(i=1;i<=NF;i++)
#print "Following tapes are going to be verified : ",$i
echo $tapes > $User_Temp_tape_file
awk -F "," '{ for(i=1;i<=NF;i++)
if (length($i)!=6)
print "Attention wrong tape serial number entered : ",$i
}' $User_Temp_tape_file
exit;;
[Nn]* ) exit;;
* ) echo "Please answer yes or no. Type Y/y for yes and N/n for no.";;
esac
done
#else
#if [[ $option == $no ]]
#then
#echo "You have aborted the operation."
#exit
#else echo "Please run the script again and type y for yes and n for no."
#fi
#fi
else
echo "You have entered wrong device, Please enter the name of the free device correctly!"
fi
else
echo "Configuraton file not found..."
echo "Please enter the name of the devices you want to check in the Configuration file named as ConfigFile separated by new line."
fi
rm $Temp_file
#rm $Temp_tape_file
#echo "\n"

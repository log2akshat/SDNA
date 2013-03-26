#!/bin/bash
echo "Tape Verifying Script"

Config_file="ConfigFile"
Temp_file=".temp_device_holder"
Temp_tape_file=".temp_tape_holder"

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
read -p 'Do you want to continue? (y/n) : ' option
yes=y
no=n
if [[ $option == $yes ]]
then
#echo "tape serial"
read -p 'Please provide the list of tape serials you want to verify. Use the comma delimited (e.g. TAPE01, TAPE02, TAPE03). Then press Enter. : ' tapes
echo $tapes > $Temp_tape_file
#awk -F "," '{for(i=1;i<=NF;i++){print $i "\n" }}' $Temp_tape_file
awk -F "," '{for(i=1;i<=NF;i++}{print $i "\n" }{print length($1)}}' $Temp_tape_file
#awk -f test_awk $Temp_tape_file
awk '{for(i=1;i<=NR;i++){{print$i} {print length($1)}}}' $Temp_tape_file
else
if [[ $option == $no ]]
then
echo "You have aborted the operation."
exit
else echo "Please run the script again and type y for yes and n for no."
fi
fi
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

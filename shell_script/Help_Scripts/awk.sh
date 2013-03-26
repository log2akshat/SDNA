#!/bin/bash
#IFS=$"\n"
echo "Tape Verifying Script"

Config_file="ConfigFile"
if [ -s $Config_file ];
then
echo "Reading list of devices to be analysed..."
All_Devices=`awk '{
        {ORS = " "}
        device = $0
        print device
}' $Config_file`
./dna_lock_scripter -d $All_Devices
else
echo "Configuraton file not found..."
echo "Please enter the name of the devices you want to check in the Configuration file named as ConfigFile separated by new line."
fi
#echo "\n"
#unset IFS

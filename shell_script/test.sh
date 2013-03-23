#!/bin/bash
#IFS=$"\n"
echo "Tape Verifying Script"

Config_file="ConfigFile"
if [ -s $Config_file ];
then
echo "Reading list of devices to be analysed..."
while read device; do
echo "$device"
#./dna_lock_scripter -d $device
done < "ConfigFile"
else
echo "Configuraton file not found..."
echo "Please enter the devices in the Configuration file named as ConfigFile seprated by spaces"
fi
#unset IFS


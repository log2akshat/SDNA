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

changer_device=""
tape_device=""
force_format="false"
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
   echo "Unable to find StorageDNA installation"
   exit 7;
fi

usage_str="Usage: format_changer.sh -tape tape-device-id [-force] tape-serial-1 [tape-serial-2 ...]"

while [ $# -ge 1 ]; do
        case $1 in
                -changer)
                        shift;
                        changer_device=$1;;
                -tape)
			shift;
                        tape_device=$1;;
		-force)
			force_format="true";;
                -*)
			echo ${usage_str}
                        exit 2;;
                *)
			len=`echo $1 | awk '{print length}'`
			if [ "$len" -ne 6 ]; then
				if [ "$len" -ne 8 ]; then
					echo "Invalid tape serial found: " $1
					exit 1;
				fi
			fi
			tape_found="true";
			myarr[${#myarr[*]}]=$1;;
        esac
        shift;
done

if [ -z "$tape_device" -a "${tape_device+xxx}" = "xxx" ]; then
	echo ${usage_str}
	exit 5;
fi

if [ -z "$tape_found" -a "${tape_found+xxx}" = "xxx" ]; then
	echo "No tape serials specified."
	exit 6
fi

echo ""
echo "*****************************"
echo "Formatter settings"
echo "*****************************"
echo Force option: $force_format
echo Tape device id: $tape_device
echo ""
echo Tape serials:

for i in "${myarr[@]}"; do  # echoes one line for each element of the array.
   echo $i
done

echo ""
echo "The formatting tool is provided with no warranty.  This script is soley for the use of authorized support representitives of StorageDNA.  By confirming your format you awcknowledge that you are authorized to run this tool."
echo "Ready to format?"
ConfirmOrExit
result=""

for i in $"${myarr[@]}"; do

   echo ""
   echo "Loading tape $i in ${tape_device}..."
   result=`${app_path}/dnaltman mounttape -d ${tape_device} -t $i -nomount -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo "Unable to load tape $i from device ${tape_device} [$rc]"
	echo $result;
	exit $rc 
   fi 

   echo "Checking tape $i in ${tape_device} to ensure it is unmounted..."
   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo "Unable to ensure tape is unmounted $i from device ${tape_device} [$rc]"
	echo $result;
	exit $rc 
   fi 
   
   echo "Formatting tape $i in ${tape_device} [force=${force_format}]..."
   if [ ${force_format} == "true" ]; then
   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -force -lock`
   else
   	result=`${app_path}/dnaltman formattape -d ${tape_device} -t $i -nomount -lock`
   fi
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo "Unable to format tape $i from device ${tape_device} [$rc]"
	echo result
	exit $rc 
   fi 

   echo "Unloading tape $i from ${tape_device}..."
   result=`${app_path}/dnaltman unmounttape -d ${tape_device} -t $i -unloadtape -lock`
   rc=$?
   if [[ $rc != 0 ]] ; then
	echo "Unable to unload tape $i from device ${tape_device} [$rc]"
	echo $result
	exit $rc 
   fi 

done

echo "Formatting completed."


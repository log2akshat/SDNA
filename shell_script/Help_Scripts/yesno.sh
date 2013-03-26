# Call the function every time you need the user to confirm...

For example


#!/bin/sh

# First we define the function
function ConfirmOrExit() {
while true
do
echo -n "Please confirm (y or n) :"
read CONFIRM
case $CONFIRM in
y|Y|YES|yes|Yes) break ;;
n|N|no|NO|No)
echo Aborting - you entered $CONFIRM
exit
;;
*) echo Please enter only y or n
esac
done
echo You entered $CONFIRM. Continuing ...
}

# At the end we put the main program

... # Do stuff here
ConfirmOrExit
... # Do more stuff here
ConfirmOrExit
... # etcettera


echo 
echo "Digital Clock for Linux"
echo "To stop this clock use command kill pid, see above for pid"
echo "Press a key to continue. . ."

while :
do
    ti=`date +"%r"`      
    echo -e -n "\033[7s"    #save current screen postion & attributes
    #
    # Show the clock
    #
    
    tput cup 0 69          # row 0 and column 69 is used to show clock
    
    echo -n $ti            # put clock on screen
     
    echo -e -n "\033[8u"   #restore current screen postion & attributs
    #
    #Delay fro 1 second
    #
    sleep 1
done

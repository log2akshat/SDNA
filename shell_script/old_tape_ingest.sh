#!/bin/bash

#Tape Ingest Script.
#.....................................

#Temporary Files
list_files=".list_files"

#variable declaraions
working_dir=`pwd`
tape_dir="/home/akshat/Desktop/Ingest"
index_tape_dir="/home/akshat/Desktop/Ingest/Index"

#Goes to the folowing directory and does listing of all files in it.
cd $tape_dir

#List all the files based on the modification time.
ls -Alutrh | awk 'NF>2' > $working_dir/$list_files

#Iterate over the number of rows to find the number of files.
num_of_rows=`ls -Altrh | awk 'NF>2' | wc -l`
echo "Total number of files are : $num_of_rows"

#Iterate over the rows of files and derive the attributes from it to write xml out of it.
for (( i=1; i<=$num_of_rows; i++ ));
#Reading the list file.
#echo "Reading the attributes from the directory files..."
do
#filename=`awk '{
#	for (i = 1; i <= NR; i++)
#        filename = $9
#        print filename
#}' $working_dir/$list_files`
#filename=`awk '{filename = $9; print filename}' $working_dir/$list_files | awk '{for (i=1; i<=NR; i++); print NR}'`
#filename=`awk '{filename = $9; print filename}' $working_dir/$list_files | awk '{for (i=1; i<=NR; i++); print $1}'`
`awk '{filename = $9; print filename}' $working_dir/$list_files | awk '{for (j=1; j<=NR; j++);
   print "<file type=\"file\">" > $i.xml
   print "<filename><![CDATA[" $i "]]></filename>" >> $i.xml
   print "<actions>" >> $i.xml
   print "<action version=\"$i\">" >> $i.xml
   print "</actions>" >> $i.xml
   print "</file>" >> $i.xml }'`
done

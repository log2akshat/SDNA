#!/bin/bash

#Tape Ingest Script.
#.....................................

#Temporary Files
list_files=".list_files"

#variable declaraions
working_dir=`pwd`
tape_dir="/home/akshat/Desktop/Ingest"
index_tape_dir="/home/akshat/Desktop/Ingest_Index"

#Goes to the folowing directory and does listing of all files in it.
cd $tape_dir

#List all the files based on the modification time.
ls -Altr --time-style=+%s | awk 'NF>2' > $working_dir/$list_files

#Iterate over the number of rows to find the number of files.
num_of_rows=`ls -Altrh | awk 'NF>2' | wc -l`
echo "Total number of files are : $num_of_rows"

#Iterate over the rows of files and derive the attributes from it to write xml out of it.
for (( i=1; i<=$num_of_rows; i++ ));
#Reading the list file.
#echo "Reading the attributes from the directory files..."
do
filename=`awk -v j=$i 'FNR == j {filename = $7; print filename}' $working_dir/$list_files | awk '{for (i=1; i<=NR; i++); print $1}'`
#raw_filename=`awk -v j=$i 'FNR == j {filename = substr($0, index($0,$9)); print filename}' $working_dir/$list_files | awk '{for (i=1; i<=NR; i++); print substr($0, index($0,$1))}'`
#echo -e '\033[01;31m'$filename'\033[00;00m' | sed s'/ /\\ /g'
chksum=`md5sum \"$filename\"` #| cut -d" " -f1`
eval $chksum
#chksum=`md5sum $filename | cut -d" " -f1`
runtime=`date +%Y%m%d`"-"`date +%H%M%S`
#`awk '{filename = $9; print filename}' $working_dir/$list_files | awk '{for (j=1; j<=NR; j++);
#while true; do
#awk 'BEGIN {
 #  print "<file type=\"file\">"}
#NF==9 {
 #  print("<filename><![CDATA["$9"]]></filename>\n");
 #  print("<actions>\n");
 #  print("<action mod-time=\"" $8 "\" />\n");
#	}
#END {
 #  print("</actions>\n");
 #  print("</file>");
#}' $working_dir/$list_files > $index_tape_dir/$i.xml
#done
awk -v "j=$i" -v "spath=$tape_dir" -v "run=$runtime" -v "checksum=$chksum" 'FNR == j {print("<file type=\"file\">");
		print("<filename><![CDATA["$7"]]></filename>");
		print("<source-path><![CDATA["spath"]]></source-path>");
		print("<actions>"); print("<action version=\"1\" size=\"" $5 "\" mod-time=\"" $6 "\" run=\"" run "\" checksum=\"" checksum "\" write-time=\"" $6 "\" write-index=\"" j  "\" type=\"upd\" />");
		print("</actions>"); print("</file>")
}' $working_dir/$list_files > $index_tape_dir/$filename.xml
done

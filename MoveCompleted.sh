#!/bin/bash

#exec >> /home/deluge/scripts/MoveCompleted.log
#exec 2>&1
#Envronmental Variables
#Change the below options to meatch your environment.

#filePath represents the folder that you want this script to scan, typically your torrent completed download directory
filePath="/home/deluge/completed"

#fileTypes is the comma seperated list of file types you want to scan for.
fileTypes="mkv,avi,mp4,rar"

#finalDestination is the directory that you want Sonarr/Radarr to monitor, typically as a  "remote path".
finalDestination="/home/deluge/sonarrcompleted"

#completedList is the running list of files that have been coppied by this script, to prevent re-copying.
completedList="/home/deluge/scripts/completedList"

#completedListRAR is the same value, but specifically for RAR files, seperated for better visibility
completedListRAR="/home/deluge/scripts/completedListRAR"

#chmodSwitch set to TRUE will execute the chmod command on all new created directories and files
chmodSwitch="True"

#chmodNumber will set the permission level for each new directory and folder
chmodNumber="775"

main() {
	trap "rm -f /home/deluge/scripts/MoveCompleted.sh.lock" SIGINT SIGTERM
	if [ -e /home/deluge/scripts/MoveCompleted.sh.lock ]
	then
		echo "MoveCompleted is already running."
		exit 1
	else
	#do work
		echo "*******************************"
		dt=$(date '+%m/%d/%Y %H:%M:%S');
		echo "$dt MoveCompleted is now running."
		touch /home/deluge/scripts/MoveCompleted.sh.lock
		moveFiles
		moveRAR
		dt2=$(date '+%m/%d/%Y %H:%M:%S');
		echo "$dt2 MoveCompleted is now finished."
		echo "*******************************"
		rm -f /home/deluge/scripts/MoveCompleted.sh.lock
		trap - SIGINT SIGTERM
		exit 0
	fi

}

moveFiles() {
	#get the file type we are scanning for.
	filetype="mkv"
	echo "Scanning for $filetype files..."
	mapfile -t fileArrayTMP < <(find $filePath -type f | grep $filetype | grep -v "sample")
	echo "${#fileArrayTMP[@]} $filetype files found:"
	for (( i=0; i<${#fileArrayTMP[@]}; i++ ));
	do
		grep -q -F ${fileArrayTMP[i]} $completedList
		if [ $? = "0" ] ; then
			echo "Already Exists: " $(basename "${fileArrayTMP[i]}")
		else
			echo "New file:" $(basename "${fileArrayTMP[i]}")
			DIR=$(basename $(dirname "${fileArrayTMP[i]}"))
			if [ $DIR = "completed" ] ; then
				#not in a subfolder, just copy it
				echo "  -Not in a subfolder, making a copy to $finalDestination"
				cp --no-preserve=mode,ownership ${fileArrayTMP[i]}  $finalDestination/$(basename "${fileArrayTMP[i]}")
			else
				#its in a subfolder. mkdir and copy
				echo "  -In a subfolder, making a copy to $finalDestination/$DIR"
				mkdir -p $finalDestination/$DIR
				cp --no-preserve=mode,ownership ${fileArrayTMP[i]}  $finalDestination/$DIR/$(basename "${fileArrayTMP[i]}")
			fi
			echo "  -Adding to $completedList..."
			echo ${fileArrayTMP[i]} >> $completedList
			echo "  -Add completed."
		fi
	done
	echo "Done scanning for $filetype files..."

}

moveRAR() {
	echo "Scanning for RAR Archive files..."
	mapfile -t fileArrayTMP < <(find $filePath -type f | grep "rar")
	echo "${#fileArrayTMP[@]} RAR files found:"
	for (( i=0; i<${#fileArrayTMP[@]}; i++ ));
	do
		grep -q -F ${fileArrayTMP[i]} $completedListRAR
		if [ $? = "0" ] ; then
			echo "Already Exists: " $(basename "${fileArrayTMP[i]}")
		else
			echo "New file:" $(basename "${fileArrayTMP[i]}")
			DIR=$(basename $(dirname "${fileArrayTMP[i]}"))
			echo "  -Making new folder $finalDestination/$DIR"
			mkdir $finalDestination/$DIR
			if [ $chmodSwitch = "True" ] ; then
				echo "  -Setting folder permission to $chmodNumber"
				chmod $chmodNumber $finalDestination/$DIR
			fi
			echo "  -Extracting RAR Archive to current folder: ${fileArrayTMP[i]}"
			extractedDIR=$(dirname ${fileArrayTMP[i]})
			echo "  -The extracted dirname is $extractedDIR"
			7z e -o$extractedDIR ${fileArrayTMP[i]} -y
			echo "  -Extracting completed."
			echo "  -Getting extracted file name"
			fileName=$(7z l -slt ${fileArrayTMP[i]} | grep -e '^Path.*$' | grep -e '.*[^rar]$' | cut -c8-)
			echo "  -File extracted: $fileName"
			fullExtractedPath="$extractedDIR/$fileName"
			echo " -- Full Path Extracted: $fullExtractedPath"
			echo "  -Moving $extractedDIR/$fileName file to $finalDestination/$DIR/$fileName"
			cp --no-preserve=mode,ownership -f $fullExtractedPath $finalDestination/$DIR/$fileName && rm $fullExtractedPath
			echo "  -Move complete."
			if [ $chmodSwitch = "True" ] ; then
				echo "  -Setting file permission to $chmodNumber"
				chmod $chmodNumber $finalDestination/$DIR/$fileName
			fi
			echo "  -Adding to $completedList..."
			echo ${fileArrayTMP[i]} >> $completedListRAR
			echo "  -Add completed."
			echo "***************************"
		fi
	done
	echo "Done scanning for RAR Archive files..."

}

main

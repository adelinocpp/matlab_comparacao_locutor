#!/bin/bash
#=============================================================#
# Name:         Space to Underscore                           #
# Description:  Recursively replace spaces with underscores   #
#               in file and directory names.                  #
# Version:      ver 1.2                                       #
# Data:         16.6.2014                                     #
# Author:       Arthur Gareginyan                             #
# Author URI:   https://www.arthurgareginyan.com              #
# License:      GNU General Public License, version 3 (GPLv3) #
# License URI:  http://www.gnu.org/licenses/gpl-3.0.html      #
#=============================================================#

#               	USAGE:
#		chmod +x space_to_underscore.sh
#		cd /home/user/example
#		~/space_to_underscore.sh

# Check for proper priveliges
# [ "`whoami`" = root ] || exec sudo "$0" "$@"


################### SETUP VARIABLES #######################
number=0                    # Number of renamed.
number_not=0		    # Number of not renamed.
IFS=$'\n'
array=( `find ./ -type d` ) # Find catalogs recursively.


######################## GO ###############################
# Reverse cycle.
for (( i = ${#array[@]}; i; )); do
     # Go in to catalog.
     pushd "${array[--i]}" >/dev/null 2>&1
     # Search of all files in the current directory.
     for name in *
     do
     	     # Check for spaces in names of files and directories.
	     echo "$name" | grep -q " "
	     if [ $? -eq 0 ]
	     then
	     	# Replacing spaces with underscores.
	        newname=`echo $name | sed -e "s/ /_/g"`
            #newname=`echo $name | sed -e "s/[/\\?&%*:;|"<>-]'/_/g"`
		if [ -e $newname ]
        	then
			let "number_not +=1"
                	echo " Not renaming: $name"
        	else
        		# Plus one to number.
                	let "number += 1"
                    	# Message about rename.
                	echo "$number Renaming: $name"
                	# Rename.
		        mv "$name" "$newname"
		fi
	     fi
     done
     # Go back.
     popd >/dev/null 2>&1
done

echo -en "\n\tTodas operacoes completadas."

if [ "$number_not" -ne "0" ]
  then echo -en "\n\t $number_not n??o renomeados."
fi

if [ "$number" -eq "0" ]
  then echo -en "\n\tNada foi renomeado.\n"
elif [ "$number" -eq "1" ]
   then echo -en "\n\t $number renomeado.\n"
   else echo -en "\n\tArquivos e diretorios renomeados: $number\n"
fi
echo "Fim do script S00_Space_To_Underscore"
exit 0

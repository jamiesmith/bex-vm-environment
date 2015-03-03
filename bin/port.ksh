#!/bin/ksh

CHECK_OUT=0

CHECK_OUT_COMMAND="sw_sccs get"

typeset sedFile

function checkPermissions
{
        file=$1
        if [ ! -w $file ]
        then
                if [ $CHECK_OUT -eq 1 ]
                then
                        print "configured to check out, getting file $file"
                        $CHECK_OUT_COMMAND $file
                else
                        print "Skipping non-writable file $file"
                fi
        fi
}

function doPort
{
        issol=`pwd | grep "/sol/" | wc -l | awk '{print $1}'`
        if [ $issol -eq 1 ]
        then
                # we don't need to change back, the shell
                # will leave us where we were when we started
                cd sol generic 
        fi
        
        if [ $# -eq 0 ]
        then
                filelist="*.act *.soc *.sdl *.xml"
        else
                filelist="$*"
        fi
        
        for file in $filelist
        do
                checkPermissions $file

                if [ -w $file ]
                then
                        if [ -x $file ]
                        then
                                typeset -i executable=1
                        else
                                typeset -i executable=0
                        fi
                        
                        # ls -l $sedFile $file
			ls -l $file
                        ${sedFile} $file > tmpfile
                        typeset -i size=`ls -lL tmpfile | awk '{print $5}'`
                        
                        if [ $size -gt 0 ]
                        then
                                mv tmpfile $file
                                if [ $executable -eq 1 ]
                                then
                                        chmod +x $file
                                fi
                                ls -l $file
                        else
                                print ARG! $file is zero size
                        fi
                        print ""
                fi
        done
}

while getopts "c" option
do
        case $option in
                c)
                        CHECK_OUT=1
                        ;;
        esac
done

shift $((${OPTIND} - 1))

sedFile="$(basename $0 .ksh).sed"
if [ -z "$sedFile" ]
then
        sedFile=port.sed
fi    
print "\n${sedFile} Using Sed File: `which ${sedFile}` \n"

doPort $*

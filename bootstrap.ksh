#!/bin/ksh

# link the files in the bootstrap to their same counterpart in $HOME/

function linkUpFile
{
    typeset file=$1
    echo $file
    
    destFile="$HOME/$file"
    if [ -f "${destFile}" ]
    then
	mv "${destFile}" "${destFile}.bootstrap" 
    fi

    echo ln -s "$(pwd)/$file" "${destFile}"
    ln -s "$(pwd)/$file" "${destFile}"
}

path_to_files=$(dirname $0)
cd ${path_to_files}

for file in .[a-z]*
do
	if [ $file = ".git" ]
	then
		continue
	fi
	
        linkUpFile $file
	
done

mkdir -p $HOME/bin
cp -r ./bin $HOME/

cd $HOME/

## install some other stuff
#
${path_to_files}/install-maven.ksh


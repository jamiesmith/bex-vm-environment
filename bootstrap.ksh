#!/bin/ksh

# link the files in the bootstrap to their same counterpart in 

function linkUpFile
{
    typeset file=$1
    echo $file
    
    destFile="${homedir}/$file"
    if [ -f "${destFile}" ]
    then
	mv "${destFile}" "$$SSH ${SSH_USER}@${publicip} echo ok

{destFile}.bootstrap" 
    fi

    echo ln -s "$(pwd)/$file" "${destFile}"
    ln -s "$(pwd)/$file" "${destFile}"
}

homedir=$(pwd)
echo "HOMEDIR BETTER BE: ${homedir}"

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

mkdir -p ${homedir}/bin
cp -r ./bin ${homedir}/

cd ${homedir}/

## install some other stuff
#
${path_to_files}/install-java.ksh
${path_to_files}/install-maven.ksh


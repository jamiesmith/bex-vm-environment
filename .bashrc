# .bashrc

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions

env -i

ECHO=echo

SetenvDir() 
{ 
	eval "$1=$2 export $1";
	if [ ! -d $2 ]
	then
		$ECHO "$0: SetenvDir: warning: $2 does not exist"
	fi
}

Setenv() 
{ 
	eval "$1=$2 export $1";
}

Addpath()
{
    if [ -n "$PATH" ]
    then
	PATH=$PATH:$1 export PATH
    else
	PATH=$1 export PATH
    fi
    if [[ "$PATH" != *:* && ! -d $1 ]]
    then
	$ECHO "$0: Addpath: warning: $1 does not exist"
    fi
}

Addlpath()
{
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$1 export LD_LIBRARY_PATH
	if [ ! -d $1 ]
	then
		$ECHO "$0: Addlpath: warning: $1 does not exist"
	fi
}

AddClassPath()
{
	CLASSPATH=$CLASSPATH:$1 export CLASSPATH

	if [ ! -f $1 ]
	then 
		$ECHO "$0: AddClassPath: warning: $1 does not exist"
	fi
}

Addman()
{
	MANPATH=$MANPATH:$1 export MANPATH

	if [ ! -d $1 ]
	then
		$ECHO "$0: Addman: warning: $1 does not exist"
	fi
}


function newf
{
    ls -ltF "$@" | head -25
}

function mcd
{
    mkdir "$@"
    cd "$@"
}

function hgrep
{
    history 1000 | grep "$@"
}

Setenv TIBCO_HOME $HOME/tibco
Setenv SW_HOME $TIBCO_HOME/be-x/1.3.0
Setenv EDITOR emacs

ulimit

SavePath=$PATH
PATH="" export PATH

Addpath .
Addpath ~/bin
Addpath ~/findgrep
Addpath ~/GITROOT/interac_gateway_poc/scripts
Addpath $SavePath
# TMP Addpath $JAVA_HOME/bin
Addpath /bin 
Addpath /usr/bin 
Addpath /usr/local/bin 
Addpath /usr/local/maven/bin 
Addpath /usr/sbin           
Addpath /etc        
Addpath /sbin 
Addpath $SW_HOME/distrib/kabira/bin
Addpath $SW_HOME/distrib/kabira/scripts
Addpath $TIBCO_HOME/tibcojre64/1.7.0/bin

alias ls="ls -F"
alias l="ls -l"
alias md="mkdir"
alias me="ps -fu $USER"
alias p="more -c"
alias clean="rm *~"
alias h="history"
alias j="jobs"
alias xe="chmod +x"
alias cd..="cd .."
alias cd...="cd ../.."
alias pd=pushd
alias po=popd
alias rd="rm -rf"
alias tt="exec tcsh"

set completion-ignore-case on
set show-all-if-ambiguous on
set completion-map-case on

PS1="\e[1m\u@\h\e[m[\t]\w % > "

## export $(gnome-keyring-daemon)

Setenv TERM vt102
SetenvDir POC_GIT_ROOT=$HOME/GITROOT/interac_gateway_poc

if [ -f $HOME/.amazon_aws ]
then
    . $HOME/.amazon_aws
fi

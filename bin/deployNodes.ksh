#!/bin/ksh
#
# Name
#	deployNode.ksh
#
# Copyright
#	Confidential Property of TIBCO Software, Inc.
#	Copyright 2013 by TIBCO Software, Inc.
#	All rights reserved.
#
# History
#	$Revision: $ $Date: $
#	$Source: $
#

# default the host to kabira-server.local, but allow it to be overridden
#
host=${BEX_HOST:=localhost}

unitTestMacro=""

function die
{
	echo "ERROR: " $*
	exit 2
}

function dieUsage
{
    cat <<EOF
deployNode.ksh- 

automatically infer and execute the deploy command based on project directory

Note that the script will look for an EAR file with the same name as the project
in the users ~/Temp directory.  It will also look for potentially updated files
that might indicate that the EAR is out of date.  If it finds out-of-date files,
the deployment will stop and a warning will be issued (if you have a mac it
swears at you.)

usage: deployNode.ksh [-a adminPort] [-d] [-e] [-f simFlag=value] [-g debugPort] [-h hostName] [-n nodeName] [-p httpOverridePort] [-r] [-s] [-S true|false] [-t] [-x otherDefines] [-x]
where:
	[-a] AdminPort, default is 2001
	[-A] Application Mode [true|false] specify whether or not to start the application
	[-c] Specify the CDD.  Default is to use the first one it finds
	[-d] Detach once deployed
	[-e] simply echoes out the the deploy command
	[-f] Set a flag to true, for example -f 
	[-g port] enables remote debugging on the deployed archive
	[-h host] HostName, default is ${host}, override with BEX_HOST env var
	[-n NodeName] infer the port number based on node name (A, B, etc)
	[-p port] shortcut for 	-Dtibco.clientVar.HTTPConfiguration/Port=port} 
	[-r] if passed, -reset is sent to the node
	[-s] (SingleNode) shortcut for -x GlobalConfig/LoadHA=false
	[-S value] Simulator Node.  Sets applicable flag to true or false
	[-t] (Test Mode) shortcut for -x GlobalConfig/RunUnitTests=true
	[-T] Automagically tail -f the app out file
	[-x] set a specific Variable
	[-X] enable flight recorder
	[-w pause] wait for the specified period- useful when starting a sim first, to delay other nodes
	[-z port] Enables SUSPENDED remote debugging on the deployed archive.
	          Waits for debugger to connect to lauch
EOF

    if [ -n "$*" ]
    then
	die $*
    else
	exit 0
    fi
}

# Some sane defaults
#
adminport=2001
reset=true
detach=false
echoOnly=false
typeset -u node=A
httpPort=4400
otherDefines=""
suspendString=""
debugjunk=""
copytarget=""
typeset cddSpec=""
typeset forceStart="false"
typeset debugPort
typeset waitFirst=0
typeset -l startSimulators=true
typeset -l startApplication=true
typeset -l tailFile=false

# This assumes that it is being launched from the root of the project
# Can be overridden in options
#
if [ -f deployment/*.cdd ]
then
    cddSpec=$(ls deployment/*.cdd | head -1)
else
    cddSpec=$(ls Deployments/*.cdd | head -1)
fi

while getopts "A:a:c:deFf:g:h:n:p:P:rsS:tTx:w:z" option
do
	case $option in
	    a)
		adminport=$OPTARG
		;;
	    A)
		startApplication=$OPTARG
		;;
	    c)
		cddSpec=$OPTARG
		;;
	    d)
		detach=true
		copytarget="copytarget=true"
		;;
	    e)
		echoOnly=true
		;;
	    F)
		forceStart="true"
		;;
	    g|z)
		if [ $option = "z" ]
		then
		    suspendString="suspend=true"
		elif [ $option = "g" ]
		then
		    debugPort="$OPTARG"
		fi
		# Handle them both to avoid fouling it up
		#
		debugjunk="remotedebug=true remotedebugport=${debugPort} $suspendString"
		dashD="-d"
		;;
	    h)
		host=$OPTARG
		;;
	    n)
		node=$OPTARG
		case $node in
		    A)
			adminport=2001
			;;
		    B)
			adminport=2002
			;;
		    C)
			adminport=2003
			;;
		    SIMS)
			adminport=2004
			;;
		esac
		;;
	    p)
		httpPort=$OPTARG
		;;
	    r)
		reset=true
		;;
	    s)
		otherDefines="-Dtibco.clientVar.GlobalConfig/LoadHA=false $otherDefines"
		;;
	    S)
		startSimulators=$OPTARG
		;;
	    t)
		unitTestMacro="-Dtibco.clientVar.GlobalConfig/RunUnitTests=true -enableassertions"
		;;
	    T)
		tailFile=true
		;;
	    x)
		otherDefines="-Dtibco.clientVar.${OPTARG} $otherDefines"
		;;
	    X)
		-XX:+UnlockCommercialFeatures -XX:+FlightRecorder  \
		;;


	    w)
		waitFirst=$OPTARG
		;;
	    *)
		dieUsage invalid option
		;;
	esac
done

shift $((${OPTIND} - 1))

# Set up the node start options (simulator and/or application)
#
otherDefines="-Dtibco.clientVar.Flags/StartApplication=$startApplication $otherDefines"
otherDefines="-Dtibco.clientVar.Flags/StartSimulators=$startSimulators $otherDefines"



function startNode
{
    node=$1
    httpPort=$2

# figure out the version we are on and get that jar
#
DEPLOY_JAR=$TIBCO_HOME/be-x/*/sdk/deploy.jar

DEPLOY_COMMAND="java -jar $DEPLOY_JAR \
	hostname=${host} \
	detach=$detach \
	${copytarget} \
	username=guest \
	password=guest \
	adminport=${adminport} \
	${debugjunk} \
	reset=$reset \
	-Dtibco.clientVar.HTTPConfiguration/Port=${httpPort} \
	$otherDefines \
	$unitTestMacro \
	-enableassertions \
	$earFile \
	descriptor=$cddSpec ${dashD}"

echo "DEPLOY COMMAND:"
echo $DEPLOY_COMMAND  | tr " " "\n" | awk '{print "\t" $0}'
echo ""

if [ "$echoOnly" = "false" ]
then
    if [ $waitFirst -gt 0 ]
    then
	echo "pausing for $waitFirst seconds before deploy"
	sleep $waitFirst
    fi
    $DEPLOY_COMMAND

    if [ $tailFile = true -a $detach = true ]
    then
	# Find the file
	#
	logFile=$(ls -t /opt/kabira/run/ast/nodes/$node/${appName}_ear*.out | head -1)
	
	echo "######################################################################"
	echo "#                        TAILING THE LOG FILE                        #" 
	echo "######################################################################"
	
	tail -50f $logFile
    fi
fi

}

function newFiles
{
    find . -type f -newer $earFile | egrep -v "^scripts|^./.deploy.sar|^html|Deployments|readme|README|.beproject|target/|OUT" 
}

function checkOutOfDate
{
    [ $forceStart = true ] && return
    newCount=$(newFiles | wc -l)

    if [ $newCount -gt 0 ]
    then
	newFiles

	[ -x /usr/bin/say ] && /usr/bin/say "rebuild the ear file"

	die "Looks like the ear is out of date!"
    fi
}


appName=$(basename $PWD)
earDir=~/EarFiles

earFile=./target/$appName-1.0.0-SNAPSHOT.ear

if [ ! -f $earFile ]
then
    earFile=${earDir}/$appName.ear
fi

[ -f "$cddSpec" ] || die "CDD specification [${cddSpec}] not found"
[ -f "$earFile" ] || die "EAR file $earFile not found"


if [ "$echoOnly" = "false" ]
then
    checkOutOfDate
fi

startNode $node $httpPort


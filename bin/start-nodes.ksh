#!/bin/ksh

Run=/opt/kabira/run/be-x

nodelist="A B C"

MEMORYTYPE=sysvshm
MEMORYSIZE=384
DMPORT=2000
APORT=2001
BPORT=2002
CPORT=2003
MODEL=dummy
BUILDTYPE=PRODUCTION

function startDomainManager
{
    administrator install node \
	application=kabira/kdm \
	adminport=$DMPORT \
	memorysize=$MEMORYSIZE \
	memorytype=$MEMORYTYPE \
	nodename=domainmanager \
	buildtype=$BUILDTYPE \
	installpath=$Run/nodes/domainmanager \
	deploydirectories=$Run/deploy \
	configpath=$Run/configuration/domainmanager
    
    administrator adminport=$DMPORT start node && print "Node domainmanager start succeeded"

    administrator adminport=$DMPORT addgroup domain groupname=dummy && print "Added Dummy Group"

    
}

function startNode
{
    typeset -u nodeName=$1

    case $nodeName in
	A)
	    adminPort=$APORT
	    ;;
	B)
	    adminPort=$BPORT
	    ;;
	C)
	    adminPort=$CPORT
	    ;;
	*)
	    echo "Error, node $nodeName not supported"
	    exit
    esac
	

    administrator install node \
	adminport=$adminPort \
	memorysize=$MEMORYSIZE \
	memorytype=$MEMORYTYPE \
	nodename=$nodeName \
	buildtype=$BUILDTYPE \
	installpath=$Run/nodes/$nodeName \
	deploydirectories=$Run/deploy \
	configpath=$Run/configuration/$nodeName


    administrator adminport=${adminPort}  start node
    administrator adminport=$DMPORT addnode domain name=${nodeName}
    administrator adminport=$DMPORT addgroupnode domain groupname=$MODEL name=${nodeName}
}


# JRS administrator install node adminport=$CPORT nodename=C buildtype=$BUILD memorytype=sysvshm memorysize=384
# JRS administrator adminport=$CPORT  start node
# JRS administrator adminport=$DMPORT addnode domain name=C
# JRS administrator adminport=$DMPORT addgroupnode domain groupname=$MODEL name=C

if [ $# -eq 0 ]
then

    startDomainManager

    # Start all of the nodes
    #
    for node in $nodelist
    do
	startNode $node
    done


# JRS startNode

else
    for node in $*
    do
	startNode $node
    done
fi

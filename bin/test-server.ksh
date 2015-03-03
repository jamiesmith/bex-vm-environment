#!/bin/ksh -p
#
#	$Revision: 1.6 $ $Date: 2011/07/28 19:51:21 $
#
#	default test server init script for maven projects
#

. $SW_HOME/distrib/kabira/ast/include/test-server.env
# . $POC_GIT_ROOT/scripts/fluency-server.env

Distrib=$SW_HOME/distrib
InstallPath=$SW_HOME/BUILD/run
IP=127.0.0.1
ProductName=test

Run=/opt/kabira/run
InstallPath=$Run
ProductName=jrs
BuildType=PRODUCTION

### Application=kabira/ast
Application=tibco/be-x

Node[0]="A memorysize=384 memorytype=sysvshm"
Node[1]="B memorysize=384 memorytype=sysvshm"
# Skipping C to see if we can activate a partition without the other node there
# Node[2]="C memorysize=384 memorytype=sysvshm"

function DisableDatagrid
{
    print "Disabling data grid"
    
    typeset kdmconfig=$Run/configuration/domainmanager/node/kabira/kdm
    
    sed -e "/dataGrid =/,/};/s+^+\/\/+" $kdmconfig/90-applicationconfig/kdm.kcs \
	> $kdmconfig/90-applicationconfig/kdm.kcs.tmp
    
    rm $kdmconfig/90-applicationconfig/kdm.kcs
    mv $kdmconfig/90-applicationconfig/kdm.kcs.tmp $kdmconfig/90-applicationconfig/kdm.kcs
}

function doStart
{
    set -e
    
    ParseArgs "$@"
    
    Initialize
    Install  
    
    DisableDatagrid
    
    Start
    
    mkdir -p target
    print -- "-Dcom.kabira.fluency.administrationPort=$domainmanager_adminport" \
	> target/server.options
    
# build a local settings.xml file
#
    echo "
<settings>
	<profiles>
		<profile>
			<id>set-properties</id>
			<properties>
			<com.kabira.fluency.administrationPort>$domainmanager_adminport</com.kabira.fluency.administrationPort>
			</properties>
		</profile>
	</profiles>

<activeProfiles>
	<activeProfile>set-properties</activeProfile>
</activeProfiles>" > target/settings.xml

    if [ -f $HOME/.m2/settings.xml ]
    then
	sed -e '/<servers>/,/<\/servers>/!d' $HOME/.m2/settings.xml >> target/settings.xml
    fi
    echo "</settings>" >> target/settings.xml
    
    return 0
}

function doRemove
{
    Initialize
    Remove
}

function doStop
{
    Initialize
    Stop
}

typeset -l command="$1"

case "$command" in
    install|start)
	doStart $command
	;;
    stop)
	doStop $command
	;;
    remove)
	doRemove $command
	;;
    restart)
	if [ -d $Run/logs ]
	then
	    echo "Doing remove..."
	    doRemove remove
	else
	    echo "Skipping remove, not installed"
	fi
	
	echo "Doing start..."
	doStart start
	;;
    *)
	InitMain "$@"
	return 0
esac

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

TIBCO_HOME=$HOME/tibco
PATH=/opt/kabira/3rdparty/generic/maven/3.0.4/bin:$PATH
if [ -d $TIBCO_HOME/tibrv/8.3 ]
then
	PATH=$PATH:$TIBCO_HOME/tibrv/8.3/bin
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TIBCO_HOME/tibrv/8.3/lib:$TIBCO_HOME/tibrv/8.3/lib/64
fi
if [ -d $TIBCO_HOME/tibrv/8.4 ]
then
	PATH=$PATH:$TIBCO_HOME/tibrv/8.4/bin
	LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$TIBCO_HOME/tibrv/8.4/lib:$TIBCO_HOME/tibrv/8.4/lib/64
fi

if [ -d $TIBCO_HOME/be-x/1.3.0 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.3.0
elif [ -d $TIBCO_HOME/be-x/1.2.0 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.2.0
elif [ -d $TIBCO_HOME/be-x/1.1.2 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.1.2
elif [ -d $TIBCO_HOME/be-x/1.1.1 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.1.1
elif [ -d $TIBCO_HOME/be-x/1.1.0 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.1.0
elif [ -d $TIBCO_HOME/be-x/1.0.4 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.0.4
elif [ -d $TIBCO_HOME/be-x/1.0.3 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.0.3
elif [ -d $TIBCO_HOME/be-x/1.0.2 ]
then
	SW_HOME=$TIBCO_HOME/be-x/1.0.2
fi

BEX_HOME=$SW_HOME
PATH=$PATH:$SW_HOME/distrib/kabira/bin
PATH=$PATH:$HOME/bin
     
JAVA_HOME=/opt/kabira/3rdparty/linux/jdk/1.7.0_67_x86_64

JAVA_HOME=
# JAVA_HOME=/opt/kabira/3rdparty/linux/jdk/1.7.0_25_x86_64
JAVA_BINDIR=${JAVA_HOME}/bin
JAVA_ROOT=${JAVA_HOME}
JDK_HOME=${JAVA_HOME}
JRE_HOME=${JAVA_HOME}
SDK_HOME=${JAVA_HOME}
PATH=${JAVA_HOME}/bin:$PATH
     
MALLOC_ARENA_MAX=1

export SW_HOME TIBCO_HOME PATH JAVA_HOME JAVA_BINDIR JAVA_ROOT JDK_HOME JRE_HOME SDK_HOME LD_LIBRARY_PATH MALLOC_ARENA_MAX


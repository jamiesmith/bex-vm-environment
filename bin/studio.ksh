#!/bin/ksh

cd $TIBCO_HOME/be/5.1/studio/eclipse/

./studio $* >> /tmp/studio.log.$USER 2>&1 &

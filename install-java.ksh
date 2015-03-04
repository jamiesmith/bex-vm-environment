#!/bin/ksh

JDK_URL=http://download.oracle.com/otn-pub/java/jdk/7u75-b13/jdk-7u75-linux-x64.tar.gz
JDK_VERSION=jdk1.7.0_75

if [[ $EUID -ne 0 ]]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cd /opt

basefile=$(basename $JDK_URL)

wget --no-cookies --no-check-certificate \
    --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" \
    --output-document $basefile \
    $JDK_URL

tar xzvf ${basefile}
chown -R root: ${JDK_VERSION}

alternatives --install /usr/bin/java java /opt/${JDK_VERSION}/bin/java 1
alternatives --install /usr/bin/javac javac /opt/${JDK_VERSION}/bin/javac 1
alternatives --install /usr/bin/jar jar /opt/${JDK_VERSION}/bin/jar 1

rm $basefile

cd -

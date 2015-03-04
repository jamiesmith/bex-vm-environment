#!/bin/ksh

if [[ $EUID -ne 0 ]]
then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cd $HOME
mkdir scratch
cd scratch
maven_version=3.2.5
wget http://apache.osuosl.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz
tar xzf apache-maven-${maven_version}-bin.tar.gz -C /usr/local

cd /usr/local
ln -s apache-maven-${maven_version} maven
cd -
cat << 'EOF' > maven.sh
export M2_HOME=/usr/local/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF

mv maven.sh /etc/profile.d/maven.sh
chown root:root /etc/profile.d/maven.sh
cd -

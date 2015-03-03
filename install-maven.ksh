#!/bin/ksh

mkdir scratch
cd scratch
maven_version=3.2.5
wget http://apache.osuosl.org/maven/maven-3/${maven_version}/binaries/apache-maven-${maven_version}-bin.tar.gz
sudo tar xzf apache-maven-${maven_version}-bin.tar.gz -C /usr/local
cd /usr/local
sudo ln -s apache-maven-${maven_version} maven
cd -
cat << 'EOF' > /etc/profile.d/maven.sh
export M2_HOME=/usr/local/maven
export PATH=${M2_HOME}/bin:${PATH}
EOF

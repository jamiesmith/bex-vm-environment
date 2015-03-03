#!/bin/sh
#
# script to create a vmware image to host BE-X development
#
# $Id: create_dev_vmware_image.sh 13691 2014-03-03 16:30:31Z plord $
#
# This script :-
#	* auto creates an image based on the settings requested
#	* installs additional packages needed
#	* creates user
#	* disable avahi
#	* enable auto login
#	* svn co
#	* users .profile
#	* copy /opt/kabira/3rdparty ( vmware host first, then nfs )
#	* setup networking
#	* start mdnsd
#	* add BE-X icon
#	* Adobe flash
#
# Pending are :-
#	* update to latest packages (???)
#	* reduce number of packages to install

# some reference links :-
#
# http://nexus.kabira.fr/policy/docs/buildprocess/os.html
# http://www.jedi.be/blog/2009/03/10/automated-creation-of-vmware-server-virtual-machines/
# http://www.centos.org/docs/5/html/Installation_Guide-en-US/s1-kickstart2-options.html

set -e

# values
#
VMWARE_PATH=${HOME}/vmware
#VMWARE_VER=9
VMWARE_VER=7
CENTOS_VERSION=6.4
MINIMAL_INSTALL=false

osName="$(uname -s)"
if [ "$osName" = "Darwin" ]
then
	vmware_bin="/Applications/VMware Fusion.app/Contents/Library"
	vmware_resources="/Applications/VMware Fusion.app/Contents/Resources"
	vmware_tools="/Applications/VMware Fusion.app/Contents/Library/tools-upgraders"
	usr_bin=/usr/local/bin
	export PATH="$PATH:${vmware_bin}:${vmware_resources}:${vmware_tools}"
	
	VM_EXTENSION=".vmwarevm"
	
elif [ "$osName" = "Linux" ]
then
	vmware_bin="/usr/bin"
	vmware_resources="/usr/bin"
	vmware_tools="/usr/bin"
	usr_bin=/usr/bin
fi

function DieUsage
{
	echo "$*"
	echo "Usage: $0 [-d desktop] [-l locale] [-t timezone] [-h hostname] [-n vmname]"
	echo ""
	echo "(defaults in paren)"
	echo "\tdesktop choices are (kde) or gnome"
	echo "\tlocale choices are us and emea"
	echo "\ttimezone choices are anything that centos supports, suggestions are:"
	echo "\t\t(Europe/London)"
	echo "\t\tAmerica/New_York"
	echo "\t\tAmerica/Los_Angeles"
	echo "\tIf the locale is set, but tz isn't, it defaults to a sane value"

	exit 1
}

function generateMAC
{
	delim="$1"
	RANGE=255
	#set integer ceiling

	number=$RANDOM
	numbera=$RANDOM
	numberb=$RANDOM
	#generate random numbers

	let "number %= $RANGE"
	let "numbera %= $RANGE"
	let "numberb %= $RANGE"
	#ensure they are less than ceiling

	octets="00${delim}60${delim}2F"
	#set mac stem

	octeta=`echo "obase=16;$number" | bc`
	octetb=`echo "obase=16;$numbera" | bc`
	octetc=`echo "obase=16;$numberb" | bc`
	#use a command line tool to change int to hex(bc is pretty standard)
	#they're not really octets.  just sections.

	macadd="${octets}${delim}${octeta}${delim}${octetb}${delim}${octetc}"
	#concatenate values and add dashes

	echo $macadd
}

P_VM_VMRUN="${vmware_bin}/vmrun"
P_VM_RUNUPGRADER="${vmware_tools}/run_upgrader.sh" 
P_VM_TOOLS_UPGRADER32="${vmware_tools}/vmware-tools-upgrader-32"
P_VM_TOOLS_UPGRADER64="${vmware_tools}/vmware-tools-upgrader-64"
P_VM_ISOLINUX="${vmware_resources}/isolinux.bin"
P_VMDISKMANAGER="${vmware_bin}/vmware-vdiskmanager"

VM_NAME="BE-X CentOS${CENTOS_VERSION}"
DISK_SIZE=40GB
DISK_CONTROLLER=lsilogic
CPUS=2
CORESPERSOCKET=2
HOSTNAME="bex"
ISO="/Volumes/StorEDGE/ISOs/CentOS-${CENTOS_VERSION}-x86_64-bin-DVD1.iso"
MEMSIZE=8192
VM_USERNAME=tibco
VM_USER_FULLNAME="Tibco"
VM_USERPASSWORD='5gT1lLIHE0cDI' # tibco
VM_ROOTPASSWORD='5gT1lLIHE0cDI' # tibco

USE_MAC_ADDRESS=$(generateMAC ":")
USE_LOCATION=$(generateMAC " ")

# You can set these via command options now, see usage
#
VM_LANG="en_GB"
VM_KEYBOARD="uk"
VM_TIMEZONE="Europe/London"
VM_DESKTOP="KDE"

INCLUDE_THIRD_PARTY="false"

# Some basic locale settings
#
while getopts "d:h:jl:mn:st:3" option
do
    case $option in 
	d)
	    VM_DESKTOP=$(echo $OPTARG | tr [:lower:] [:upper:])

	    if [ $VM_DESKTOP != "GNOME" -a $VM_DESKTOP != "KDE" ]
	    then
		DieUsage Invalid Desktop Choice
	    fi
	    ;;
	h)
		HOSTNAME="$OPTARG"
		;;
	j)
	    # hidden Shortcut for me
	    #
	    VM_LANG="en_US"
	    VM_KEYBOARD="us"
	    VM_TIMEZONE="America/New_York"
	    VM_DESKTOP="GNOME"
	    ;;
	m)
	    MINIMAL_INSTALL=true
	    ;;
	n)
	    VM_NAME="$OPTARG"
	    ;;
	s)
	    # hidden Shortcut for singapore
	    #
	    VM_LANG="en_US"
	    VM_KEYBOARD="us"
	    VM_TIMEZONE="Asia/Singapore"
	    VM_DESKTOP="GNOME"
	    ;;
	l)
	    case $OPTARG in
		e|emea)
		    VM_LANG="en_GB"
		    VM_KEYBOARD="uk"
		    ;;
		u|us)
		    VM_LANG="en_US"
		    VM_KEYBOARD="us"
		    ;;
		*)
		    DieUsage Invalid Option
	    esac
	    ;;
	z)
	    VM_TIMEZONE="$OPTARG"
	    ;;
	3)
	    INCLUDE_THIRD_PARTY="true"
	    ;;
	*)
	    DieUsage
	    
    esac
done

shift $((${OPTIND} - 1)) 

SVN_URL="http://svn.tibco.com/policyorchestration/trunk/ocs3uk"
SVN_USER="nightly"
SVN_PASSWORD="TibcoN1t3"
THIRDPARTY_SERVER="nfs.kabira.com"
THIRDPARTY_USER="vzwsps"
#MDNSD_VER=107.5
MDNSD_VER=320.16

NL=$'\n'

# List of packages to install
#
PACKAGES="python${NL}"

if [ $VM_DESKTOP == "GNOME" ]
then
    # For some reason, if this is included with KDE it overrides
    #
    PACKAGES="${PACKAGES}@ Desktop${NL}"
    DEFAULT_DESKTOP_OPTION="--defaultdesktop=${VM_DESKTOP}"
fi

#PACKAGES="${PACKAGES}@ General Purpose Desktop${NL}"
PACKAGES="${PACKAGES}@ KDE Desktop${NL}" # KDE
#PACKAGES="${PACKAGES}@ Internet Browser${NL}"
PACKAGES="${PACKAGES}@ X Window System${NL}"
#PACKAGES="${PACKAGES}@ Fonts${NL}"
#PACKAGES="${PACKAGES}@ Printing client${NL}"
PACKAGES="${PACKAGES}@ Console internet tools${NL}"
#PACKAGES="${PACKAGES}@ Debugging Tools${NL}"
PACKAGES="${PACKAGES}@ Networking Tools${NL}"
PACKAGES="${PACKAGES}@ Perl Support${NL}"
PACKAGES="${PACKAGES}gcc${NL}"
PACKAGES="${PACKAGES}make${NL}"
PACKAGES="${PACKAGES}patch${NL}"
PACKAGES="${PACKAGES}binutils${NL}"
PACKAGES="${PACKAGES}kernel-devel${NL}"
PACKAGES="${PACKAGES}nfs-utils${NL}"
PACKAGES="${PACKAGES}nfs-utils-lib${NL}"
PACKAGES="${PACKAGES}lksctp-tools${NL}"
PACKAGES="${PACKAGES}gnome-terminal${NL}"

# some large packages we can do without
#
PACKAGES="${PACKAGES}-kdepim${NL}"
PACKAGES="${PACKAGES}-kdepim-libs${NL}"
PACKAGES="${PACKAGES}-kdegames${NL}"
PACKAGES="${PACKAGES}-gnome-user-docs${NL}"

# List of packages to install on first boot - can include packages from disk 2
# or internet repositories
#
POSTINSTALL_PACKAGES="wireshark-gnome"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} vim-X11"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} ksh"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} libstdc++"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} compat-libstdc++-33"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} glibc.i686"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} gdb"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} screen"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} lsof"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} wireshark"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} compat-expat1"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} subversion"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} subversion-gnome"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} telnet"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} firefox"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} emacs"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} webkitgtk"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} xulrunner"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} git"
POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} meld"
### only if making it for amazon.  POSTINSTALL_PACKAGES="${POSTINSTALL_PACKAGES} cloud-init"


# list of 3rdparty directories - avoid trailing /
#
THIRDPARTY_DIRECTORIES=""

if [ "$INCLUDE_THIRD_PARTY" = "true" ]
then
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/generic/maven/3.0.4"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/jdk/1.7.0_67_x86_64"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/openssl/1.0.1h_x86_64"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/mdns/107.5_x86_64"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/mdns/320.16_x86_64"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/db/4.4.20_x86_64"
	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/libsasl"
#	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/openldap/2.4.31_x86_64"
#	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/tibco-be/5.0/TIB_rv_8.4.0_linux26gl23_x86.tar.gz"
#	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/tibco-bex/1.2.0.GA"
#	THIRDPARTY_DIRECTORIES="${THIRDPARTY_DIRECTORIES} /opt/kabira/3rdparty/linux/tibco-ems/7.0.0_x86_64"
fi

# preperation
#
function prepare()
{
	# check for tools
	#
	for file in "${usr_bin}/wget" \
		"${usr_bin}/isoinfo" \
		"${usr_bin}/mkisofs" \
		"${P_VMDISKMANAGER}" \
		"${P_VM_VMRUN}" \
		"${P_VM_RUNUPGRADER}" \
		"${P_VM_TOOLS_UPGRADER32}" \
		"${P_VM_TOOLS_UPGRADER64}" \
		"${P_VM_ISOLINUX}"
	do
		if [ ! -f "${file}" ]
		then
			echo "${file} is required but missing"
			
			echo Note that on a mac you probably need to install cdrtools.  You can use homebrew:
			echo "#> brew install cdrtools"
			
			exit -1
		fi
	done
	
	# get install iso
	#
	if [ ! -f ${ISO} ]
	then
	# Use the vault, so we can get whatever version we want
	#
	    echo "The iso ($ISO) was not found, attempting to download it"
	    wget -q -O ${ISO} http://mirror.symnds.com/distributions/CentOS-vault/${CENTOS_VERSION}/isos/x86_64//$(basename ${ISO})
	    # wget -q http://mirror.nsc.liu.se/centos-store/${CENTOS_VERSION}/isos/x86_64/$(basename ${ISO})
	fi
}


# create disk
#
function createDisk() 
{
	if [ -d "${VMWARE_PATH}/${VM_NAME}" ]
	then
		rm -rf "${VMWARE_PATH}/${VM_NAME}"
	fi
	mkdir -p "${VMWARE_PATH}/${VM_NAME}"
	"${P_VMDISKMANAGER}" -c -s ${DISK_SIZE} -a ${DISK_CONTROLLER} -t 0 "${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmdk"
}

function createVMX()
{
	echo "#!/usr/bin/vmware
.encoding = \"UTF-8\"
config.version = \"8\"
numvcpus = \"${CPUS}\"
cpuid.coresPerSocket = \"${CORESPERSOCKET}\"
virtualHW.version = \"${VMWARE_VER}\"
vcpu.hotadd = \"TRUE\"
scsi0.present = \"TRUE\"
scsi0.virtualDev = \"lsilogic\"
memsize = \"${MEMSIZE}\"
mem.hotadd = \"TRUE\"
scsi0:0.present = \"TRUE\"
scsi0:0.fileName = \"${VM_NAME}.vmdk\"
ide0:0.present = \"TRUE\"
ide0:0.fileName = \"autoinst.iso\"
ide0:0.deviceType = \"cdrom-image\"
ide1:0.present = \"TRUE\"
ide1:0.fileName = \"${ISO}\"
ide1:0.deviceType = \"cdrom-image\"
floppy0.startConnected = \"FALSE\"
floppy0.fileName = \"\"
floppy0.autodetect = \"TRUE\"
ethernet0.present = "TRUE"
ethernet0.connectionType = "nat"
ethernet0.virtualDev = \"e1000\"
ethernet0.wakeOnPcktRcv = "FALSE"
ethernet0.addressType = "generated"
usb.present = \"TRUE\"
ehci.present = \"TRUE\"
ehci.pciSlotNumber = \"35\"
sound.present = \"TRUE\"
sound.startConnected = \"FALSE\"
sound.fileName = \"-1\"
sound.autodetect = \"TRUE\"
serial0.present = \"TRUE\"
serial0.fileType = \"thinprint\"
pciBridge0.present = \"TRUE\"
pciBridge4.present = \"TRUE\"
pciBridge4.virtualDev = \"pcieRootPort\"
pciBridge4.functions = \"8\"
pciBridge5.present = \"TRUE\"
pciBridge5.virtualDev = \"pcieRootPort\"
pciBridge5.functions = \"8\"
pciBridge6.present = \"TRUE\"
pciBridge6.virtualDev = \"pcieRootPort\"
pciBridge6.functions = \"8\"
pciBridge7.present = \"TRUE\"
pciBridge7.virtualDev = \"pcieRootPort\"
pciBridge7.functions = \"8\"
vmci0.present = \"TRUE\"
hpet0.present = \"TRUE\"
usb.vbluetooth.startConnected = \"TRUE\"
displayName = \"${VM_NAME}\"
guestOS = \"centos-64\"
nvram = \"${VM_NAME}.nvram\"
virtualHW.productCompatibility = \"hosted\"
powerType.powerOff = \"hard\"
powerType.powerOn = \"hard\"
powerType.suspend = \"hard\"
powerType.reset = \"hard\"
extendedConfigFile = \"${VM_NAME}.vmxf\"
scsi0.pciSlotNumber = \"16\"
ethernet0.generatedAddress = \"${USE_MAC_ADDRESS}\"
ethernet0.pciSlotNumber = \"33\"
usb.pciSlotNumber = \"32\"
sound.pciSlotNumber = \"34\"
vmci0.id = \"1574766763\"
vmci0.pciSlotNumber = \"36\"
uuid.location = \"56 4d ed a7 04 7c 2b bb-e2 f2 37 ${USE_LOCATION}\"
uuid.bios = \"56 4d ed a7 04 7c 2b bb-e2 f2 37 ${USE_LOCATION}\"
uuid.action = \"keep\"
cleanShutdown = \"TRUE\"
replay.supported = \"FALSE\"
replay.filename = \"\"
scsi0:0.redo = \"\"
pciBridge0.pciSlotNumber = \"17\"
pciBridge4.pciSlotNumber = \"21\"
pciBridge5.pciSlotNumber = \"22\"
pciBridge6.pciSlotNumber = \"23\"
pciBridge7.pciSlotNumber = \"24\"
usb:0.present = \"TRUE\"
usb:1.present = \"TRUE\"
ethernet0.generatedAddressOffset = \"0\"
vmotion.checkpointFBSize = \"33554432\"
softPowerOff = \"FALSE\"
usb:0.deviceType = \"hid\"
usb:0.port = \"0\"
usb:0.parent = \"-1\"
usb:1.speed = \"2\"
usb:1.deviceType = \"hub\"
usb:1.port = \"1\"
usb:1.parent = \"-1\"
applianceView.coverPage.author = \"Peter Lord ($0)\"
applianceView.coverPage.version = \"$Id: create_dev_vmware_image.sh 13691 2014-03-03 16:30:31Z plord $\""> "${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmx"

	if [ -d /opt/kabira/3rdparty/linux ]
	then
		echo "sharedFolder0.present = \"TRUE\"
sharedFolder0.enabled = \"TRUE\"
sharedFolder0.readAccess = \"TRUE\"
sharedFolder0.hostPath = \"/opt/kabira/3rdparty\"
sharedFolder0.guestName = \"3rdparty\"
sharedFolder0.expiration = \"never\"
isolation.tools.hgfs.disable = \"FALSE\"
sharedFolder.maxNum = \"1\"" >> "${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmx"
	fi
}

# create auto install iso
#
function createAutoInstISO
{
	mkdir "${VMWARE_PATH}/${VM_NAME}/autoinst"
	mkdir "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux"
	echo "lang ${VM_LANG}
#langsupport --default en_US
network --bootproto dhcp --hostname ${HOSTNAME}
cdrom
keyboard ${VM_KEYBOARD}
zerombr #yes
clearpart --all --initlabel
part /boot --size 300
part swap --recommended
part / --size 3000 --grow
#part biosboot --fstype=biosboot --size=1
install
#mouse generic3ps/2
firstboot --disable
firewall --disable
timezone --utc ${VM_TIMEZONE}
xconfig --startxonboot ${DEFAULT_DESKTOP_OPTION} #--resolution=800x600
rootpw --iscrypted ${VM_ROOTPASSWORD}
reboot
auth --useshadow --enablemd5
bootloader --location=mbr
key --skip
%packages
${PACKAGES}

%end
%post
cp /boot/grub/menu.lst /boot/grub/grub.conf.bak
sed -i 's/ rhgb//' /boot/grub/grub.conf
if [ -f /etc/rc.d/rc.local ]; then cp /etc/rc.d/rc.local /etc/rc.d/rc.local.backup; fi
cat >>/etc/rc.d/rc.local <<EOF
#!/bin/bash
echo
echo \"Installing VMware Tools, please wait...\"
if [ -x /usr/sbin/getenforce ]; then oldenforce=\\\$(/usr/sbin/getenforce); /usr/sbin/setenforce permissive || true; fi
mkdir -p /tmp/vmware-toolsmnt0
for i in hda sr0 scd0; do mount -t iso9660 /dev/\\\$i /tmp/vmware-toolsmnt0 && break; done
cp -a /tmp/vmware-toolsmnt0 /opt/vmware-tools-installer
chmod 755 /opt/vmware-tools-installer
cd /opt/vmware-tools-installer
mv upgra32 vmware-tools-upgrader-32
mv upgra64 vmware-tools-upgrader-64
mv upgrade.sh run_upgrader.sh
chmod +x /opt/vmware-tools-installer/*upgr*
umount /tmp/vmware-toolsmnt0
rmdir /tmp/vmware-toolsmnt0
if [ -x /usr/bin/rhgb-client ]; then /usr/bin/rhgb-client --quit; fi
cd /opt/vmware-tools-installer
for s in sr0 sr1; do eject -s /dev/\\\$s; done
./run_upgrader.sh
if [ -f /etc/rc.d/rc.local.backup ]; then mv /etc/rc.d/rc.local.backup /etc/rc.d/rc.local; else rm -f /etc/rc.d/rc.local; fi
rm -rf /opt/vmware-tools-installer
sed -i 's/3:initdefault/5:initdefault/' /etc/inittab
mv /boot/grub/grub.conf.bak /boot/grub/grub.conf
if [ -x /usr/sbin/getenforce ]; then /usr/sbin/setenforce \\\$oldenforce || true; fi
if [ -x /bin/systemd ]; then systemctl restart prefdm.service; else telinit 5; fi

cd /

echo '[WandiscoSVN]
name=Wandisco SVN Repo
baseurl=http://opensource.wandisco.com/centos/6/svn-1.8/RPMS/$basearch/
enabled=1
gpgcheck=0' > /etc/yum.repos.d/wandisco-svn.repo

# extra installations
#
/usr/bin/yum -y install ${POSTINSTALL_PACKAGES}

# graphical yum & disk usage
#
/bin/rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
/usr/bin/yum -y install yumex
/usr/bin/yum -y install ncdu

# flash / acroread
#
/bin/rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-x86_64-1.0-1.noarch.rpm
/bin/rpm -ivh http://linuxdownload.adobe.com/adobe-release/adobe-release-i386-1.0-1.noarch.rpm
/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-adobe-linux
/usr/bin/yum -y install flash-plugin
/usr/bin/yum -y install AdobeReader_enu

# could update all packages to latest ... but takes some time and takes us to
# 6.4 !
#
#/usr/bin/yum -y update

# kernel tuning
#
echo '* hard nproc unlimited' >> /etc/security/limits.conf
echo '* soft nproc 40960' >> /etc/security/limits.conf
echo '* soft nproc 40960' > /etc/security/limits.d/90-nproc.conf

# sudo access
#
echo '# Grant sudo access to users in tibco groupsu
' >> /etc/sudoers
echo '%tibco        ALL=(ALL)       NOPASSWD: ALL' >> /etc/sudoers

# copy from build servers
#
mkdir -p /opt/kabira
if [ -d /mnt/hgfs/3rdparty ]
then
	cd /mnt/hgfs
	for dir in ${THIRDPARTY_DIRECTORIES}
	do
		f=\\\$(echo \\\${dir} | sed -e \"s+/opt/kabira/++\")
		tar -cf - \\\${f} | tar -C /opt/kabira -xvf -
	done
	cd /
else
	mkdir /tmp/3rdparty
	/bin/mount -tnfs -oro,nolock ${THIRDPARTY_SERVER}:/export/data/3rdparty /tmp/3rdparty
	cd /tmp
	for dir in ${THIRDPARTY_DIRECTORIES}
	do
		f=\\\$(echo \\\${dir} | sed -e \"s+/opt/kabira/++\")
		tar -cf - \\\${f} | tar -C /opt/kabira -xvf -
	done
	cd /
	/bin/umount /tmp/3rdparty
fi

# disable avahd
#
/sbin/service avahi-daemon stop
/sbin/chkconfig avahi-daemon off

# configure hostname
#
if [ -d /etc/NetworkManager/dispatcher.d ]
then
	echo '#!/bin/sh

case \"\\\$2\" in
    up)
  	ip=\\\$(/sbin/ifconfig \\\${1} | grep \"inet addr:\" | grep -v \"127.0.0.1\" | cut -d: -f2 | awk '\''{ print \\\$1}'\'')
  	if [ \"\\\${ip}\" != \"\" ]
  	then
    		sed -i -e \"/ADDED BY UPDATEHOSTS/d\" /etc/hosts
    		echo \"\\\${ip} \\\$(uname -n) # ADDED BY UPDATEHOSTS\" >> /etc/hosts
        fi
        ;;
    *)
        exit 0
        ;;
esac' > /etc/NetworkManager/dispatcher.d/updatehosts
	chmod a+x /etc/NetworkManager/dispatcher.d/updatehosts
	
else
	echo 'for interface in eth0 wlan0
do
  ip=\\\$(ifconfig \\\${interface} | grep \"inet addr:\" | grep -v \"127.0.0.1\" | cut -d: -f2 | awk '\''{ print \\\$1}'\'')
  if [ \"\\\${ip}\" != \"\" ]
  then
    echo \"added \\\${ip} as \\\$(uname -n)\"
    sed -i -e \"/ADDED BY LOCAL/d\" /etc/hosts
    echo \"\\\${ip} \\\$(uname -n) # ADDED BY LOCAL\" >> /etc/hosts
    break
  fi
done' >> /etc/rc.local
fi

# enable mdnsd
#
if [ /opt/kabira/3rdparty/linux/mdns/${MDNSD_VER}_x86_64/sbin/mdnsd ]
then
	echo \"/opt/kabira/3rdparty/linux/mdns/${MDNSD_VER}_x86_64/sbin/mdnsd\" >> /etc/rc.local
fi

/etc/rc.local

# svn checkout
#
mkdir -p ~${VM_USERNAME}/workspace
chown ${VM_USERNAME} ~${VM_USERNAME}/workspace
cd ~${VM_USERNAME}/workspace
#/bin/su ${VM_USERNAME} -c \"/usr/bin/svn --non-interactive --username ${SVN_USER} --password ${SVN_PASSWORD} co ${SVN_URL}\"

# desktop BE-X icon
#
wget -O ~${VM_USERNAME}/Tibco.svg -q http://upload.wikimedia.org/wikipedia/commons/a/a6/Tibco.svg
mkdir -p ~${VM_USERNAME}/Desktop
chown ${VM_USERNAME}:${VM_USERNAME} ~${VM_USERNAME}/Desktop

echo '#!/usr/bin/env xdg-open
[Desktop Entry]
Comment[${VM_LANG}]=
Comment=
Exec=\\\${TIBCO_HOME}/be/5.1/studio/eclipse/studio
GenericName[${VM_LANG}]=
GenericName=
Icon=/home/${VM_USERNAME}/Tibco.svg
MimeType=
Name[${VM_LANG}]=BE-X
Name=BE-X
Path=\\\${TIBCO_HOME}be/5.1/studio/eclipse
StartupNotify=true
Terminal=false
TerminalOptions=
Type=Application
X-DBUS-ServiceName=
X-DBUS-StartupType=
X-KDE-SubstituteUID=false
X-KDE-Username=' > ~${VM_USERNAME}/Desktop/BE-X.desktop

ln -sf ~${VM_USERNAME}/workspace ~${VM_USERNAME}/Desktop/

# Also try to make real icons for the others
#
# Emacs.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=emacs.png
Name[${VM_LANG}]=Emacs
Comment[${VM_LANG}]=Edit text
Exec=emacs %f
Name=Emacs
Comment=Edit text
Icon=emacs.png' > ~${VM_USERNAME}/Desktop/Emacs.desktop

# Firefox Web Browser.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=firefox
Name[${VM_LANG}]=Firefox Web Browser
Comment[${VM_LANG}]=Browse the Web
Exec=firefox %u
Name=Firefox Web Browser
Comment=Browse the Web
Icon=firefox' > ~${VM_USERNAME}/Desktop/FirefoxWebBrowser.desktop

# Gnome Terminal
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=utilities-terminal
Name[${VM_LANG}]=Terminal
Comment[${VM_LANG}]=Use the command line
Exec=gnome-terminal
Name=Terminal
Comment=Use the command line
Icon=utilities-terminal' > ~${VM_USERNAME}/Desktop/Terminal.desktop

# Konsole.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=utilities-terminal
Name[${VM_LANG}]=Konsole
Exec=konsole
Name=Konsole
Icon=utilities-terminal' > ~${VM_USERNAME}/Desktop/Konsole.desktop

# Vi IMproved.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=gvim
Name[${VM_LANG}]=Vi IMproved
Comment[${VM_LANG}]=Powerful text editor with scripting functions and macro recorder
Exec=gvim -f %f
Name=Vi IMproved
Comment=Powerful text editor with scripting functions and macro recorder
Icon=gvim' > ~${VM_USERNAME}/Desktop/Vi-IMproved.desktop

# Wireshark Network Analyzer.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=wireshark
Name[${VM_LANG}]=Wireshark Network Analyzer
Comment[${VM_LANG}]=Wireshark traffic and network analyzer
Exec=wireshark
Name=Wireshark Network Analyzer
Comment=Wireshark traffic and network analyzer
Icon=wireshark' > ~${VM_USERNAME}/Desktop/Wireshark-Network-Analyzer.desktop

# xterm Terminal.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=gnome-xterm
Name[${VM_LANG}]=xterm Terminal
Comment[${VM_LANG}]=Terminal emulator for the X Window System
Exec=xterm
Name=xterm Terminal
Comment=Terminal emulator for the X Window System
Icon=gnome-xterm' > ~${VM_USERNAME}/Desktop/xterm-Terminal.desktop

# Yum Extender.desktop
echo '#!/usr/bin/env xdg-open

[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Icon[${VM_LANG}]=/usr/share/pixmaps/yumex/yumex-icon.png
Name[${VM_LANG}]=Yum Extender
Comment[${VM_LANG}]=GUI front end for Yum
Exec=/usr/bin/yumex
Name=Yum Extender
Comment=GUI front end for Yum
Icon=/usr/share/pixmaps/yumex/yumex-icon.png' > ~${VM_USERNAME}/Desktop/Yum-Extender.desktop

chown ${VM_USERNAME}:${VM_USERNAME} ~${VM_USERNAME}/Desktop/*
chmod +x ~${VM_USERNAME}/Desktop/*

# compress disk space
#
/usr/bin/yum -y clean all
cat /dev/zero > /zero.fill 2>/dev/null ; sync ; sleep 1 ; sync ; rm -f /zero.fill
/usr/bin/vmware-toolbox-cmd disk shrink /

EOF
chmod 755 /etc/rc.d/rc.local
if [ -x /bin/systemd ]; then systemctl enable rc-local.service; fi

# add user
#
/usr/sbin/adduser ${VM_USERNAME}
/usr/sbin/usermod -p '${VM_USERPASSWORD}' ${VM_USERNAME}
/usr/bin/chfn -f \"${VM_USER_FULLNAME}\" ${VM_USERNAME}

# Import environment
# 
# Set up some other stuff
#
cd ~${VM_USERNAME}
git clone https://github.com/jamiesmith/findgrep.git
git clone https://github.com/jamiesmith/bex-vm-environment.git
./bex-vm-environment/bootstrap.ksh
chown -R ${VM_USERNAME}:${VM_USERNAME} ~${VM_USERNAME}/
cd -

mkdir -p /opt/tibco
mkdir -p /opt/kabira
chown ${VM_USERNAME} /opt/tibco /opt/kabira

# disable kde gui login
#
if [ -f /etc/kde/kdm/kdmrc ]
then 
	echo \"[X-:0-Core]
AutoLoginEnable=true
AutoLoginLocked=false
AutoLoginUser=${VM_USERNAME}

[X-:*Greeter]
AutoLoginEnable=true
AutoLoginUser=${VM_USERNAME}\" >> /etc/kde/kdm/kdmrc

fi

# auto-login for gnome as well
#
if [ -f /etc/gdm/custom.conf ]
then 
	echo \"# GDM configuration storage

[daemon]
AutomaticLoginEnable=true
AutomaticLogin=${VM_USERNAME}

[security]

[xdmcp]

[greeter]

[chooser]

[debug]\" > /etc/gdm/custom.conf

fi


%end" > "${VMWARE_PATH}/${VM_NAME}/autoinst/ks.cfg"

# save a copy locally to troubleshoot
#
cp "${VMWARE_PATH}/${VM_NAME}/autoinst/ks.cfg" /tmp/

	cp "${P_VM_RUNUPGRADER}"      "${VMWARE_PATH}/${VM_NAME}/autoinst/upgrade.sh"
	cp "${P_VM_TOOLS_UPGRADER32}" "${VMWARE_PATH}/${VM_NAME}/autoinst/upgra32"
	cp "${P_VM_TOOLS_UPGRADER64}" "${VMWARE_PATH}/${VM_NAME}/autoinst/upgra64"
	cp "${P_VM_ISOLINUX}"         "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux/isolinux.bin"
	
	isoinfo -R -i ${ISO} -x /isolinux/boot.cat > "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux/boot.cat"
	isoinfo -R -i ${ISO} -x /isolinux/initrd.img > "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux/initrd.img"
	isoinfo -R -i ${ISO} -x /isolinux/vmlinuz > "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux/vmlinuz"

	echo "default linux
prompt 0
timeout 1

label linux
	kernel vmlinuz
	append initrd=initrd.img  ks=cdrom:/ks.cfg" > "${VMWARE_PATH}/${VM_NAME}/autoinst/isolinux/isolinux.cfg"

	mkisofs -o "${VMWARE_PATH}/${VM_NAME}/autoinst.iso" -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table "${VMWARE_PATH}/${VM_NAME}/autoinst"
	rm -rf "${VMWARE_PATH}/${VM_NAME}/autoinst"
}

# run
#
function run()
{
	"${P_VM_VMRUN}" -T ws start "${VMWARE_PATH}/${VM_NAME}${VM_EXTENSION}/${VM_NAME}.vmx"
}

function fixMacName()
{
	if [ -n "${VM_EXTENSION}" ]
	then
		# Mac friendly, hide the extension
		#
		echo mv "${VMWARE_PATH}/${VM_NAME}" "${VMWARE_PATH}/${VM_NAME}${VM_EXTENSION}"
		mv "${VMWARE_PATH}/${VM_NAME}" "${VMWARE_PATH}/${VM_NAME}${VM_EXTENSION}"
		
		SetFile -a E "${VMWARE_PATH}/${VM_NAME}${VM_EXTENSION}"
	fi
}


############

# install sequence
prepare
createDisk
createVMX
createAutoInstISO
fixMacName
run


echo "To shrink the disk for sending try"
echo "	ls -l \"${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmdk\""
echo "	vmware-vdiskmanager -d \"${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmdk\""
echo "	vmware-vdiskmanager -k \"${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmdk\""
echo "	ls -l \"${VMWARE_PATH}/${VM_NAME}/${VM_NAME}.vmdk\""
echo
echo "To ship"
echo "	cd \"${VMWARE_PATH}\""
echo "	rm -f \"${VM_NAME}.tar.7z\""
echo "	tar -cf - \"${VM_NAME}\" | 7z a -si \"${VM_NAME}.tar.7z\""
echo "	scp \"${VM_NAME}.tar.7z\" nexus.kabira.fr:/var/www/html/vmware"
echo "	cp \"${VM_NAME}.tar.7z\" ~/Dropbox/BE-X/"

# Trying to incorporate this in to the install kind of broke stuff
#
# sudo yum install subversion-gnome



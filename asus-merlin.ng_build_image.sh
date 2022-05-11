#!/bin/sh

DIR_BUILD=$HOME
SRC_BRANCH="386.5_2"
RT_MODEL="rt-ac68u"

while [ $# -gt 0 ] ; do
  case "$1" in
    -d)
      DIR_BUILD=$2
      shift 1
      ;;
    -b)
      SRC_BRANCH=$2
      shift 1
      ;;
    -m)
      RT_MODEL=$2
      shift 1
      ;;
    *)
      echo "Invalid argument: $1"
      exit 4
      ;;
  esac
  shift 1
done

DIR_AMTC="$DIR_BUILD/am-toolchains"
DIR_AMNG="$DIR_BUILD/amng-build.$RT_MODEL"


echo "-------------------- install the required packages"
sudo -S dpkg --add-architecture i386
if [ $? != 0 ]; then
  echo "dpkg --add-architectur is failed. Please run this script again."
  exit 1
fi
echo "dash dash/sh boolean false" | sudo debconf-set-selections
if [ $? != 0 ]; then
  echo "debconf-set-selections is failed. Please run this script again."
  exit 1
fi
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash
if [ $? != 0 ]; then
  echo "dpkg-reconfigure is failed. Please run this script again."
  exit 1
fi
sudo -S apt update
if [ $? != 0 ]; then
  echo "apt update is failed. Please run this script again."
  exit 1
fi
sudo -S apt -y upgrade
if [ $? != 0 ]; then
  echo "apt upgrade is failed. Please run this script again."
  exit 1
fi
sudo -S apt -y install libtool-bin cmake libproxy-dev uuid-dev liblzo2-dev autoconf automake bash bison \
	bzip2 diffutils file flex m4 g++ gawk groff-base libncurses5-dev libtool libslang2 make patch perl pkg-config shtool \
	subversion tar texinfo zlib1g zlib1g-dev git gettext libexpat1-dev libssl-dev cvs gperf unzip \
	python libxml-parser-perl gcc-multilib gconf-editor libxml2-dev g++-multilib gitk libncurses5 mtd-utils \
	libncurses5-dev libvorbis-dev git autopoint autogen automake-1.15 sed build-essential intltool libglib2.0-dev \
	xutils-dev lib32z1-dev lib32stdc++6 xsltproc gtk-doc-tools libelf1:i386
if [ $? != 0 ]; then
  echo "apt install is failed. Please run this script again."
  exit 1
fi

echo "-------------------- git clone the asuswrt-merlin.ng repository"
rm -rf $DIR_AMTC
git clone https://github.com/RMerl/am-toolchains $DIR_AMTC
if [ $? != 0 ]; then
  echo "git clone is failed. Please run this script again."
  exit 2
fi

rm -rf $DIR_AMNG
git clone -c advice.detachedHead=false --branch $SRC_BRANCH --depth=1 --single-branch https://github.com/RMerl/asuswrt-merlin.ng $DIR_AMNG
if [ $? != 0 ]; then
  echo "git clone is failed. Please run this script again."
  exit 2
fi

echo "-------------------- apply the patch to to support EAP_TTLS/PAP for the asuswrt-merlin.ng"
cd $DIR_AMNG
curl -sLf "https://github.com/ypyd/asuswrt-merlin-ypyd/raw/main/asus-merlin.ng_${SRC_BRANCH}_ttls.patch" | patch -p0
if [ $? != 0 ]; then
  echo "patch is failed. Please run this script again."
  exit 3
fi

echo "-------------------- create some symlinks and adjust the PATH environment variable"
case "$RT_MODEL" in
  rt-ac68u|rt-ac88u|rt-ac3100|rt-ac5300)
    sudo -S ln -s -f $DIR_AMTC/brcm-arm-sdk/hndtools-arm-linux-2.6.36-uclibc-4.5.3 /opt/brcm-arm
    ln -s -f $DIR_AMTC/brcm-arm-sdk $DIR_AMNG/release/src-rt-6.x.4708/toolchains
    export PATH=$PATH:/opt/brcm-arm/bin
    ;;
  rt-ac86u|gt-ac2900)
    sudo -S ln -s -f $DIR_AMTC/brcm-arm-hnd /opt/toolchains
    export LD_LIBRARY_PATH=$LD_LIBRARY:/opt/toolchains/crosstools-arm-gcc-5.3-linux-4.1-glibc-2.22-binutils-2.25/usr/lib
    export TOOLCHAIN_BASE=/opt/toolchains
    export PATH=$PATH:/opt/toolchains/crosstools-arm-gcc-5.3-linux-4.1-glibc-2.22-binutils-2.25/usr/bin
    export PATH=$PATH:/opt/toolchains/crosstools-aarch64-gcc-5.3-linux-4.1-glibc-2.22-binutils-2.25/usr/bin
    ;;
  rt-ax56u|rt-ax58u|rt-ax68u|rt-ax86u|rt-ax88u|gt-ax11000)
    sudo -S ln -s -f $DIR_AMTC/brcm-arm-hnd /opt/toolchains
    export LD_LIBRARY_PATH=$LD_LIBRARY:/opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/lib
    export TOOLCHAIN_BASE=/opt/toolchains
    export PATH=$PATH:/opt/toolchains/crosstools-arm-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/bin
    export PATH=$PATH:/opt/toolchains/crosstools-aarch64-gcc-5.5-linux-4.1-glibc-2.26-binutils-2.28.1/usr/bin
    ;;
    *)
      echo "RT_MODEL is wrong. Please run this script again."
      exit 4
      ;;
esac

case "$RT_MODEL" in
  rt-ac68u)
    cd $DIR_AMNG/release/src-rt-6.x.4708
    ;;
  rt-ac88u|rt-ac3100|rt-ac5300)
    cd $DIR_AMNG/release/src-rt-7.14.114.x/src
    ;;
  rt-ac86u|gt-ac2900)
    cd $DIR_AMNG/release/src-rt-5.02hnd
    ;;
  rt-ax56u|rt-ax58u)
    cd $DIR_AMNG/release/src-rt-5.02axhnd.675x
    ;;
  rt-ax68u|rt-ax86u)
    cd $DIR_AMNG/release/src-rt-5.02p1axhnd.675x
    ;;
  rt-ax88u|gt-ax11000)
    cd $DIR_AMNG/release/src-rt-5.02axhnd
    ;;
esac
make $RT_MODEL

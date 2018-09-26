#!/bin/bash
GOESTOOLS_DIR="/home/pi/goestools"
GOESTOOLS_REPO="https://github.com/pietern/goestools.git"
BUILD_PACKAGES="apt-utils build-essential ca-certificates cmake git libairspy-dev libopencv* librtlsdr-dev pkg-config"

if [ "$EUID" -ne 0 ]
then echo "This script must be run as root!"
exit 1
fi &&

echo "$(tput setaf 1 2> /dev/null)ANY FILES WITHIN $GOESTOOLS_DIR WILL BE DESTROYED. CONTINUE? (yes/no)$(tput sgr0 2> /dev/null)" &&
read -r REPLY &&
REPLY=${REPLY,,} &&
if ! [[ $REPLY =~ ^(yes|y) ]]
then
echo "$(tput setaf 1 2> /dev/null)Aborting!$(tput sgr0 2> /dev/null)" &&
exit 1
fi &&

#get requisite packages
apt-get update &&
apt-get -y install --no-install-recommends $BUILD_PACKAGES &&

#build goestools
rm -rf "$GOESTOOLS_DIR"
git clone --recursive "$GOESTOOLS_REPO" "$GOESTOOLS_DIR" &&
cd "$GOESTOOLS_DIR" &&
mkdir -p build &&
cd build/ &&
cmake ../ -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local -DBUILD_GOESRECV=ON -DBUILD_GOESLRIT=ON -DBUILD_GOESPROC=ON &&
make -j4 &&
make install &&
cd ../ &&
mkdir -p bin &&
cd bin/ &&
cp "$GOESTOOLS_DIR"/build/src/goeslrit/goeslrit . &&
cp "$GOESTOOLS_DIR"/build/src/goesproc/goesproc . &&
cp "$GOESTOOLS_DIR"/build/src/goesrecv/goesrecv . &&
chmod +x * &&
cp "$GOESTOOLS_DIR"/etc/* . &&
echo "Done!" &&

exit
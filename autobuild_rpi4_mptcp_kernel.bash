#!/bin/bash
# !!! HIGHLY EXPERIMENTAL !!!
# !!! USE AT YOUR OWN RISK !!!

### GITHUB SECTION ###
# GLOBAL CONFIG #
GIT_USERNAME="3x3cut0r" # your git username
GIT_EMAIL="executor55@gmx.de" # your git email
# COMMIT HASHES #
GIT_COMMIT_RPI_SHA1=106fa147d3daa58d2c1ae5f41a29d07036fe7d0a # "Linux 4.19.127" on https://github.com/raspberrypi/linux/commit/106fa147d3daa58d2c1ae5f41a29d07036fe7d0a
GIT_COMMIT_MPTCP_SHA1=106fa147d3daa58d2c1ae5f41a29d07036fe7d0a # "Linux 4.19.127" on https://github.com/multipath-tcp/mptcp/commit/106fa147d3daa58d2c1ae5f41a29d07036fe7d0a
# BRANCH #
RPI_BRANCH="rpi-4.19.y" # the git branch from https://github.com/raspberrypi/linux which contains the GIT_COMMIT_RPI_SHA1
MPTCP_BRANCH="mptcp_v0.95" # the git branch from https://github.com/multipath-tcp/mptcp which contains the GIT_COMMIT_MPTCP_SHA1

### KERNEL SECTION ###
# Raspberry Pi 1, Pi Zero, Pi Zero W    : KERNEL="kernel"    KERNEL_CONFIG="bcmrpi_defconfig"
# Raspberry Pi 2, Pi 3, Pi 3+           : KERNEL="kernel7"   KERNEL_CONFIG="bcm2709_defconfig"
# Raspberry Pi 4                        : KERNEL="kernel7l"  KERNEL_CONFIG="bcm2711_defconfig"
KERNEL="kernel7l"
KERNEL_CONFIG="bcm2711_defconfig"

### GLOBAL SECTION ###
# WORKING DIRECTORY #
WORKING_DIR="$HOME" # home directory is recommended to prevent write permission issues
# CPU CORES #
CPU_CORES_FOR_COMPILING=4 # number of cpu cores to use for compiling



### START OF SCRIPT ###
cd $WORKING_DIR

# CLEANING UP #
rm -rf $WORKING_DIR/linux
rm -rf .gitconfig

# UPDATE ENVIRONMENT #
sudo apt update
sudo apt upgrade -y

# INSTALL PREREQUISITES #
sudo apt install -y git bc make ncurses-dev gcc gcc-arm-linux-gnueabihf wget unzip bison flex libssl-dev libc6-dev libncurses5-dev

# CLONE RASPBERRYPI/LINUX FROM GITHUB #
git clone --branch $RPI_BRANCH git://github.com/raspberrypi/linux.git
cd $WORKING_DIR/linux

# SETTING UP GIT #
git config --global user.name $GIT_USERNAME
git config --global user.email $GIT_EMAIL
git config merge.renameLimit 999999

# CHECKOUT REPOSITORY #
# git checkout $GIT_COMMIT_RPI_SHA1

# ADD MULTIPATH-TCP/MPTCP FROM GITHUB #
git remote add mptcp https://github.com/multipath-tcp/mptcp.git
git fetch mptcp
git checkout -b rpi_mptcp origin/rpi-4.19.y
#git fetch --depth=1 mptcp $GIT_COMMIT_MPTCP_SHA1
#git checkout -b rpi_mptcp $GIT_COMMIT_MPTCP_SHA1

# MERGE REPOSITORYS #
git merge mptcp/$MPTCP_BRANCH --allow-unrelated-histories

# CLONE BUILD TOOLS #
git clone https://github.com/raspberrypi/tools $WORKING_DIR/tools
echo PATH=\$PATH:~/tools/arm-bcm2708/gcc-linaro-arm-linux-gnueabihf-raspbian-x64/bin >> ~/.bashrc
source ~/.bashrc

### COMPILE SECTION ###
# DOWNLOAD KERNEL_CONFIG
cd arch/arm/configs/
wget https://raw.githubusercontent.com/raspberrypi/linux/$RPI_BRANCH/arch/arm/configs/$KERNEL_CONFIG
cd $WORKING_DIR/linux

# MAKE #
make mrproper
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- $KERNEL_CONFIG
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- nconfig
# COMPILE #
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING zImage
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING dtbs

# WGET RASPIAN IMAGE #
wget https://downloads.raspberrypi.org/raspbian_lite_latest
unzip raspbian_lite_latest
mv *.img raspbian.img
fdisk -l raspbian.img
mkdir -p mnt/fat32
mkdir mnt/ext4
read -p 'Start of Partition1 * 512 = ' PART1
read -p 'Start of Partition2 * 512 = ' PART2

# MOUNT IMAGE #
mount -v -o offset=$PART2 -t ext4 raspbian.img mnt/ext4
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=mnt/ext4 -j $CPU_CORES_FOR_COMPILING modules_install
umount mnt/ext4
mount -v -o offset=$PART1 -t vfat raspbian.img mnt/fat32
cp mnt/fat32/$KERNEL.img mnt/fat32/$KERNEL-backup.img
cp arch/arm/boot/zImage mnt/fat32/$KERNEL.img
cp arch/arm/boot/dts/*.dtb mnt/fat32/
cp arch/arm/boot/dts/overlays/*.dtb* mnt/fat32/overlays/
cp arch/arm/boot/dts/overlays/README mnt/fat32/overlays/
echo "kernel=$KERNEL.img" >> mnt/fat32/config.txt
# UNMOUNT IMAGE #
umount mnt/fat32
mv raspbian.img $WORKING_DIR/Raspbian_RPi4.img

### CLEANING UP AGAIN ###
cd $WORKING_DIR
rm -rf $WORKING_DIR/linux
#rm -rf $WORKING_DIR/tools
rm -rf .gitconfig

# DONE #

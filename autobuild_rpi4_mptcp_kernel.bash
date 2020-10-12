#!/bin/bash
# !!! HIGHLY EXPERIMENTAL !!!
# !!! USE AT YOUR OWN RISK !!!

### ------------------------------------------------------------------------ ###
### GITHUB SECTION ###
# GLOBAL CONFIG #
GIT_USERNAME="3x3cut0r" # your git username
GIT_EMAIL="executor55@gmx.de" # your git email
# COMMIT HASHES #
GIT_COMMIT_SHA=106fa147d3daa58d2c1ae5f41a29d07036fe7d0a # "Linux 4.19.127" commit on https://github.com/raspberrypi/linux/commit/106fa147d3daa58d2c1ae5f41a29d07036fe7d0a
# BRANCH #
RPI_BRANCH="rpi-4.19.y" # the git branch from https://github.com/raspberrypi/linux which contains the GIT_COMMIT_RPI_SHA1
MPTCP_BRANCH="mptcp_v0.95" # the git branch from https://github.com/multipath-tcp/mptcp which contains the GIT_COMMIT_MPTCP_SHA1

### KERNEL SECTION ###
# Raspberry Pi 1, Pi Zero, Pi Zero W    : KERNEL="kernel"    KERNEL_CONFIG="bcmrpi_defconfig"
# Raspberry Pi 2, Pi 3, Pi 3+           : KERNEL="kernel7"   KERNEL_CONFIG="bcm2709_defconfig"
# Raspberry Pi 4                        : KERNEL="kernel7l"  KERNEL_CONFIG="bcm2711_defconfig"
KERNEL="kernel7l"
KERNEL_CONFIG="bcm2711_defconfig"

### IMAGE SECTION ###
# Raspberry Pi OS (32-bit) with desktop and recommended software    = "https://downloads.raspberrypi.org/raspios_full_armhf_latest"
# Raspberry Pi OS (32-bit) with desktop                             = "https://downloads.raspberrypi.org/raspios_armhf_latest"
# Raspberry Pi OS (32-bit) Lite                                     = "https://downloads.raspberrypi.org/raspios_lite_armhf_latest"
RASPIOS_URL="https://downloads.raspberrypi.org/raspios_lite_armhf_latest"

### GLOBAL SECTION ###
# WORKING DIRECTORY #
WORKING_DIR="$HOME" # home directory is recommended to prevent write permission issues
# CPU CORES #
CPU_CORES_FOR_COMPILING=4 # number of cpu cores to use for compiling

### ------------------------------------------------------------------------ ###
### START OF SCRIPT ###
cd $WORKING_DIR

# CLEANING UP #
sudo rm -rf $WORKING_DIR/linux
sudo rm -rf .gitconfig

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
git checkout -b rpi_mptcp $GIT_COMMIT_SHA
#git checkout -b rpi_mptcp origin/rpi-4.19.y

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
#sudo make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- nconfig
cp .config .config.old
sed -i  's/CONFIG_IPV6=m/CONFIG_IPV6=y/g' .config
INSLINE=$(grep -rnw '.config' -e 'CONFIG_TCP_CONG_BBR=m' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)iCONFIG_TCP_CONG_LIA=y" .config
sed -i  "$(expr $INSLINE + 2)iCONFIG_TCP_CONG_OLIA=y" .config
sed -i  "$(expr $INSLINE + 3)iCONFIG_TCP_CONG_WVEGAS=y" .config
sed -i  "$(expr $INSLINE + 4)iCONFIG_TCP_CONG_BALIA=y" .config
sed -i  "$(expr $INSLINE + 5)iCONFIG_TCP_CONG_MCTCPDESYNC=y" .config
INSLINE=$(grep -rnw '.config' -e 'CONFIG_DEFAULT_CUBIC=y' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)i# CONFIG_DEFAULT_LIA is not set" .config
sed -i  "$(expr $INSLINE + 2)i# CONFIG_DEFAULT_OLIA is not set" .config
sed -i  "$(expr $INSLINE + 3)i# CONFIG_DEFAULT_WVEGAS is not set" .config
sed -i  "$(expr $INSLINE + 4)i# CONFIG_DEFAULT_BALIA is not set" .config
sed -i  "$(expr $INSLINE + 5)i# CONFIG_DEFAULT_MCTCPDESYNC is not set" .config
INSLINE=$(grep -rnw '.config' -e '# CONFIG_IPV6_SEG6_HMAC is not set' | cut -d: -f 1)
sed -i  "$(expr $INSLINE + 1)iCONFIG_MPTCP=y" .config
sed -i  "$(expr $INSLINE + 2)iCONFIG_MPTCP_PM_ADVANCED=y" .config
sed -i  "$(expr $INSLINE + 3)iCONFIG_MPTCP_FULLMESH=y" .config
sed -i  "$(expr $INSLINE + 4)iCONFIG_MPTCP_NDIFFPORTS=y" .config
sed -i  "$(expr $INSLINE + 5)iCONFIG_MPTCP_BINDER=y" .config
sed -i  "$(expr $INSLINE + 6)iCONFIG_MPTCP_NETLINK=y" .config
sed -i  "$(expr $INSLINE + 7)iCONFIG_DEFAULT_FULLMESH=y" .config
sed -i  "$(expr $INSLINE + 8)i# CONFIG_DEFAULT_NDIFFPORTS is not set" .config
sed -i  "$(expr $INSLINE + 9)i# CONFIG_DEFAULT_BINDER is not set" .config
sed -i  "$(expr $INSLINE + 10)i# CONFIG_DEFAULT_NETLINK is not set" .config
sed -i  "$(expr $INSLINE + 11)i# CONFIG_DEFAULT_DUMMY is not set" .config
sed -i  "$(expr $INSLINE + 12)iCONFIG_DEFAULT_MPTCP_PM=\"fullmesh\"" .config
sed -i  "$(expr $INSLINE + 13)iCONFIG_MPTCP_SCHED_ADVANCED=y" .config
sed -i  "$(expr $INSLINE + 14)iCONFIG_MPTCP_BLEST=y" .config
sed -i  "$(expr $INSLINE + 15)iCONFIG_MPTCP_ROUNDROBIN=y" .config
sed -i  "$(expr $INSLINE + 16)iCONFIG_MPTCP_REDUNDANT=y" .config
sed -i  "$(expr $INSLINE + 17)iCONFIG_DEFAULT_SCHEDULER=y" .config
sed -i  "$(expr $INSLINE + 18)i# CONFIG_DEFAULT_ROUNDROBIN is not set" .config
sed -i  "$(expr $INSLINE + 19)i# CONFIG_DEFAULT_REDUNDANT is not set" .config
sed -i  "$(expr $INSLINE + 20)iCONFIG_DEFAULT_MPTCP_SCHED=\"default\"" .config

# COMPILE #
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING zImage
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING modules
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- -j $CPU_CORES_FOR_COMPILING dtbs

# WGET RASPIAN IMAGE #
wget $RASPIOS_URL
sudo chmod 755 $WORKING_DIR/linux/raspios_*
unzip $WORKING_DIR/linux/raspios_* -d $WORKING_DIR/linux
mv $WORKING_DIR/linux/*raspios*.img $WORKING_DIR/linux/raspios.img
fdisk -l $WORKING_DIR/linux/raspios.img
mkdir -p $WORKING_DIR/linux/mnt/fat32
mkdir $WORKING_DIR/linux/mnt/ext4
START_PART_1=$(fdisk -l $WORKING_DIR/linux/raspios.img | grep raspios.img1 | awk '{gsub(/[ ]+/," ")}1' | cut -d ' ' -f 2 | cut -d ' ' -f 1)
START_PART_2=$(fdisk -l $WORKING_DIR/linux/raspios.img | grep raspios.img2 | awk '{gsub(/[ ]+/," ")}1' | cut -d ' ' -f 2 | cut -d ' ' -f 1)
UNITS=$(fdisk -l $WORKING_DIR/linux/raspios.img | grep 'Units\|Einheiten' | cut -d = -f 2 | cut -d ' ' -f 2 | cut -d ' ' -f 1)
OFFSET_PART_1=$(expr "$START_PART_1" '*' "$UNITS")
OFFSET_PART_2=$(expr "$START_PART_2" '*' "$UNITS")

# MOUNT IMAGE #
mount -v -o offset=$OFFSET_PART_2 -t ext4 $WORKING_DIR/linux/raspios.img $WORKING_DIR/linux/mnt/ext4
make ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- INSTALL_MOD_PATH=$WORKING_DIR/linux/mnt/ext4 -j $CPU_CORES_FOR_COMPILING modules_install | tee /tmp/INSTALL_MOD_OUTPUT.txt
VERSION=$(sudo tail -n 1 /tmp/INSTALL_MOD_OUTPUT.txt  | awk '{gsub(/[ ]+/," ")}1' | cut -d ' ' -f 3)
umount $WORKING_DIR/linux/mnt/ext4
mount -v -o offset=$OFFSET_PART_1 -t vfat $WORKING_DIR/linux/raspios.img $WORKING_DIR/linux/mnt/fat32
cp $WORKING_DIR/linux/mnt/fat32/$KERNEL.img $WORKING_DIR/linux/mnt/fat32/$KERNEL-backup.img
cp $WORKING_DIR/linux/arch/arm/boot/zImage $WORKING_DIR/linux/mnt/fat32/$KERNEL.img
cp $WORKING_DIR/linux/arch/arm/boot/dts/*.dtb $WORKING_DIR/linux/mnt/fat32/
cp $WORKING_DIR/linux/arch/arm/boot/dts/overlays/*.dtb* $WORKING_DIR/linux/mnt/fat32/overlays/
cp $WORKING_DIR/linux/arch/arm/boot/dts/overlays/README $WORKING_DIR/linux/mnt/fat32/overlays/
echo "kernel=$KERNEL.img" | tee -a $WORKING_DIR/linux/mnt/fat32/config.txt

# UNMOUNT IMAGE #
umount $WORKING_DIR/linux/mnt/fat32
mv $WORKING_DIR/linux/raspios.img "$WORKING_DIR"/RaspiOS_RPi4_"$VERSION"_"$MPTCP_BRANCH".img

### CLEANING UP AGAIN ###
cd $WORKING_DIR
sudo chown -R $(whoami):$(whoami) $WORKING_DIR/RaspiOS*
sudo chmod 755 $WORKING_DIR/RaspiOS*
ls -la RaspiOS*
rm -rf $WORKING_DIR/linux
rm -rf $WORKING_DIR/tools
rm -rf /tmp/INSTALL_MOD_OUTPUT.txt

# DONE #

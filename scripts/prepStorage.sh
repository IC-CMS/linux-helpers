#!/bin/bash

MOUNT_NAME="/data"
LVM_LABEL="lvm"
VGLABEL="vg"
LVLABEL="lv"
FORMAT="ext4"

while getopts ":m:d:f:" opt;
do
	case $opt in
		m)
			MOUNT_NAME="$OPTARG"
			echo "Setting MOUNT_NAME=$MOUNT_NAME"
			;;
		d)
			DEVICE="$OPTARG"
			echo "Setting DEVICE=$DEVICE"
			;;
		f) 
			FORMAT="$OPTARG"
			echo "Setting format to $FORMAT"
			;;
		?)
			echo "Usage: prepStorage.sh -d vxd[device letter] -m /data -f [ext4|xfs]"
			exit 1
			;;
	esac
done

if [[ "$DEVICE" == "" ]]; then
	echo "Exitting.  Device option -d cannot be empty."
	exit 1
fi

rpm -qa | grep -i lvm
if [[ $? -eq 1 ]]; then
	echo "Installing lvm2"
	sudo yum install -y lvm2*
fi

echo "Prepping to mount $DEVICE to $MOUNT_NAME"

# Display block devices
sudo lsblk

# Check to see if device exists
/bin/mount | grep -e "$MOUNT_NAME"
if [[ $? -eq 1 ]]; then
	MP="$DEVICE""1"
	echo "storage $MP is not mounted"

	sudo fdisk -l /dev/$DEVICE

	OUT=`ls /dev | grep -e "$MP"`
	if [ ! $? -eq 0 ]; then
		echo "Device /dev/$MP not found.  Creating Partition."
		sudo -s /sbin/fdisk /dev/$DEVICE <<< "n
p
1


t
83
w
"
	fi
# Done with interactive input
		echo "running pvcreate on /dev/$MP"
		sudo /sbin/pvcreate -d /dev/$MP

		sudo pvdisplay
		
		VGSCAN_OUT=$(sudo vgscan)
		
		VGTAG="$LVM_LABEL""_""$VGLABEL"
		echo "Running vgcreate $VGTAG /dev/$MP"
		sudo /sbin/vgcreate $VGTAG /dev/$MP

		sudo lvscan
		
		LVTAG="$LVM_LABEL""_""$LVLABEL"
		echo "Running lvcreate  -l 100%VG $VGTAG -n $LVTAG"
		sudo /sbin/lvcreate -l 100%VG $VGTAG -n $LVTAG

		# Display the new volume-group
		sudo lvdisplay -v /dev/$VGTAG/$LVTAG
		LVM_DEV="/dev/$VGTAG/$LVTAG"
		echo "Creating ext4 filesystem on $LVM_DEV"
		sudo /sbin/mkfs.ext4 $LVM_DEV

		sudo mkdir -p $MOUNT_NAME
		
		FSTAB_RESULT=$(sudo grep "$LVM_DEV" /etc/fstab)
		if [[ "$?" == "1" ]]; then
			sudo -s 'cat >> /etc/fstab "$LVM_DEV $MOUNT_NAME ext4  defaults 0 0"'
		fi
	sleep 5
	#sudo /bin/mount -a

	# look at it to see if it worked
	sudo /bin/mount $LVM_DEV $MOUNT_NAME
	
	if [[ "$?" == 0 ]]; then
		echo "Storage mounted!"
	else
		echo "ISSUES :("
	fi
fi

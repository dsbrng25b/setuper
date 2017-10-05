#!/bin/sh

set -o errexit

DEVICE="/dev/sda"
BOOT_PARTITION="${DEVICE}1"
MAIN_PARTITION="${DEVICE}2"
CRYPT_DEVICE_NAME="cryptroot"
CRYPT_PARTITION="/dev/mapper/${CRYPT_DEVICE_NAME}"

USERNAME="TODO"

pre_chroot_setup() {

	# create partition
	sfdisk "$DEVICE" <<EOF
,512M,,*
;
EOF

	# set datetime
	timedatectl set-ntp true

	# setup main partition
	cryptsetup -y -v luksFormat "$MAIN_PARTITION"
	cryptsetup open "$MAIN_PARTITION" "$CRYPT_DEVICE_NAME"
	mkfs.ext4 "$CRYPT_PARTITION"
	mount "$CRYPT_PARTITION" /mnt

	# setup boot partition

	mkdir /mnt/boot
	mkfs.ext4 -O '^64bit' "$BOOT_PARTITION"
	#resize2fs -s "$BOOT_PARTITION"
	mount "$BOOT_PARTITION" /mnt/boot

	# install base system
	echo 'Server = http://archlinux.puzzle.ch/$repo/os/$arch' > /etc/pacman.d/mirrorlist
	pacstrap /mnt base
	genfstab -U /mnt >> /mnt/etc/fstab
	cp "$0" /mnt/tmp/
	if ! arch-chroot /mnt sh /tmp/$( basename $0 ) post
	then
		echo "Something in the post setup went wrong. You can retry the setup by running the following commands: "
		echo ""
		echo "\tarch-chroot /mnt /bin/bash"
		echo "\tsh /tmp/$( basename $0 ) post"
		echo ""
	else
		echo "Setup was successful. You can reboot now:"
		echo ""
		echo "umount /mnt/boot"
		echo "umount /mnt"
		echo "reboot"
	fi
}

post_chroot_setup() {

	useradd -m -s /bin/bash "$USERNAME"

	echo "Set root password: "
	passwd

	echo "Set password for $USERNAME"
	passwd "$USERNAME"

	pacman -S git ansible python

	git clone https://github.com/dsbrng25b/setuper.git /tmp/setuper

	# run ansible as unpreviledged user that copied files get the right permission
	su -c 'ansible-playbook -K -i "localhost," -c local /tmp/setuper/all.yml' "$USERNAME"

}

if [ "$1" = "post" ]
then
	echo "### RUN POST CHROOT SETUP ###"
	post_chroot_setup
else
	echo "### PRE POST CHROOT SETUP ###"
	pre_chroot_setup
fi

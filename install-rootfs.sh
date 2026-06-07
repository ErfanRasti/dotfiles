#!/usr/bin/env bash
# Install the rootfs files which needs `sudo`

########################################################################################### root stow
# install-rootfs.sh — stow system-level files from rootfs/

# root files
cd "$HOME/dotfiles/rootfs/" || exit

# shellcheck disable=SC2035
sudo stow */
sudo systemctl daemon-reload
sudo systemctl enable --now powertop.service
sudo systemctl enable --now bluetooth-wakeup.service
# sudo find . -type f -exec install -D {} /{}

########################################################################################### Swap partition setup
# 1. Delete the previously created swap partition
sudo swapoff /swap/swapfile
sudo btrfs subvolume delete /swap

# 2. Mount your Btrfs root to a temporary location
sudo mkdir -p /mnt/btrfs
sudo mount -t btrfs /dev/mapper/root /mnt/btrfs

# 3. Delete the nested swap subvolume (Optional: instead of sudo btrfs subvolume delete /swap)
sudo btrfs subvolume delete /mnt/btrfs/@/swap

# 4. Create NEW top-level swap subvolume (at top level 5, same as @)
sudo btrfs subvolume create /mnt/btrfs/@swap

# 5. Unmount the temporary mount
sudo umount /mnt/btrfs

# 6. Create mount point and mount the new swap subvolume
sudo mkdir -p /swap
sudo mount -t btrfs -o subvol=@swap /dev/mapper/root /swap

# 7. Create the swapfile inside the new top-level subvolume
sudo btrfs filesystem mkswapfile --size 32g --uuid clear /swap/swapfile

# 8. Secure permissions
sudo chmod 0600 /swap/swapfile

# 9. Add to fstab (NOTE: subvol=@swap is critical)
## Get the UUID of your btrfs partition
BTRFS_UUID=$(sudo blkid -s UUID -o value /dev/mapper/root)
## Get the subvolume ID of @swap
SWAP_SUBVOL_ID=$(sudo btrfs subvolume list / | grep "@swap" | awk '{print $2}')

## Add to fstab with subvolid
echo "# /dev/mapper/ainstsda2 - Swap subvolume" | sudo tee -a /etc/fstab
echo "UUID=$BTRFS_UUID /swap btrfs rw,noatime,nodatacow,compress=no,ssd,space_cache=v2,subvolid=$SWAP_SUBVOL_ID,subvol=/@swap 0 0" | sudo tee -a /etc/fstab

# 10. Add swap entry to fstab
sudo bash -c "echo # Swap partition >> /etc/fstab"
sudo bash -c "echo /swap/swapfile none swap defaults,pri=60 0 0 >> /etc/fstab"

########################################################################################### hibernation setup
# Hibernate Setup Script for BTRFS Swapfile

# Step 1: Create the hibernation image size config
echo "Creating /etc/tmpfiles.d/hibernation_image_size.conf..."
sudo rm -f /etc/tmpfiles.d/hibernation_image_size.conf
sudo cat <<EOF | sudo tee /etc/tmpfiles.d/hibernation_image_size.conf >/dev/null
#    Path                   Mode UID  GID  Age Argument
w    /sys/power/image_size  -    -    -    -   0
EOF

# Step 2: Add resume hook to mkinitcpio.conf
echo "Adding resume hook to /etc/mkinitcpio.conf..."
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.backup
sudo sed -i '/HOOKS=/ s/\(filesystems\) \(fsck\)/\1 resume \2/' /etc/mkinitcpio.conf

# Step 3: Regenerate initramfs
echo "Regenerating initramfs..."
sudo mkinitcpio -P

# Step 4: Find the swapfile offset
echo "Finding swapfile offset..."
OFFSET=$(sudo btrfs inspect-internal map-swapfile -r /swap/swapfile)
echo "Offset: $OFFSET"

# Step 5: Set resume_offset
echo "Setting resume_offset..."
echo "$OFFSET" | sudo tee /sys/power/resume_offset

# Step 6: Verify the setting
echo "Current resume_offset:"
cat /sys/power/resume_offset

# Step 7: Reboot
echo "Setup complete! Rebooting the system."

########################################################################################### plymouth setup
# Plymouth Setup Script

# Step 1: Install Plymouth
echo "Installing Plymouth..."
sudo pacman -S plymouth

# Step 2: Add plymouth to mkinitcpio.conf
echo "Adding plymouth hook to /etc/mkinitcpio.conf..."
sudo cp /etc/mkinitcpio.conf /etc/mkinitcpio.conf.plymouth.backup

# Add plymouth before encrypt (adjust the pattern if you use sd-encrypt)
sudo sed -i '/HOOKS=/ s/\(block\) \(encrypt\)/\1 plymouth \2/' /etc/mkinitcpio.conf

# Step 3: Regenerate initramfs
echo "Regenerating initramfs..."
sudo mkinitcpio -P

echo "Plymouth setup complete!"
echo "Make sure you have 'quiet splash' in your boot entries."

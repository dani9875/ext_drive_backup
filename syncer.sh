#!/bin/bash

# Prompt for the passphrase securely
echo "Enter passphrase for /dev/sda1:"
read -s passphrase

# Open the encrypted volume using cryptsetup
echo "$passphrase" | sudo cryptsetup luksOpen /dev/sda1 sda1

# Create the mount point if it doesn't exist
sudo mkdir -p /mnt/encrypted

# Mount the encrypted device
sudo mount /dev/mapper/sda1 /mnt/encrypted

# Use rclone to copy files from remote "Let's eat something" to the external drive
echo "Starting file copy from remote..."
rclone copy "remote:Let's eat something" /mnt/encrypted/ --progress

# Unmount the device after copying
sudo umount /dev/mapper/sda1

# Close the encrypted volume
echo "$passphrase" | sudo cryptsetup luksClose sda1

echo "Process complete."


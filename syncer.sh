#!/bin/bash

read -sp "Enter your rclone password: " PASSWORD

cleanup() {
    local device="$1"
    
    echo "Graceful exit: Cleaning up..."

    # First rclone config session
    expect <<EOF
        spawn rclone config
        send "$PASSWORD\r"
        send "s\r"
        send "u\r"
        send "q\r"
        send "q\r"
        expect eof
EOF

    # Second rclone config session
    expect <<EOF
        spawn rclone config
        send "d\r"
        send "1\r"
        send "q\r"
        expect eof
EOF

    # Unmount the device after copying
    sudo umount /dev/mapper/$device

    # Close the encrypted volume
    sudo cryptsetup luksClose $device

    rm -R ~/mount

    echo "Process complete."
}

handle_interrupt() {
    echo "Detected Ctrl+C (SIGINT). Performing graceful exit..."
    cleanup "$device" "$passphrase"
    exit 1  # Optional: exit with a non-zero status to indicate interruption
}

# Prompt for the device name, with a default value of sda1 if nothing is entered
echo "Enter device name (e.g., sda1) [default: sda1]:"
read device
device="${device:-sda1}"

# Prompt for the passphrase securely
echo "Enter passphrase for device $device:"
read -s passphrase

# Open the encrypted volume using cryptsetup
echo "$passphrase" | sudo cryptsetup luksOpen "/dev/$device" "$device" || { echo "Failed to unlock device"; exit 1; }

echo "Device unlocked successfully."

# Create the mount point if it doesn't exist
mkdir -p ~/mount/encrypted

# Mount the encrypted device
sudo mount /dev/mapper/$device ~/mount/encrypted
# Change ownership of the mounted files to the current user
sudo chown -R $(id -u):$(id -g) ~/mount/encrypted

expect <<EOF
spawn rclone config
expect -timeout 15 "n/s/q>"
send "n\r"
send "remote\r"
send "drive\r"
send "\r"
send "\r"
send "drive.readonly\r"
send "\r"
send "n\r"
send "y\r"
expect -timeout 60 "Configure this as a Shared Drive (Team Drive)?"
send "n\r"
send "y\r"
send "q\r"
expect eof
EOF

expect <<EOF
spawn rclone config
send "s\r"
send "a\r"
send "$PASSWORD\r"
send "$PASSWORD\r"
send "q\r"
send "q\r"
expect eof
EOF

# Trap SIGINT (Ctrl+C) signal to call handle_interrupt function
trap handle_interrupt SIGINT

# Use rclone to copy files from remote " to the external drive
echo "Starting file copy from remote..."
# rclone sync "remote:Let's eat something" ~/mount/encrypted --progress

# Get the full path of the directory where you want to sync
SYNC_DIR="$HOME/mount/encrypted/Backup"

# Run rclone sync command with expect, including password sending
expect <<EOF
spawn rclone sync "remote:Let's eat something" "$SYNC_DIR" --progress
expect -timeout 10 "Enter configuration password:?"
send "$PASSWORD\r"
expect eof
EOF

# Check if rclone completed successfully
if [ $? -eq 0 ]; then
    echo "Sync completed successfully."
else
    echo "rclone sync failed."
fi

cleanup "$device"

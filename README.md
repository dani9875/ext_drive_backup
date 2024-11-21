# External drive backup
If you store your data on Google Drive but occasionally need to sync it to an external drive, this script will automate the process, saving you from manually downloading or using Google Takeout. The script works properly only on Linux.

## Overview

This script leverages rclone to sync the content from your Google Drive root to an external drive. The initial sync may take some time, but afterward, only changes will be synced. The sync mechanism mirrors your Google Drive content, ensuring that any mismatched files are deleted from the drive. Be sure to have enough space on your external drive. Additionally, since my external drives are encrypted with LUKS, the script also includes functionality for unlocking and locking the drives during the sync process.

## Prerequisites

Before running the setup, ensure the following tools are installed:

- **rclone**: A command-line program to manage files on cloud storage.
- **expect**: A program to automate interactions with command-line applications.
- **cryptsetup**: A utility for setting up disk encryption.

You can install these tools using the following commands:

```bash
# Install rclone
sudo apt install rclone

# Install expect
sudo apt install expect

# Install cryptsetup
sudo apt install cryptsetup
```````

## How to Use It

### Locking your drive with LUKS

1. Take your external drive and format it. Use the entire space and create a FAT partition. Assign a name to the partition.
2. Open a terminal and run `lsblk` to identify the label of your disk.
3. Run the following command to encrypt the partition with LUKS:
    ```bash
    sudo cryptsetup --verbose --verify-passphrase luksFormat <disk_label>   # <disk_label> e.g. /dev/sda1
    ```
    - Enter and verify your passphrase when prompted.
4. After encryption, open the disk with the following command:
    ```bash
    sudo cryptsetup luksOpen /dev/sda1 sda1
    ```
    This will unlock the disk for formatting.
5. Format the unlocked disk with the `ext4` file system:
    ```bash
    sudo mkfs.ext4 /dev/mapper/sda1
    ```
6. Optionally, disable reserved space for root (set to 0%):
    ```bash
    sudo tune2fs -m 0 /dev/mapper/sda1
    ```
7. Once you're finished, close the encrypted disk:
    ```bash
    sudo cryptsetup luksClose sda1
    ```

This process ensures that your external drive is encrypted and formatted as `ext4`, which will only be accessible on Linux systems.

### Syncing your GDrive

1. Open a terminal in the project root and run the script:
    ./syncer.sh

2. You will be prompted to add a password for the rclone configuration. This will encrypt your rclone config file for security purposes.

3. Add the label of your external drive (if you're unsure of the drive label, run lsblk to list all connected devices).

4. Enter your passphrase to unlock your external storage drive.

5. You will need sudo permissions to mount the external drive, so provide your password when prompted.

6. After a few seconds, you will be redirected to a Google authentication page. Grant permission for rclone to access your Google Drive.

7. Once authenticated, the sync process will start automatically.

8. You can press CTRL+C at any time to gracefully exit the script. If the sync is completed, the script will automatically close your drive, unmount it, and delete the rclone config file.

Notes

Make sure your external drive has sufficient space for all the data you plan to sync.
The first sync might take a longer time, but subsequent syncs will only update changed files.
The script is designed for Linux systems and assumes that you are familiar with using the command line.
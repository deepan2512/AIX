#!/bin/bash

# Variables
MOUNT_POINT="/mnt"
NFS_SERVER="dc1nim:/export/mksysb /mnt"
BACKUP_FILE="dc2nim1_mksysb"
BACKUP_PATH="$MOUNT_POINT/$BACKUP_FILE"
PREV_BACKUP="$BACKUP_PATH.prev"
LOG_FILE="/tmp/mksysb.log"
EMAIL="deepan.s@kyndryl.com"

# Step 1: Check if /mnt is mounted, if not, mount it
if ! mount | grep -q "$MOUNT_POINT"; then
    echo "/mnt is not mounted. Attempting to mount..."
    mount $NFS_SERVER $MOUNT_POINT
    if [ $? -ne 0 ]; then
        echo "Failed to mount $NFS_SERVER to $MOUNT_POINT. Exiting." | mail -s "MKSYSB Backup Error" $EMAIL
        exit 1
    fi
    echo "/mnt mounted successfully."
else
    echo "/mnt is already mounted."
fi

# Step 2: Change directory to /mnt
cd $MOUNT_POINT || { echo "Failed to change directory to $MOUNT_POINT"; exit 1; }

# Step 3: Check for existing mksysb file and rename if it exists
if [ -f "$BACKUP_PATH" ]; then
    echo "Found existing mksysb file. Renaming to $PREV_BACKUP..."
    mv "$BACKUP_PATH" "$PREV_BACKUP"
    if [ $? -ne 0 ]; then
        echo "Failed to rename existing mksysb file." | mail -s "MKSYSB Backup Error" $EMAIL
        exit 1
    fi
    echo "Old mksysb backup renamed successfully."
fi

# Step 4: Run the mksysb backup command
echo "Starting mksysb backup..."
mksysb -i "$BACKUP_PATH" > "$LOG_FILE"
if [ $? -ne 0 ]; then
    echo "mksysb backup failed. Check $LOG_FILE for details." | mail -s "MKSYSB Backup Error" $EMAIL
    exit 1
fi
echo "mksysb backup completed successfully."

# Step 5: Unmount /mnt if backup was successful, or send an error email
echo "Unmounting $MOUNT_POINT..."
cd /
umount $MOUNT_POINT
if [ $? -ne 0 ]; then
    echo "Failed to unmount $MOUNT_POINT." | mail -s "MKSYSB Backup Error" $EMAIL
    exit 1
fi
echo "/mnt unmounted successfully."

# End of Script
echo "Backup process completed." 

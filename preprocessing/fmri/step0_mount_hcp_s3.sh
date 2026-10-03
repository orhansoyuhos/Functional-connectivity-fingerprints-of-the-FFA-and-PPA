#!/bin/bash
# Step 0 (fMRI): mount the HCP Open Access S3 bucket (hcp-openaccess) with s3fs.
#
# Runs in Ubuntu. On Windows, install WSL first (PowerShell as administrator:
# `wsl --install`), restart if asked, and open Ubuntu from the Start menu.
#
# You need an HCP account with Amazon S3 access. Create your AWS keys in
# ConnectomeDB (https://db.humanconnectome.org) and set them in the shell
# before running this script; never write them into a file in this repository:
#   export HCP_AWS_ACCESS_KEY=...
#   export HCP_AWS_SECRET_KEY=...
#   bash step0_mount_hcp_s3.sh        # not with sudo; the script calls sudo itself
#
# The bucket is mounted at /home/<user>/hcp-openaccess. The HCP 1200 data are
# then in /home/<user>/hcp-openaccess/HCP_1200 (mount_point in Step 1).
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

set -e
: "${HCP_AWS_ACCESS_KEY:?Set HCP_AWS_ACCESS_KEY first}"
: "${HCP_AWS_SECRET_KEY:?Set HCP_AWS_SECRET_KEY first}"

USER_NAME=$(whoami)
S3_BUCKET_DIR=/home/$USER_NAME/hcp-openaccess   # mount point of the bucket
PATH_TO_FILE=/home/$USER_NAME/.passwd-s3fs      # s3fs credentials file

# Install s3fs
sudo apt update
sudo apt install s3fs -y

# Folder for the mounted bucket
sudo mkdir -p "$S3_BUCKET_DIR"

# Credentials file (ACCESS_KEY:SECRET_ACCESS_KEY), readable by the owner only
echo "$HCP_AWS_ACCESS_KEY:$HCP_AWS_SECRET_KEY" | sudo tee "$PATH_TO_FILE" > /dev/null
sudo chmod 600 "$PATH_TO_FILE"
sudo chown "$USER_NAME:$USER_NAME" "$PATH_TO_FILE"
ls -l "$PATH_TO_FILE"

# Mount the bucket and list its contents
sudo s3fs hcp-openaccess "$S3_BUCKET_DIR" -o passwd_file="$PATH_TO_FILE" -o dbglevel=info -o curldbg -o umask=0077
sudo chown "$USER_NAME:$USER_NAME" "$S3_BUCKET_DIR"
sudo ls "$S3_BUCKET_DIR"

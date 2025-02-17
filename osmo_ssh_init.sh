#!/bin/bash

# Determine the correct home directory based on the available mount point
if [ -d "/mnt/amlfs-01/home/yuqix" ]; then
    MY_HOME="/mnt/amlfs-01/home/yuqix"
elif [ -d "/mnt/amlfs-04/home/yuqix" ]; then
    MY_HOME="/mnt/amlfs-04/home/yuqix"
else
    echo "Error: Could not find the correct home directory."
    exit 1
fi

echo "Using MY_HOME: $MY_HOME"

# Run essential installation script
sh ./scripts/install_essentials.sh

# Copy SSH keys
cp -r "$MY_HOME/.ssh" ~/.ssh

# Install Miniforge
ARCH=$(uname -m)
OS=$(uname)
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${OS}-${ARCH}.sh" -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p /opt/conda
rm /tmp/miniconda.sh

# Run additional scripts
sh ./scripts/zsh_init.sh
sh ./scripts/zsh_plugin.sh
sh ./scripts/git_config.sh

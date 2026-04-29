#!/bin/bash

# Determine the persistent home directory based on the available mount point.
if [ -d "/mnt/aws-lfs-03/shared/yuqix" ]; then
    MY_HOME="/mnt/aws-lfs-03/shared/yuqix"
elif [ -d "/mnt/amlfs-01/home/yuqix" ]; then
    MY_HOME="/mnt/amlfs-01/home/yuqix"
elif [ -d "/mnt/amlfs-04/home/yuqix" ]; then
    MY_HOME="/mnt/amlfs-04/home/yuqix"
elif [ -d "/mnt/aws-lfs-02/home/yuqix" ]; then
    MY_HOME="/mnt/aws-lfs-02/home/yuqix"
else
    echo "Error: Could not find the correct home directory."
    exit 1
fi

echo "Using MY_HOME: $MY_HOME"
RUNTIME_HOME="${HOME:-/root}"
if [ ! -d "$RUNTIME_HOME" ]; then
    echo "Runtime HOME $RUNTIME_HOME does not exist; using MY_HOME as HOME."
    export HOME="$MY_HOME"
    RUNTIME_HOME="$MY_HOME"
fi
mkdir -p "$RUNTIME_HOME"

# Run essential installation script
sh ./scripts/install_essentials.sh

# Copy SSH keys
if [ -d "$MY_HOME/.ssh" ]; then
    rm -rf "$RUNTIME_HOME/.ssh"
    cp -r "$MY_HOME/.ssh" "$RUNTIME_HOME/.ssh"
    chmod 700 "$RUNTIME_HOME/.ssh"
    chmod 600 "$RUNTIME_HOME/.ssh"/* 2>/dev/null || true
else
    echo "Warning: $MY_HOME/.ssh does not exist; skipping SSH key copy."
fi
# Copy git credentials
if [ -f "$MY_HOME/.git-credentials" ]; then
    cp "$MY_HOME/.git-credentials" "$RUNTIME_HOME/.git-credentials"
else
    echo "Warning: $MY_HOME/.git-credentials does not exist; GitLab PAT prompt will recreate it."
fi

# Install Miniforge
ARCH=$(uname -m)
OS=$(uname)
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${OS}-${ARCH}.sh" -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p /opt/conda
rm /tmp/miniconda.sh
rm -r /opt/conda/envs
mkdir -p "$MY_HOME/conda_envs"
ln -s "$MY_HOME/conda_envs" /opt/conda/envs
# Run additional scripts
sh ./scripts/zsh_init.sh
sh ./scripts/zsh_plugin.sh
sh ./scripts/git_config.sh

ZSHRC_PATH="$RUNTIME_HOME/.zshrc"
append_zshrc() {
    grep -qxF "$1" "$ZSHRC_PATH" 2>/dev/null || echo "$1" >> "$ZSHRC_PATH"
}

append_zshrc "export MY_HOME=$MY_HOME"
append_zshrc "HISTFILE=$MY_HOME/.zsh_history"
echo "Updated HISTFILE in ~/.zshrc to: $MY_HOME/.zsh_history"

if [ -d "/mnt/aws-lfs-03/shared" ]; then
    HF_HUB_CACHE_PATH="/mnt/aws-lfs-03/shared/ckpts"
    LFS_CACHE_PATH_VALUE="/mnt/aws-lfs-03/shared/datasets"
    MSC_CACHE_PATH_VALUE="/mnt/aws-lfs-03/shared/msc_cache"
elif [ -d "/mnt/aws-lfs-02/shared" ]; then
    HF_HUB_CACHE_PATH="/mnt/aws-lfs-02/shared/ckpts"
    LFS_CACHE_PATH_VALUE="/mnt/aws-lfs-02/shared/datasets"
    MSC_CACHE_PATH_VALUE="/mnt/aws-lfs-02/shared/msc_cache"
else
    HF_HUB_CACHE_PATH="/mnt/amlfs-02/shared/ckpts"
    LFS_CACHE_PATH_VALUE="/mnt/amlfs-02/shared/datasets"
    MSC_CACHE_PATH_VALUE="/mnt/amlfs-07/shared/msc_cache"
fi

append_zshrc "export HF_HUB_CACHE=$HF_HUB_CACHE_PATH"
append_zshrc "export LFS_CACHE_PATH=$LFS_CACHE_PATH_VALUE"
append_zshrc "export MSC_CACHE_PATH=$MSC_CACHE_PATH_VALUE"
append_zshrc "export HF_HUB_OFFLINE=1"


VENV_PATH="$RUNTIME_HOME/venv/bin/activate"
ROS_SETUP_PATH="/opt/ros/humble/setup.zsh"

# Add venv activation to .zshrc if it exists
if [ -f "$VENV_PATH" ]; then
    append_zshrc "source $VENV_PATH"
    echo "Added virtual environment activation to $ZSHRC_PATH"
fi

# Add ROS2 setup to .zshrc if it exists
if [ -f "$ROS_SETUP_PATH" ]; then
    append_zshrc "source $ROS_SETUP_PATH"
    echo "Added ROS2 setup to $ZSHRC_PATH"
    append_zshrc "export ROS_LOCALHOST_ONLY=1"
fi


# Prompt user for GitLab Personal Access Token
echo "Please enter your GitLab Personal Access Token (GITLAB_PAT):"
read -s GITLAB_PAT
echo ""

git config --global credential.helper store
echo "https://token:${GITLAB_PAT}@gitlab-master.nvidia.com" > "$RUNTIME_HOME/.git-credentials"
echo "https://token:${GITHUB_PAT}@github.com" >> "$RUNTIME_HOME/.git-credentials"
git config --global credential.helper 'store --file ~/.git-credentials'

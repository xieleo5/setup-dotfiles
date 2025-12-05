#!/bin/bash

# Determine the correct home directory based on the available mount point
if [ -d "/mnt/amlfs-01/home/yuqix" ]; then
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

# Run essential installation script
sh ./scripts/install_essentials.sh

# Copy SSH keys
cp -r "$MY_HOME/.ssh" ~/.ssh
# Copy git credentials
cp "$MY_HOME/.git-credentials" ~/.git-credentials

# Install Miniforge
ARCH=$(uname -m)
OS=$(uname)
wget "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-${OS}-${ARCH}.sh" -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p /opt/conda
rm /tmp/miniconda.sh
rm -r /opt/conda/envs
ln -s /mnt/amlfs-01/home/yuqix/conda_envs /opt/conda/envs
# Run additional scripts
sh ./scripts/zsh_init.sh
sh ./scripts/zsh_plugin.sh
sh ./scripts/git_config.sh

echo "HISTFILE=$MY_HOME/.zsh_history" >> ~/.zshrc
echo "Updated HISTFILE in ~/.zshrc to: $MY_HOME/.zsh_history"
echo "export HF_HUB_CACHE=/mnt/amlfs-02/shared/ckpts" >> ~/.zshrc
echo "export HF_HUB_OFFLINE=1" >> ~/.zshrc


ZSHRC_PATH="/root/.zshrc"
VENV_PATH="/root/venv/bin/activate"
ROS_SETUP_PATH="/opt/ros/humble/setup.zsh"

# Add venv activation to .zshrc if it exists
if [ -f "$VENV_PATH" ]; then
    echo "source $VENV_PATH" >> "$ZSHRC_PATH"
    echo "Added virtual environment activation to $ZSHRC_PATH"
fi

# Add ROS2 setup to .zshrc if it exists
if [ -f "$ROS_SETUP_PATH" ]; then
    echo "source $ROS_SETUP_PATH" >> "$ZSHRC_PATH"
    echo "Added ROS2 setup to $ZSHRC_PATH"
    echo "export ROS_LOCALHOST_ONLY=1" >> "$ZSHRC_PATH"
fi


# Prompt user for GitLab Personal Access Token
echo "Please enter your GitLab Personal Access Token (GITLAB_PAT):"
read -s GITLAB_PAT
echo ""

git config --global credential.helper store
echo "https://token:${GITLAB_PAT}@gitlab-master.nvidia.com" > ~/.git-credentials
echo "https://token:${GITHUB_PAT}@github.com" >> ~/.git-credentials
git config --global credential.helper 'store --file ~/.git-credentials'

echo "export no_proxy=localhost,127.0.0.1,::1" >> ~/.zshrc
echo "export https_proxy=http://squid-proxy.osmo-squid-proxy.svc.cluster.local:3128" >> ~/.zshrc
echo "export HTTPS_PROXY=http://squid-proxy.osmo-squid-proxy.svc.cluster.local:3128" >> ~/.zshrc
echo "export HTTP_PROXY=http://squid-proxy.osmo-squid-proxy.svc.cluster.local:3128" >> ~/.zshrc
echo "export http_proxy=http://squid-proxy.osmo-squid-proxy.svc.cluster.local:3128" >> ~/.zshrc

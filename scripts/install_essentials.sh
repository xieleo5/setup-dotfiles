DEBIAN_FRONTEND=noninteractive

apt update && \
    apt install -y git curl software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt install -y ffmpeg libsm6 libxext6 wget cmake build-essential vim tmux wget rsync unzip git-lfs 

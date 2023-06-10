# syntax=docker/dockerfile:1
FROM nvidia/cuda:11.4.0-runtime-ubuntu20.04

# Set the timezone environmental variable
ENV TZ=Australia/Sydney

# Update the apt sources
RUN apt update

# Install pip so that we can install PyTorch
RUN DEBIAN_FRONTEND=noninteractive apt install -y python3.8 python3-pip

# Install PyTorch
RUN pip3 install --upgrade pip
RUN pip3 install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu116

# Unminimize Ubunutu, and install a bunch of necessary/helpful packages
RUN yes | unminimize
RUN DEBIAN_FRONTEND=noninteractive apt install -y ubuntu-server openssh-server python-is-python3 git python3-venv build-essential curl git gnupg2 make cmake ffmpeg swig libz-dev unzip zlib1g-dev libglfw3 libglfw3-dev libxrandr2 libxinerama-dev libxi6 libxcursor-dev libgl1-mesa-dev libgl1-mesa-glx libglew-dev libosmesa6-dev lsb-release ack-grep patchelf wget xpra xserver-xorg-dev xvfb python-opengl ffmpeg

# Move to the root home directory
WORKDIR /root

# Do things which require secrets: set up git and clone the repo
RUN --mount=type=secret,id=my_env,mode=0444 /bin/bash -c 'source /run/secrets/my_env \
    && git config --global user.name "${GIT_NAME}" \
    && git config --global user.email "${GIT_EMAIL}" \
    && git clone https://github.com/luciaquirke/superposition.git \
    && mkdir -p .ssh \
    && echo ${SSH_PUBKEY} > .ssh/authorized_keys'

# Add /root/.local/bin to the path
ENV PATH=/root/.local/bin:/usr/local/nvidia/bin:/usr/local/cuda/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Move to the repo directory
WORKDIR superposition

# Install all the required packages
RUN pip install --upgrade pip \
    && pip install wheel \
    && pip install -r requirements.txt \
    && pip install nvitop

# Go back to the root
WORKDIR /root

# Expose the default SSH port (inside the container)
EXPOSE 22
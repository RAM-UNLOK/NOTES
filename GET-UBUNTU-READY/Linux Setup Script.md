<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# can you create a script to automate the installation of all packages

Here's a shell script that will automate the entire installation and setup of all required packages, symlinks, and helper tools for building AOSP custom ROMs on Kubuntu 24.04.3 LTS. Simply save this script as `setup_aosp_env.sh`, make it executable, and run it with root privileges.

```bash
#!/bin/bash

# Make System Ready to Build Custom ROM on Kubuntu 24.04.3 LTS

set -e
echo "Updating and Upgrading System..."
sudo apt-get update && sudo apt-get upgrade -y

echo "Adding git-core PPA..."
sudo add-apt-repository ppa:git-core/ppa -y
sudo apt-get update && sudo apt-get upgrade -y

echo "Installing Essential Build Tools..."
sudo apt-get install -y bc bison build-essential ccache curl flex git \
g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses-dev \
lib32z1-dev libc6-dev-i386 libgl1-mesa-dev libssl-dev libx11-dev

echo "Installing Additional Libraries and Utilities..."
sudo apt-get install -y libxml2-utils unzip xorg-dev xsltproc zip zlib1g-dev \
default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils

echo "Installing Kernel-Related Packages..."
sudo apt-get install -y git automake flex lzop bison gperf build-essential zip curl \
zlib1g-dev g++-multilib python3-networkx libxml2-utils bzip2 libbz2-dev libbz2-1.0 \
libghc-bzlib-dev squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool \
make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom \
libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 xorg-dev libx11-dev \
lib32z1-dev libgl1-mesa-dev xsltproc unzip

echo "Installing Archive and Compression Tools..."
sudo apt-get install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar \
uudeview mpack arj cabextract rename liblzma-dev brotli lz4 \
libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x

echo "Installing Python Dependencies and Dev Tools..."
sudo apt-get install -y python3 python3-full python3-pip python3-protobuf \
python-is-python3 python3-venv libncurses6 fontconfig rsync openssl clang cmake ninja-build \
libncurses-dev lib32stdc++6 libelf-dev libsdl2-dev

echo "Fixing libncurses5 compatibility issues..."
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
sudo ln -sf /usr/lib32/libncurses.so.6 /usr/lib32/libncurses.so.5
sudo ln -sf /usr/lib32/libtinfo.so.6 /usr/lib32/libtinfo.so.5

echo "Setting up Android SDK Platform Tools Path..."
if ! grep -q "ANDROID_HOME" ~/.bashrc; then
cat <<EOL >> ~/.bashrc
# AOSP Build Configuration
export USE_CCACHE=1
ccache -M 150G
PATH="\${HOME}/.bin:\${PATH}"

# Android SDK Configuration
export ANDROID_HOME=\${HOME}/Android/Sdk
export PATH=\${PATH}:\${ANDROID_HOME}/platform-tools
export PATH=\${PATH}:\${ANDROID_HOME}/cmdline-tools/latest/bin:\${ANDROID_HOME}/build-tools/34.0.0
EOL
fi
source ~/.bashrc

echo "Setting up git-repo..."
mkdir -p ~/.bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
chmod a+rx ~/.bin/repo

echo "Configuring Git (Set your name and email on next step)..."
git config --global user.name "Your Name"
git config --global user.email "youremail@example.com"

echo "Flatpak Installation (optional)..."
sudo apt install -y flatpak plasma-discover-backend-flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Telegram PPA Installation..."
sudo add-apt-repository ppa:atareao/telegram -y
sudo apt-get update
sudo apt-get install -y telegram

echo "Installation Complete. Please reboot your system to finalize setup."
```

**Instructions:**

1. Copy this script to a file named `setup_aosp_env.sh`
2. Run:

```bash
chmod +x setup_aosp_env.sh
sudo ./setup_aosp_env.sh
```

3. Follow additional prompts for Git configuration.

This script will set up all necessary packages, symlinks, and environment variables needed to build AOSP ROMs on Kubuntu 24.04.3 LTS.[^1][^2][^3]

<div align="center">⁂</div>

[^1]: https://stackoverflow.com/questions/78857564/unable-to-compile-aosp-source-code-on-ubuntu-24-04-system

[^2]: Make-System-Ready-to-Build-Custom-Rom-on-Ubuntu-24.04.2.md

[^3]: https://source.android.com/docs/setup/start/requirements


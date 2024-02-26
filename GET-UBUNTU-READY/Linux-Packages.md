# Make System Ready to Build Custom Rom on Ubuntu 23.10

- Lets start by updating ubuntu packages and install new one later

```
sudo apt-get update && sudo apt-get upgrade
```
```
sudo add-apt-repository ppa:git-core/ppa
```
```
sudo apt-get update && sudo apt-get upgrade
```
```
sudo apt-get install bc bison build-essential ccache curl flex git \
g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses-dev \
lib32z1-dev libc6-dev-i386 libgl1-mesa-dev libssl-dev libx11-dev
```
```
sudo apt-get install libxml2-utils unzip x11proto-core-dev xsltproc zip zlib1g-dev \
default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils
```
```
sudo apt-get install libc6 libncurses6 libstdc++6 lib32z1 libbz2-1.0 \
bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses6
```
```
sudo apt-get install lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libsdl1.2-dev \
libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync tmate schedtool \
squashfs-tools xsltproc zip zlib1g-dev
```
```
sudo apt-get install python3 python3-full python3-pip python3-protobuf \
python-is-python3 libncurses6
```


- incase you face any issue use the below lines and then try again with the failed one

```
sudo apt-get update --fix-missing
```
```
sudo apt-get install -f
```
```
sudo apt-get clean
```
```
sudo apt-get autoremove
```


- More packages

```
sudo apt-get install unace unrar zip unzip p7zip-full p7zip-rar sharutils rar \
uudeview mpack arj cabextract rename liblzma-dev brotli lz4 \
libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x
```


- Kernel Related Packeages Optional

```
sudo apt-get install git automake flex lzop bison gperf build-essential zip curl \
zlib1g-dev zlib1g-dev g++-multilib python3-networkx \
libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev
```
```
sudo apt-get install squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool \
make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom
```
```
sudo apt-get install libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 \
x11proto-core-dev libx11-dev lib32z1-dev libgl1-mesa-dev xsltproc unzip
```


- Add latest git-repo

```
mkdir -p ~/.bin
```
```
PATH="${HOME}/.bin:${PATH}"
```
```
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
```
```
chmod a+rx ~/.bin/repo
```

> Edit bashrc and add these line and save by `ctrl+o` & `ctrl+x`
> this will make androidsdk & git-repo system wide

```
nano ~/.bashrc
```
```
export USE_CCACHE=1
ccache -M 150G
PATH="${HOME}/.bin:${PATH}"

export ANDROID_HOME=${HOME}/Android/Sdk
export PATH=${PATH}:${ANDROID_HOME}/platform-tools
export PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/build-tools/34.0.0
```


- Create Symlink for libncurses.so.5 & libtinfo.so.5 (Only for 23.10)

```
sudo su
```
```
cd
```
```
ln -s /usr/lib32/libncurses.so.6.4 /usr/lib32/libncurses.so.5
```
```
ln -s /usr/lib/x86_64-linux-gnu/libncurses.so.6.4 /usr/lib/x86_64-linux-gnu/libncurses.so.5
```
```
ln -s /usr/lib32/libtinfo.so.6.4 /usr/lib32/libtinfo.so.5
```
```
ln -s /usr/lib/x86_64-linux-gnu/libtinfo.so.6.4 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
```
```
exit
```


- Install Flatpak (reboot is reqired at the end)

```
sudo apt install flatpak plasma-discover-backend-flatpak
```
```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

> Now install android studio via flatpak (reboot first if you haven't)

- Install Telegram PPA ( Flatpak or snap doesnt work sometimes )

```
sudo add-apt-repository ppa:atareao/telegram
```
```
sudo apt-get update
```
```
sudo apt-get install -y telegram
```

- Installing any `.deb` packages you downloaded use this

```
sudo dpkg -i /path/
```

> Install Git Kraken
> Install Chrome Via Deb package and change ( chrome://flags/ | TLS 1.3 hybridized Kyber support=enabled )


- removing an installed app (example as chrome)

> Just removes chrome and not its app data
```
sudo apt-get remove google-chrome-stable
```
> Removes app & app data
```
sudo apt --purge remove google-chrome-stable
```


- Create a new folder in root dir

```
sudo mkdir -m 775 Foldername
```
```
sudo chown -R username:group Foldername
```


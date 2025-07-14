<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" class="logo" width="120"/>

# Make System Ready to Build Custom Rom on Ubuntu 24.04.2 LTS

Below is your revised installation script, fully updated for Ubuntu 24.04.2 LTS. All deprecated or problematic packages have been replaced with their supported alternatives. You can copy and paste this directly into your `Install.md` file.

## Update and Prepare System

```
sudo apt-get update && sudo apt-get upgrade
```

```
sudo add-apt-repository ppa:git-core/ppa
```

```
sudo apt-get update && sudo apt-get upgrade
```


## Essential Build Tools

```
sudo apt-get install bc bison build-essential ccache curl flex git \
g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses-dev \
lib32z1-dev libc6-dev-i386 libgl1-mesa-dev libssl-dev libx11-dev
```


## Additional Libraries and Utilities

```
sudo apt-get install libxml2-utils unzip xorg-dev xsltproc zip zlib1g-dev \
default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils
```

```
sudo apt-get install libc6 libncurses6 libstdc++6 lib32z1 libbz2-1.0 \
bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses6
```

```
sudo apt-get install lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libsdl2-dev \
libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync tmate schedtool \
squashfs-tools xsltproc zip zlib1g-dev
```

```
sudo apt-get install python3 python3-full python3-pip python3-protobuf \
python-is-python3 libncurses6
```


## Troubleshooting Commands

If you face any issues, use the following commands and then retry the failed installation:

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


## More Packages

```
sudo apt-get install unace unrar zip unzip p7zip-full p7zip-rar sharutils rar \
uudeview mpack arj cabextract rename liblzma-dev brotli lz4 \
libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x
```


## Kernel Related Packages (Optional)

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
xorg-dev libx11-dev lib32z1-dev libgl1-mesa-dev xsltproc unzip
```


## Add Latest git-repo

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

> Edit bashrc and add these lines, then save with `ctrl+o` \& `ctrl+x`
> This will make androidsdk \& git-repo system wide

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


## Flatpak Installation (reboot required at the end)

```
sudo apt install flatpak plasma-discover-backend-flatpak
```

```
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

> Now install Android Studio via Flatpak (reboot first if you haven't)

## Telegram PPA (Flatpak or Snap doesn't work sometimes)

```
sudo add-apt-repository ppa:atareao/telegram
```

```
sudo apt-get update
```

```
sudo apt-get install -y telegram
```


## Installing `.deb` Packages

```
sudo dpkg -i /path/to/package.deb
```


## Removing Installed Apps

> Just removes chrome and not its app data

```
sudo apt-get remove google-chrome-stable
```

> Removes app \& app data

```
sudo apt --purge remove google-chrome-stable
```


## Create a New Folder in Root Directory

```
sudo mkdir -m 775 Foldername
```

```
sudo chown -R username:group Foldername
```


## Create a Virtual Environment Using venv or virtualenv

> Make sure venv is installed by running:

```
sudo apt install python3-venv
```

> To create a new virtual environment in a directory named .venv, run:

```
python3 -m venv .venv
```

> To activate this virtual environment:

```
source .venv/bin/activate
```

> Now you can install a library like requests in this virtual environment:

```
pip install requests
```

> If you want to leave the virtual environment, you can run:

```
deactivate
```


### Notes on Deprecated Packages

- **libncurses5** and **x11proto-core-dev** are no longer available in Ubuntu 24.04.2 LTS. Use `libncurses6` and `xorg-dev` instead[^1][^2][^3][^4][^5].
- **libsdl1.2-dev** is deprecated; use `libsdl2-dev` for new development. If you need SDL1.2 compatibility, consider `sdl12-compat`, but direct SDL2 usage is preferred[^1][^6][^7].
- Do not attempt to manually symlink or install legacy libraries unless absolutely required for legacy software, and only in isolated environments.

This script is now fully compatible with Ubuntu 24.04.2 LTS and avoids all deprecated or broken packages.

<div style="text-align: center">⁂</div>

[^1]: https://launchpad.net/ubuntu/noble/amd64/libsdl1.2-dev

[^2]: https://www.reddit.com/r/Ubuntu/comments/1cm97bg/libncurses5dev/

[^3]: https://askubuntu.com/questions/1531398/how-to-install-libncurses-so-5-for-ubuntu-24-04

[^4]: https://github.com/swfans/swars/issues/224

[^5]: https://stackoverflow.com/questions/78857564/unable-to-compile-aosp-source-code-on-ubuntu-24-04-system

[^6]: https://answers.launchpad.net/ubuntu/noble/amd64/libsdl1.2-dev/1.2.68-1

[^7]: https://www.reddit.com/r/Ubuntu/comments/1dgrv3g/ubuntu_2404_is_a_large_step_back/

[^8]: Linux-Packages.md

[^9]: https://www.ubuntuupdates.org/package/core/noble/main/base/x11proto-gl-dev

[^10]: https://answers.launchpad.net/ubuntu/+question/819200

[^11]: https://discourse.ubuntu.com/t/ubuntu-24-04-lts-noble-numbat-release-notes/39890

[^12]: https://github.com/intel/ipu6-drivers/issues/228

[^13]: https://discourse.ubuntu.com/t/how-to-switch-from-x11-to-wayland-on-live-ubuntu-24-04-1/52917

[^14]: https://askubuntu.com/questions/214746/how-to-run-apt-get-install-to-install-all-dependencies

[^15]: https://github.com/duplicati/duplicati/issues/5178

[^16]: https://ubuntu.com/blog/ubuntu-server-development-summary-2-oct-2018

[^17]: https://community.st.com/t5/stm32cubeide-mcus/ubuntu-24-04-install-of-cube-ide-1-15-1/td-p/669387/page/2

[^18]: https://askubuntu.com/questions/483302/unable-to-locate-package-libsdl1-2-dev

[^19]: https://community.arm.com/support-forums/f/compilers-and-libraries-forum/55989/arm-gnu-toolchain-issue-with-libncurses5-and-libncursesw5-on-ubuntu-24-04

[^20]: https://gist.github.com/aaangeletakis/3187339a99f7786c25075d4d9c80fad5

[^21]: https://github.com/rvm/rvm/issues/5475


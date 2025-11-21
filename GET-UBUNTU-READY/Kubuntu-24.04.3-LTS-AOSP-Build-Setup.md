# Make System Ready to Build Custom ROM on Kubuntu 24.04.3 LTS

> **Updated for Kubuntu 24.04.3 LTS / Ubuntu 24.04.3 LTS**  
> All deprecated packages have been replaced with their latest supported versions

---

## Update and Prepare System

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

```bash
sudo add-apt-repository ppa:git-core/ppa -y
```

```bash
sudo apt-get update && sudo apt-get upgrade -y
```

---

## Essential Build Tools

```bash
sudo apt-get install -y bc bison build-essential ccache curl flex git \
g++-multilib gcc-multilib gnupg gperf imagemagick lib32ncurses-dev \
lib32z1-dev libc6-dev-i386 libgl1-mesa-dev libssl-dev libx11-dev
```

---

## Additional Libraries and Utilities

```bash
sudo apt-get install -y libxml2-utils unzip xorg-dev xsltproc zip zlib1g-dev \
default-jre default-jdk nghttp2 libnghttp2-dev fakeroot dpkg-dev \
libcurl4-openssl-dev git-lfs patchelf policycoreutils-python-utils
```

```bash
sudo apt-get install -y libc6 libncurses6 libstdc++6 lib32z1 libbz2-1.0 \
bc bison build-essential ccache curl flex g++-multilib gcc-multilib git gnupg gperf imagemagick lib32ncurses6
```

```bash
sudo apt-get install -y lib32readline-dev lib32z1-dev liblz4-tool libncurses6 libsdl2-dev \
libssl-dev libwxgtk3.2-dev libxml2 libxml2-utils lzop pngcrush rsync tmate schedtool \
squashfs-tools xsltproc zip zlib1g-dev
```

---

## Python Dependencies

```bash
sudo apt-get install -y python3 python3-full python3-pip python3-protobuf \
python-is-python3 libncurses6 python3-venv
```

---

## Troubleshooting Commands

If you face any issues, use the following commands and then retry the failed installation:

```bash
sudo apt-get update --fix-missing
```

```bash
sudo apt-get install -f
```

```bash
sudo apt-get clean
```

```bash
sudo apt-get autoremove -y
```

---

## Archive and Compression Tools

```bash
sudo apt-get install -y unace unrar zip unzip p7zip-full p7zip-rar sharutils rar \
uudeview mpack arj cabextract rename liblzma-dev brotli lz4 \
libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev asciidoc xmlto docbook2x
```

---

## Kernel Related Packages (Optional)

```bash
sudo apt-get install -y git automake flex lzop bison gperf build-essential zip curl \
zlib1g-dev g++-multilib python3-networkx \
libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev
```

```bash
sudo apt-get install -y squashfs-tools pngcrush schedtool dpkg-dev liblz4-tool \
make optipng maven libssl-dev pwgen libswitch-perl policycoreutils minicom
```

```bash
sudo apt-get install -y libxml-sax-base-perl libxml-simple-perl bc libc6-dev-i386 \
xorg-dev libx11-dev lib32z1-dev libgl1-mesa-dev xsltproc unzip
```

---

## Additional Development Tools

```bash
sudo apt-get install -y fontconfig rsync openssl clang cmake ninja-build \
libncurses-dev lib32stdc++6 libelf-dev
```

---

## Fix for libncurses5 (Required for AOSP Build on Ubuntu 24.04.3)

Ubuntu 24.04.3 no longer includes `libncurses5` by default. Create symlinks to use `libncurses6`:

```bash
sudo ln -sf /usr/lib/x86_64-linux-gnu/libncurses.so.6 /usr/lib/x86_64-linux-gnu/libncurses.so.5
```

```bash
sudo ln -sf /usr/lib/x86_64-linux-gnu/libtinfo.so.6 /usr/lib/x86_64-linux-gnu/libtinfo.so.5
```

For 32-bit libraries:

```bash
sudo ln -sf /usr/lib32/libncurses.so.6 /usr/lib32/libncurses.so.5
```

```bash
sudo ln -sf /usr/lib32/libtinfo.so.6 /usr/lib32/libtinfo.so.5
```

---

## Setup Android SDK Platform Tools

> Edit bashrc and add these lines, then save with `Ctrl+O` & `Ctrl+X`  
> This will make Android SDK & git-repo system-wide

```bash
nano ~/.bashrc
```

Add the following lines at the end:

```bash
# AOSP Build Configuration
export USE_CCACHE=1
ccache -M 150G
PATH="${HOME}/.bin:${PATH}"

# Android SDK Configuration
export ANDROID_HOME=${HOME}/Android/Sdk
export PATH=${PATH}:${ANDROID_HOME}/platform-tools
export PATH=${PATH}:${ANDROID_HOME}/cmdline-tools/latest/bin:${ANDROID_HOME}/build-tools/34.0.0
```

After editing, reload the configuration:

```bash
source ~/.bashrc
```

---

## Add Latest git-repo

```bash
mkdir -p ~/.bin
```

```bash
PATH="${HOME}/.bin:${PATH}"
```

```bash
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/.bin/repo
```

```bash
chmod a+rx ~/.bin/repo
```

---

## Git Configuration for AOSP

Configure Git with your details:

```bash
git config --global user.name "Your Name"
```

```bash
git config --global user.email "youremail@example.com"
```

---

## Flatpak Installation (Optional)

> Reboot required after installation

```bash
sudo apt install -y flatpak plasma-discover-backend-flatpak
```

```bash
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
```

> Now install Android Studio via Flatpak (reboot first if you haven't)

---

## Telegram Installation via PPA

> Flatpak or Snap doesn't work properly sometimes

```bash
sudo add-apt-repository ppa:atareao/telegram -y
```

```bash
sudo apt-get update
```

```bash
sudo apt-get install -y telegram
```

---

## Installing `.deb` Packages

```bash
sudo dpkg -i /path/to/package.deb
```

If dependencies are missing:

```bash
sudo apt-get install -f
```

---

## Removing Installed Applications

**Remove app only (keeps app data):**

```bash
sudo apt-get remove google-chrome-stable
```

**Remove app & app data:**

```bash
sudo apt --purge remove google-chrome-stable
```

---

## Create a New Folder in Root Directory

```bash
sudo mkdir -m 775 FolderName
```

```bash
sudo chown -R username:group FolderName
```

Replace `username` and `group` with your actual username and group (usually the same as username).

---

## Create Python Virtual Environment

> Make sure venv is installed:

```bash
sudo apt install -y python3-venv
```

> Create a new virtual environment in a directory named `.venv`:

```bash
python3 -m venv .venv
```

> Activate the virtual environment:

```bash
source .venv/bin/activate
```

> Install packages in the virtual environment:

```bash
pip install requests
```

> Deactivate the virtual environment:

```bash
deactivate
```

---

## AOSP Build Helper Commands

### Reorder Proprietary Libraries

This rearranges files in proprietary-files:

```bash
python3 reorder-libs.py
```

### Find Duplicates in proprietary-files.txt

```bash
sort proprietary-files.txt | uniq -cd | sort -nr
```

---

## Grep Commands for AOSP

### Search for a file recursively

Navigate to the directory where you want to search and use:

```bash
grep -r "filename"
```

### Find and Replace One Word from Multiple Directories

Example: Replace `EXPORT_SYMBOL` with `EXPORT_SYMBOL_GPL`:

```bash
grep -rli 'EXPORT_SYMBOL' | xargs sed -i 's/EXPORT_SYMBOL(/EXPORT_SYMBOL_GPL(/g'
```

---

## Fix SELinux Denials

### Download SELinux Denial Fixer Tools

**Option 1:** [Dexer125/SELinux-Denials-Tool](https://github.com/Dexer125/SELinux-Denials-Tool/releases)

```bash
java -jar SELinuxDenialsTool.jar
```

**Option 2:** [DarkJoker360/selinux-denial-fixer](https://github.com/DarkJoker360/selinux-denial-fixer.git)

```bash
python3 denials.py
```

---

## Additional AOSP Build Tips

### Clean Build

```bash
make clean
```

### Build with specific number of threads

```bash
make -j$(nproc)
```

### Build specific module

```bash
make module_name
```

### Check build environment

```bash
source build/envsetup.sh
lunch
```

---

## Package Changes from Ubuntu 23.10 to 24.04.3 LTS

### Deprecated Packages (DO NOT USE)

- ❌ `libncurses5` → ✅ Use `libncurses6` with symlinks
- ❌ `libncurses5-dev` → ✅ Use `libncurses-dev`
- ❌ `x11proto-core-dev` → ✅ Use `xorg-dev`
- ❌ `libsdl1.2-dev` → ✅ Use `libsdl2-dev`
- ❌ `libtinfo5` → ✅ Use `libtinfo6` with symlinks

### Why These Changes?

Ubuntu 24.04.3 LTS has moved to newer library versions and removed legacy packages to improve security and maintainability. The symlink solution for `libncurses5` ensures backward compatibility with AOSP build tools that still reference the older library versions.

---

## Verify Installation

Check if all critical packages are installed:

```bash
dpkg -l | grep -E "build-essential|ccache|git|python3|flex|bison"
```

Check repo version:

```bash
repo --version
```

---

## System Requirements for AOSP Build

- **RAM:** Minimum 16GB (32GB recommended)
- **Storage:** Minimum 400GB free space (SSD recommended)
- **CPU:** 64-bit multi-core processor (8+ cores recommended)
- **OS:** Kubuntu 24.04.3 LTS / Ubuntu 24.04.3 LTS

---

## Notes

- All commands have been tested and verified for Ubuntu 24.04.3 LTS compatibility
- Replace deprecated packages with their modern equivalents
- Use symlinks for backward compatibility where necessary
- Always run `sudo apt-get update` before installing new packages
- ccache significantly speeds up rebuilds - adjust size based on your storage

---

## Troubleshooting Common Issues

### Issue: "Unable to locate package"

**Solution:**

```bash
sudo apt-get update --fix-missing
sudo apt-get install -f
```

### Issue: "libncurses.so.5: cannot open shared object file"

**Solution:** Create symlinks as mentioned in the "Fix for libncurses5" section above.

### Issue: Build fails with "No space left on device"

**Solution:** Check available space:

```bash
df -h
```

Clear ccache if needed:

```bash
ccache -C
```

### Issue: Permission denied errors

**Solution:** Ensure proper ownership:

```bash
sudo chown -R $USER:$USER ~/path/to/aosp
```

---

## References

- [AOSP Official Documentation](https://source.android.com/docs/setup)
- [Ubuntu 24.04.3 LTS Release Notes](https://discourse.ubuntu.com/t/ubuntu-24-04-lts-noble-numbat-release-notes/39890)
- [Git-Repo Documentation](https://gerrit.googlesource.com/git-repo/)

---

> **Made for:** Kubuntu 24.04.3 LTS / Ubuntu 24.04.3 LTS  
> **Purpose:** AOSP Custom ROM Build Environment Setup  
> **Last Updated:** November 2025

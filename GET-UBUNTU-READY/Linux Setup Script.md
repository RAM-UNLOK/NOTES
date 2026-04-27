# AOSP Build Environment – Ubuntu / Kubuntu 26.04 LTS

**All-in-one installer by Omkar Parte · [Digimend Labs](https://digimendlabs.in)**  
Automates the full setup of an AOSP build environment on Ubuntu / Kubuntu 26.04 LTS, including build dependencies, Apktool, Android udev rules, KVM, Flatpak apps, git-repo, and SDK paths.

---

## Requirements

| Item | Minimum |
|------|---------|
| OS | Ubuntu 26.04 LTS / Kubuntu 26.04 LTS |
| RAM | 16 GB (32 GB recommended for AOSP builds) |
| Disk | 300 GB free (AOSP source + build output) |
| CPU | Any x86_64 (optimised for Intel i7-12700KF / 20 threads) |
| Internet | Required (downloads ~2–3 GB) |
| Privileges | `sudo` / root |

---

## Quick Start

```bash
# 1. Clone or download the script
wget https://your-host/setup_aosp_kubuntu_2604.sh

# 2. Make executable
chmod +x setup_aosp_kubuntu_2604.sh

# 3. Run as root
sudo bash setup_aosp_kubuntu_2604.sh

# 4. Reload shell environment after the script finishes
source ~/.bashrc
```

> **Tip:** Run inside a `tmux` or `screen` session for long installs.

---

## What the Script Does (Step by Step)

| Step | Description |
|------|-------------|
| 1/9 | Optional: enable Universe & Multiverse repositories |
| 2/9 | `apt-get update && apt-get upgrade` – full system refresh |
| 3/9 | Add/verify **git-core PPA** for latest Git |
| 4/9 | Install all AOSP **build dependencies** in 11 labelled sections with wait timers |
| 5/9 | Install **KVM / libvirt** and add user to `kvm` & `libvirt` groups |
| 6/9 | Install **Flatpak** + Telegram, Google Chrome, Android Studio via Flathub |
| 7/9 | Inject **AOSP SDK/NDK PATH** block into `~/.bashrc` (stale-entry safe) |
| 8/9 | Download **Google git-repo** → `~/.bin/repo` + set Git identity |
| 9/9 | Download **51-android udev rules** from `snowdream/51-android` + reload udev |
| ✦ | Install **Apktool 3.0.2** (JAR + wrapper) into `/usr/local/bin/` |

### Dependency Install Sections (Step 4)

| Section | Packages |
|---------|----------|
| 4a – Core build tools | `bc bison build-essential ccache curl flex make schedtool zip unzip wget` |
| 4b – Git & VCS | `git git-core git-lfs` |
| 4c – Java | `default-jre default-jdk` (Java 8+ validated) |
| 4d – Compression | `bzip2 lz4 lzop liblzma-dev squashfs-tools p7zip-full rar brotli …` |
| 4e – 32-bit libs | `libc6-dev-i386 lib32ncurses-dev lib32z1-dev lib32stdc++6` |
| 4f – Image/graphics | `imagemagick libgl1-mesa-dev libsdl2-dev pngcrush optipng fontconfig` |
| 4g – SSL/XML/Network | `libssl-dev libcurl4-openssl-dev libxml2-utils nghttp2 rsync aria2` |
| 4h – Misc build tools | `fakeroot patchelf automake maven pwgen minicom …` |
| 4i – Python 3 | `python3 python3-pip python3-venv python-is-python3 python3-protobuf` |
| 4j – Clang/CMake/Ninja | `clang cmake ninja-build libncurses-dev libelf-dev` |
| 4k – Android tools | `android-sdk-libsparse-utils erofs-utils` |

---

## Setting ccache Size (100 GB)

ccache dramatically speeds up repeated AOSP builds by caching compiled objects.

### Option A – Set in `~/.bashrc` (Recommended, Persistent)

Add these lines to your `~/.bashrc` (the script already adds `USE_CCACHE` and `CCACHE_EXEC`):

```bash
# --- AOSP ENV START --- (already present, add CCACHE_SIZE below it)
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
export CCACHE_DIR="${HOME}/.ccache"   # custom cache location (optional)
export CCACHE_SIZE=100G               # 100 GB cache limit
```

Then reload:

```bash
source ~/.bashrc
```

Apply the size to the ccache database immediately:

```bash
ccache -M 100G
```

### Option B – Apply Once (Session Only)

```bash
ccache -M 100G
```

### Verify ccache Is Working

```bash
# Show current config and stats
ccache -s

# Expected output includes:
#   Cache directory   ~/.ccache
#   Max cache size    100.0 GB
```

### During AOSP Build

AOSP's build system honours `USE_CCACHE=1` automatically. To also set it inline:

```bash
export USE_CCACHE=1
export CCACHE_EXEC=/usr/bin/ccache
ccache -M 100G
source build/envsetup.sh
lunch aosp_x86_64-eng
make -j$(nproc)
```

---

## Apktool

Installed automatically by the script.

| File | Path | Permissions |
|------|------|-------------|
| JAR | `/usr/local/bin/apktool.jar` | `644 root:root` |
| Wrapper | `/usr/local/bin/apktool` | `755 root:root` |

**Sources used:**
- Wrapper: `https://raw.githubusercontent.com/iBotPeaches/Apktool/master/scripts/linux/apktool`
- JAR: `https://bitbucket.org/iBotPeaches/apktool/downloads/apktool_3.0.2.jar`

```bash
# Verify
apktool --version

# Decode an APK
apktool d app.apk -o output_dir

# Rebuild an APK
apktool b output_dir -o rebuilt.apk
```

---

## Android udev Rules

The script downloads the community-maintained `51-android.rules` from:

```
https://raw.githubusercontent.com/snowdream/51-android/refs/heads/master/51-android.rules
```

Installed to `/etc/udev/rules.d/51-android.rules` and activated immediately via:

```bash
udevadm control --reload-rules && udevadm trigger
```

This enables ADB/Fastboot access for **all major Android device vendors** without needing `sudo adb`.

---

## Post-Install Checklist

```bash
# 1. Reload environment
source ~/.bashrc

# 2. Verify tools
git --version
java -version
apktool --version
adb version
ccache --version
ccache -s          # check cache stats & size

# 3. Verify KVM (reboot or re-login first for group changes to apply)
kvm-ok

# 4. Check Android Studio (Flatpak)
flatpak list | grep AndroidStudio
```

---

## Notes

- **Group changes** (`kvm`, `libvirt`) require a **logout/login** or reboot to take effect.
- The `~/.bashrc` AOSP block is **idempotent** — re-running the script safely removes and rewrites it.
- Ubuntu 26.04 ships Python 3 by default; `python-is-python3` makes `python` point to `python3`.
- For full AOSP source sync, ensure at least **300 GB** of free disk space and run `repo init` / `repo sync` after setup.

---

## License

MIT — free to use and modify.  
Maintained by **Omkar Parte · Digimend Labs**, Mumbai, Maharashtra 🇮🇳

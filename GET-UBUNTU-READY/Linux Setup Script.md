# AOSP Build Environment Setup — Kubuntu / Ubuntu 26.04 LTS

> **Author:** Omkar Parte — Digimend Labs  
> **Script:** `setup_aosp_kubuntu.sh`  
> **Target:** Ubuntu / Kubuntu 26.04 LTS · Android 16.x / AOSP Latest  
> **Hardware:** Intel i7-12700KF (20 Threads) · AMD RX 6800 XT  

---

## What This Script Does

An all-in-one, idempotent installer that sets up a complete AOSP build environment in a single run. It handles:

| Step | Task |
|------|------|
| 1 | Optional Universe & Multiverse repository setup |
| 2 | System package update & upgrade |
| 3 | git-core PPA (latest stable Git) |
| 4 | All AOSP build dependencies (split into 11 sub-sections) |
| 5 | KVM / libvirt for Cuttlefish & Android Emulator |
| 6 | Flatpak + Telegram, Chrome, Android Studio |
| 7 | AOSP SDK/NDK `PATH` & `ccache` env vars → `~/.bashrc` |
| 8 | Google `git-repo` tool + Git identity |
| 9 | `51-android.rules` udev rules |
| ✦ | Apktool 3.0.2 (bonus) |

---

## Requirements

- **OS:** Ubuntu or Kubuntu **26.04 LTS** (noble/oracular base)
- **Arch:** x86_64 (64-bit)
- **Internet:** Active connection required (downloads ~500 MB+)
- **Privileges:** Must be run with `sudo` — **do NOT run as the root user directly**
- **Disk:** At least **30 GB** free (20 GB for ccache + AOSP source space)

---

## How to Execute

### Step 1 — Download / copy the script

If cloning from a repo:
```bash
git clone https://github.com/your-repo/aosp-setup.git
cd aosp-setup
```

Or just copy `setup_aosp_kubuntu.sh` to your home directory.

### Step 2 — Make it executable

```bash
chmod +x setup_aosp_kubuntu.sh
```

### Step 3 — Run with sudo (IMPORTANT)

```bash
sudo bash setup_aosp_kubuntu.sh
```

> ⚠️ **Always use `sudo bash`, NOT `sudo su` then bash, and NOT as the root user.**  
> The script uses `$SUDO_USER` internally to detect your actual username and home directory.  
> Running directly as root (e.g. logging in as root) will cause ccache and git-repo to be  
> installed into `/root/` instead of your user's home — which breaks the AOSP build.

### Step 4 — Reload your shell environment

After the script finishes:
```bash
source ~/.bashrc
```
Or open a new terminal tab. This loads the `ANDROID_HOME`, `CCACHE_*`, and PATH exports.

### Step 5 — Verify ccache is working

```bash
ccache -p | grep max_size
# Expected output: max_size = 100.0 GB

ccache -s
# Shows cache statistics for ~/.ccache
```

---

## Interactive Prompt

The script asks **one question** during setup:

```
Enable Universe and Multiverse repositories? [y/N]:
```

- Press **Enter** (or type `N`) to skip — safe to skip on most Kubuntu installs.
- Type `y` + Enter to enable them — required only if certain packages are missing.

All other steps run fully automatically.

---

## Log File

Every run writes a timestamped log to:

```
/var/log/aosp-setup/setup_YYYYMMDD_HHMMSS.log
```

If the script fails, the exact **line number**, **function**, and **command** that failed are printed to the terminal AND saved in the log. To inspect:

```bash
sudo cat /var/log/aosp-setup/setup_*.log | tail -50
```

---

## Environment Variables Written to `~/.bashrc`

The script appends the following block (replacing any previous version):

```bash
# --- AOSP ENV START ---
export USE_CCACHE=1
export PATH="/usr/lib/ccache:$PATH"
export CCACHE_MAXSIZE=50G

export ANDROID_HOME="${HOME}/Android/Sdk"
export ANDROID_SDK_ROOT="${HOME}/Android/Sdk"
export NDK_HOME="${ANDROID_HOME}/ndk/30.0.14904198"

export PATH="${HOME}/.bin:${PATH}"
export PATH="${ANDROID_HOME}/platform-tools:${PATH}"
export PATH="${ANDROID_HOME}/cmdline-tools/latest/bin:${PATH}"
export PATH="${ANDROID_HOME}/build-tools/37.0.0:${PATH}"
export PATH="${ANDROID_HOME}/emulator:${PATH}"
export PATH="/usr/lib/ccache:${PATH}"   # ← ccache compiler symlinks
# --- AOSP ENV END ---
```

> **Re-running the script is safe.** It detects and removes the old block before writing a fresh one.

---

## ccache Configuration Details

| Setting | Value |
|---------|-------|
| Cache directory | `~/.ccache` (owned by your user) |
| Max size | 100 GB |
| Config file | `~/.ccache/ccache.conf` |
| Binary | `/usr/bin/ccache` |
| Env var for size | `CCACHE_MAXSIZE` |

### Why `CCACHE_MAXSIZE` and not `CCACHE_SIZE`?

`CCACHE_SIZE` is **not** a recognised ccache environment variable — it is silently ignored at build time. The correct variable is `CCACHE_MAXSIZE`. The `ccache -M 100G` command also writes the limit permanently into `~/.ccache/ccache.conf`, so it persists across reboots without the env var.

---

## Post-Install Checklist

After running the script and sourcing `~/.bashrc`, verify your environment:

```bash
# 1. Git version (should be 2.x from git-core PPA)
git --version

# 2. Java version (must be ≥ 8)
java -version

# 3. ccache size config
ccache -p | grep max_size

# 4. repo tool
repo --version

# 5. Android Debug Bridge (after Android Studio SDK install)
adb --version

# 6. KVM access (should show your username)
groups | grep kvm

# 7. Apktool
apktool --version
```

---

## Troubleshooting

### Script exits immediately with no error shown
Make sure you ran with `sudo bash`, not just `bash`. The script requires root for apt/udev.

### `ccache: No such file or directory`
The PATH reload hasn't happened yet. Run `source ~/.bashrc` or open a new terminal.

### `SUDO_USER is empty` warning
Do not run the script by first doing `sudo su` and then calling bash. Always run as:
```bash
sudo bash setup_aosp_kubuntu.sh
```

### Flatpak install fails (Android Studio / Chrome)
These apps require the Flathub remote. The script adds it automatically, but if your system clock is wrong or DNS fails, re-run just the Flatpak step manually:
```bash
sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
sudo flatpak install flathub com.google.AndroidStudio
```

### `udevadm trigger` fails on a headless/WSL system
This is non-fatal. The `51-android.rules` file is installed correctly — a reboot will activate it.

### Apktool JAR download fails
The JAR is hosted on Bitbucket. If the download fails, manually download from:  
`https://bitbucket.org/iBotPeaches/apktool/downloads/`  
and place it at `/usr/local/bin/apktool.jar` with `chmod 644`.

---

## NDK Path Note

The script sets `NDK_HOME` to:
```
~/Android/Sdk/ndk/30.0.14904198
```
This NDK version must be downloaded via **Android Studio → SDK Manager → NDK (Side by side)**.  
The script itself does not download the NDK or Android SDK — those are managed by Android Studio.

---

## Re-running / Idempotency

The script is **safe to re-run**. Key idempotent behaviours:

- `apt-get install -y` skips already-installed packages
- Old `# --- AOSP ENV START --- … END ---` block in `.bashrc` is removed and replaced
- `repo` binary is deleted and re-downloaded fresh each run
- Apktool JAR and wrapper are overwritten
- `dpkg --add-architecture i386` uses `|| true` — safe if already added

---

## File Locations Summary

| Item | Path |
|------|------|
| Script log | `/var/log/aosp-setup/setup_YYYYMMDD_HHMMSS.log` |
| ccache data | `~/.ccache/` |
| ccache config | `~/.ccache/ccache.conf` |
| git-repo tool | `~/.bin/repo` |
| udev rules | `/etc/udev/rules.d/51-android.rules` |
| Apktool JAR | `/usr/local/bin/apktool.jar` |
| Apktool wrapper | `/usr/local/bin/apktool` |
| Android SDK | `~/Android/Sdk/` *(managed by Android Studio)* |
| Env vars | `~/.bashrc` (AOSP ENV block) |

---

*Maintained by Omkar Parte — Digimend Labs*

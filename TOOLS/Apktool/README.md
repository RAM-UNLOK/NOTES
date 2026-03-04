# Apktool Overlay Decoder — Setup & Usage

Scripts to install Apktool on Ubuntu and batch-decode Android overlay APKs using frameworks.

---

## Files

| File | Purpose |
|------|---------|
| `install_apktool.sh` | Installs Java (default JRE) + latest Apktool system-wide |
| `decode_overlays.sh` | Installs frameworks and decodes all overlay APKs |

---

## Prerequisites

- Ubuntu (any modern LTS — 20.04, 22.04, 24.04)
- Internet connection (for install script)
- `sudo` access

---

## Step 1 — Install Apktool

```bash
chmod +x install_apktool.sh
sudo ./install_apktool.sh
```

### What it does

1. Checks if Java is installed — installs `default-jre` via `apt` if not
2. Validates Java is version 8 or higher (required by Apktool)
3. Fetches the latest Apktool release version from GitHub API
4. Downloads the JAR from the official Bitbucket page
5. Installs a wrapper script so you can call `apktool` from anywhere
6. Verifies the installation with `apktool --version`

### Installed files & permissions

| Path | Permission | Why |
|------|-----------|-----|
| `/usr/local/bin/apktool.jar` | `644` (`rw-r--r--`) `root:root` | JAR is a data file — only root should modify it, all users need to read it |
| `/usr/local/bin/apktool` | `755` (`rwxr-xr-x`) `root:root` | Wrapper must be executable by all users, only root can modify |

> **Note:** Java JARs don't need the executable bit (`+x`) set — the JVM reads them as data.

---

## Step 2 — Prepare Your Folder Structure

Before running the decode script, your `overlaytodecode/` folder must look like this:

```
overlaytodecode/
├── framework-res.apk          ← required
├── framework-ext-res.apk      ← recommended
├── framework.jar              ← ignored (code-only, no resources)
├── product/
│   └── overlay/
│       ├── SomeOverlay.apk
│       └── AnotherOverlay.apk
└── vendor/
    └── overlay/
        ├── VendorOverlay.apk
        └── OtherOverlay.apk
```

> **Why is `framework.jar` ignored?**  
> It's a DEX bytecode library with no `resources.arsc` file inside.  
> Apktool's `if` (install-framework) command only works on APKs that contain resources.  
> Only `framework-res.apk` and `framework-ext-res.apk` need to be installed.

---

## Step 3 — Run the Decode Script

```bash
chmod +x decode_overlays.sh

# If run from the same folder as overlaytodecode/:
./decode_overlays.sh

# Or pass the path explicitly:
./decode_overlays.sh /path/to/overlaytodecode
```

> The decode script does **not** require `sudo` — it only reads/writes within your own folder.

### What it does

1. **Installs frameworks** — runs `apktool if` on `framework-res.apk` then `framework-ext-res.apk`, storing them in `overlaytodecode/frameworks/` using `-p` to keep them isolated from your system's default apktool cache
2. **Decodes product overlays** — loops through every `.apk` in `product/overlay/` and decodes each one
3. **Decodes vendor overlays** — same for `vendor/overlay/`
4. **Names output folders** after the APK filename — e.g. `SomeOverlay.apk` → `decoded/product/SomeOverlay/`
5. **Prints a summary** of decoded / skipped / failed counts

### Output structure

```
overlaytodecode/
├── frameworks/
│   ├── 1.apk       ← installed from framework-res.apk
│   └── 17.apk      ← installed from framework-ext-res.apk
└── decoded/
    ├── product/
    │   ├── SomeOverlay/
    │   └── AnotherOverlay/
    └── vendor/
        ├── VendorOverlay/
        └── OtherOverlay/
```

Each decoded folder contains the standard Apktool output:

```
SomeOverlay/
├── AndroidManifest.xml
├── apktool.yml
└── res/
    ├── values/
    │   └── strings.xml
    └── ...
```

---

## Re-decoding an APK

The script **skips** APKs that already have a decoded output folder.  
To force a re-decode, delete the folder first:

```bash
rm -rf overlaytodecode/decoded/product/SomeOverlay
./decode_overlays.sh
```

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `apktool not found` | Apktool not installed | Run `install_apktool.sh` first |
| `Could not find resources.arsc` | Trying to install a code-only JAR as a framework | Expected — `framework.jar` is skipped automatically |
| `brut.androlib.exceptions.AndrolibException` during decode | Wrong or missing framework | Make sure both `framework-res.apk` and `framework-ext-res.apk` are present in the root folder |
| `java: command not found` | Java not installed | Run `sudo apt install default-jre` |
| Decoded folder is empty / missing `res/` | APK has no resources (rare for overlays) | Check the APK — it may only contain a manifest |

---

## Quick Reference

```bash
# Full workflow from scratch
sudo ./install_apktool.sh
./decode_overlays.sh /home/omkar/overlaytodecode
```

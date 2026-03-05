# APK Zipalign + Sign Tool

Fixes APK alignment issues and signs the APK with your own key or an auto-generated one.

---

## Requirements

Make sure these are installed and in your `PATH`:

| Tool | How to get it |
|---|---|
| `zipalign` | Android SDK Build-Tools |
| `apksigner` | Android SDK Build-Tools |
| `keytool` | JDK (Java Development Kit) |
| `zip` | Pre-installed on most Linux distros |

**Quick install on Ubuntu/Debian:**
```bash
sudo apt install google-android-build-tools-installer default-jdk zip
```
Or manually add your Android SDK `build-tools/<version>/` folder to `PATH`.

---

## Setup

```bash
chmod +x apk_sign.sh
```

---

## Usage

### Option 1 — Auto-generate a key
```bash
./apk_sign.sh MyApp.apk --auto-key
```
Generates a keystore saved as `auto_generated_key.jks`. Reused automatically on future runs.

### Option 2 — Use your own JKS keystore
```bash
./apk_sign.sh MyApp.apk --ks release.jks --ks-pass mypassword --key-alias mykey
```

### Option 3 — Custom output filename
```bash
./apk_sign.sh MyApp.apk --auto-key --out MyApp_release.apk
```

---

## All Options

| Flag | Description |
|---|---|
| `--ks <file>` | Path to your JKS keystore |
| `--ks-pass <pass>` | Keystore password |
| `--key-alias <alias>` | Key alias inside the keystore |
| `--key-pass <pass>` | Key password (defaults to `--ks-pass`) |
| `--auto-key` | Auto-generate a new keystore |
| `--out <file>` | Output APK filename |
| `--skip-align` | Skip zipalign, only sign |

---

## ⚠️ Important

Always sign future updates of the same app with the **same keystore**. If you lose the keystore, Android will reject your updates.

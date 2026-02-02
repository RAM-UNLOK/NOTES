<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# i have apktool installed provide simple and advanced commands to decode and compile framework, overlays, ims camera etc. also which java tool to use to decode java library

Here's a comprehensive section on APKTool and Java decompilation tools to add to your markdown:

***

## 🛠️ APKTool - Decode \& Compile APKs

> **Purpose:** Reverse engineer and rebuild Android APK files including framework, overlays, system apps, and custom modifications.

### Basic APKTool Commands

**Decode a standard APK:**

```bash
apktool d app.apk
```

Decodes APK to a folder with readable resources and smali code.[^1][^2]

**Decode to a specific output directory:**

```bash
apktool d app.apk -o output_folder
```

Extracts decoded files to a custom folder name.[^3][^1]

**Decode without resources (only smali source):**

```bash
apktool d app.apk -r
```

Skips resource decoding, faster when you only need code analysis.[^1][^3]

**Decode without sources (only resources):**

```bash
apktool d app.apk -s
```

Skips smali code extraction, useful for theme/overlay development.[^3][^1]

**Decode with framework resources installed:**

```bash
apktool d app.apk -f
```

Forces fresh decode even if target folder exists.[^1]

**Match original mode (no changes to resources):**

```bash
apktool d app.apk -m
```

Minimal disassembly for quick inspection without full rebuild capability.[^4]

**Build/recompile decoded APK:**

```bash
apktool b decoded_folder
```

Recompiles the decoded folder back to an APK in the `dist` subfolder.[^3][^1]

**Build to specific output APK:**

```bash
apktool b decoded_folder -o modified_app.apk
```

Generates APK with custom filename.[^1]

**Force rebuild (clean build):**

```bash
apktool b decoded_folder -f
```

Deletes previous build files and performs clean compilation.[^1]

### Framework Installation \& Management

**Install framework resources (required for system apps):**

```bash
apktool if framework-res.apk
```

Installs the base framework for decoding system applications that depend on framework resources.[^5][^1]

**Install framework with custom tag:**

```bash
apktool if framework-res.apk -t samsung
```

Tags framework for device-specific builds (useful when working with multiple OEM frameworks).[^3][^1]

**Install multiple frameworks (for OEM customizations):**

```bash
apktool if framework-res.apk
apktool if SystemUI-res.apk
apktool if com.android.systemui.apk
```

Required when system apps depend on multiple framework resources.[^1]

**Specify custom framework directory:**

```bash
apktool d SystemUI.apk -p ~/frameworks/
```

Uses frameworks from a specific directory instead of default location.[^3][^1]

**Use tagged framework when decoding:**

```bash
apktool d app.apk -t samsung
```

Decodes using previously tagged framework resources.[^3][^1]

### Advanced Decoding Options

**Decode with specific API level:**

```bash
apktool d app.apk --api 33
```

Forces smali baksmaling against specific Android API level.[^1]

**Keep broken resources during decode:**

```bash
apktool d app.apk --keep-broken-res
```

Retains resources that cannot be properly decoded (keep mode).[^1]

**Remove broken resources during decode:**

```bash
apktool d app.apk --force-manifest
```

Removes problematic resources that cause decode failures (default behavior).[^1]

**Decode only main dex classes:**

```bash
apktool d app.apk --only-main-classes
```

Ignores classes in secondary/multi-dex files, faster for large apps.[^1]

**Prevent asset file decoding:**

```bash
apktool d app.apk --no-assets
```

Skips copying unknown asset files during decode.[^1]

**Force decode of obfuscated resources:**

```bash
apktool d app.apk --force-all
```

Attempts aggressive decoding even with obfuscated/protected resources.

### System Apps \& Overlays

**Decode framework-res.apk (core Android framework):**

```bash
apktool if framework-res.apk
apktool d framework-res.apk
```

First install framework, then decode it for modifying system resources.[^6][^5]

**Decode SystemUI.apk (status bar, notifications):**

```bash
apktool if framework-res.apk
apktool d SystemUI.apk
```

Requires framework installation first as SystemUI depends on framework resources.[^1]

**Decode overlay APKs (theme/resource overlays):**

```bash
apktool d overlay.apk
```

Overlays typically only contain resources, no code.[^7][^6]

**Build overlay with specific target package:**

```bash
apktool b overlay_folder
```

Overlays must maintain correct package names and resource IDs to properly overlay target app.[^6]

**Decode Camera app:**

```bash
apktool if framework-res.apk
apktool d Camera.apk
```

Camera apps often require framework resources for proper decoding.[^1]

**Decode IMS (IP Multimedia Subsystem) apps:**

```bash
apktool if framework-res.apk
apktool if telephony-common.apk
apktool d ims.apk
```

IMS/telephony apps may require telephony framework resources.[^1]

### Building with Custom Options

**Build with specific aapt version:**

```bash
apktool b decoded_folder -a /path/to/aapt2
```

Uses custom aapt/aapt2 binary for building (useful for specific Android SDK versions).[^1]

**Build with specific API level:**

```bash
apktool b decoded_folder --api 33
```

Compiles smali against specific API level.[^1]

**Copy original files during build:**

```bash
apktool b decoded_folder -c
```

Preserves original files from the APK in the rebuild.[^1]

**Use aapt2 for building:**

```bash
apktool b decoded_folder --use-aapt2
```

Forces use of aapt2 instead of legacy aapt for resource compilation.[^1]

### Debugging \& Troubleshooting

**Verbose output during decode/build:**

```bash
apktool d app.apk -v
```

Shows detailed processing information for troubleshooting.[^1]

**Decode in debug mode:**

```bash
apktool d app.apk -d
```

Adds debugging information to smali files.[^6][^1]

**Build in debug mode:**

```bash
apktool b decoded_folder -d
```

Creates debuggable APK with debug symbols.[^1]

**Check APKTool version:**

```bash
apktool --version
```

Displays installed APKTool version.

***

## ☕ Java Decompilation Tools

> **Purpose:** Convert compiled Android bytecode (DEX/JAR) back to readable Java source code for analysis and understanding app logic.

### JADX (Recommended - Best for Android)

**Why JADX:** Directly converts DEX to Java without intermediate steps, specialized for Android, preserves more DEX-specific features, includes GUI, can export as Android Studio project.[^8][^9]

**Install JADX:**

Download from: https://github.com/skylot/jadx/releases

**Decompile APK using JADX CLI:**

```bash
jadx app.apk
```

Decompiles entire APK to Java source code in a folder.[^9]

**Decompile to specific output directory:**

```bash
jadx app.apk -d output_folder
```

Extracts Java source to custom folder.[^9]

**Decompile only specific classes:**

```bash
jadx app.apk --show-bad-code
```

Shows classes even if decompilation has issues.[^9]

**Export as Gradle project for Android Studio:**

```bash
jadx app.apk --export-gradle
```

Creates complete Android Studio project structure for advanced refactoring and analysis.[^8][^9]

**Launch JADX GUI:**

```bash
jadx-gui
```

Opens graphical interface for browsing and searching decompiled code with syntax highlighting.[^9]

**Decompile DEX file directly:**

```bash
jadx classes.dex
```

Works with extracted DEX files from APKs.[^9]

**Decompile with threading options (faster):**

```bash
jadx app.apk -j 8
```

Uses 8 threads for parallel decompilation (adjust based on CPU cores).[^9]

**Skip resources during decompilation:**

```bash
jadx app.apk --no-res
```

Faster decompilation when you only need code, not resources.[^9]

**Decompile with comments and debug info:**

```bash
jadx app.apk --comments-level info
```

Adds helpful comments about decompilation assumptions.[^9]

### dex2jar + JD-GUI (Alternative Method)

**Why dex2jar + JD-GUI:** Established tools, good for cross-verification, JD-GUI is lightweight, works well for simpler apps.[^9]

**Convert DEX to JAR using dex2jar:**

```bash
d2j-dex2jar app.apk
```

Converts APK/DEX to JAR file for viewing in Java decompilers.[^9]

**Convert with specific output name:**

```bash
d2j-dex2jar app.apk -o output.jar
```

Creates JAR with custom filename.[^9]

**Force overwrite existing JAR:**

```bash
d2j-dex2jar app.apk -f
```

Overwrites output if file exists.[^9]

**View JAR in JD-GUI:**

```bash
jd-gui output.jar
```

Opens decompiled Java source in JD-GUI viewer (GUI tool).[^9]

**Save all source files from JD-GUI:**

```
File → Save All Sources
```

Exports entire decompiled source tree to a zip file from JD-GUI interface.[^9]

### Other Decompilation Tools

**Fernflower (IntelliJ decompiler):**

```bash
java -jar fernflower.jar app.apk output_folder
```

IntelliJ IDEA's built-in decompiler, good accuracy for standard Java patterns.

**Procyon:**

```bash
procyon-decompiler -jar app.jar -o output_folder
```

Modern decompiler with good Java 8+ feature support.

**CFR:**

```bash
java -jar cfr.jar app.jar --outputdir output_folder
```

Fast decompiler with excellent lambda and modern Java support.

### Decompilation Workflow for Android

**Complete analysis workflow:**

```bash
# Step 1: Decode resources with APKTool
apktool d app.apk -o decoded_apk

# Step 2: Decompile code with JADX
jadx app.apk -d decompiled_java

# Now you have:
# - decoded_apk/ → Smali code + decoded resources (for rebuilding)
# - decompiled_java/ → Readable Java source (for understanding logic)
```

**For system apps requiring framework:**

```bash
# Step 1: Install framework
apktool if framework-res.apk

# Step 2: Decode system app
apktool d SystemUI.apk -o decoded_systemui

# Step 3: Decompile to Java for easier reading
jadx SystemUI.apk -d systemui_java
```


### Tool Comparison Summary

| Tool | Best For | Output | Android Optimized | GUI |
| :-- | :-- | :-- | :-- | :-- |
| **JADX** | DEX → Java directly | Java source | ✅ Yes | ✅ Yes |
| **dex2jar + JD-GUI** | Legacy/verification | Java source | ⚠️ Via conversion | ✅ Yes (JD-GUI) |
| **APKTool** | Resource editing, rebuilding | Smali + Resources | ✅ Yes | ❌ No |
| **Fernflower** | Modern Java features | Java source | ⚠️ Generic | ❌ No |
| **CFR** | Lambda/Java 8+ | Java source | ⚠️ Generic | ❌ No |


***

## 📝 Notes on Decompilation

- **Obfuscation:** Apps using ProGuard/R8 will have obfuscated code (meaningless variable/method names). Decompiled source will be harder to read but still executable logic.[^9]
- **Recompilation:** Java source from JADX/JD-GUI is for **reading only**—it won't recompile perfectly due to DEX→Java conversion losses. Use APKTool's smali for modifications.[^9]
- **Framework dependencies:** System apps (Camera, IMS, SystemUI) require framework-res.apk to be installed in APKTool before decoding.[^5][^1]
- **Overlays:** Overlay APKs only contain resources, no code. They work by replacing resources in target apps at runtime.[^6]
- **Legal:** Only decompile apps you own or have permission to analyze. Respect intellectual property and license terms.[^10]

***

Would you like me to merge this into the complete markdown file with all the previous sections?
<span style="display:none">[^11]</span>

<div align="center">⁂</div>

[^1]: https://apktool.org/docs/cli-parameters/

[^2]: https://apktool.org/wiki/the-basics/intro/

[^3]: https://www.kali.org/tools/apktool/

[^4]: https://apktool.org

[^5]: https://pankajchunchun.wordpress.com/2012/07/27/129/

[^6]: https://mmmyddd.github.io/wiki/android/overlay.html

[^7]: https://www.reddit.com/r/Substratum/comments/eqzymd/how_can_i_decompile_an_apk_show_a_preview_of_it/

[^8]: https://news.ycombinator.com/item?id=21924761

[^9]: https://stackoverflow.com/questions/1249973/how-to-decompile-dex-into-java-source-code

[^10]: https://www.corellium.com/blog/android-mobile-reverse-engineering

[^11]: Simple-Commands.md


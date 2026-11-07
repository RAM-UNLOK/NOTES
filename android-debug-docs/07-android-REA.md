# The Full-Stack Guide to Reverse Engineering Android `.so` Files and Service Blobs

Reverse engineering Android native libraries and the services that use them is a deep discipline that combines binary analysis, IPC protocol reconstruction, and build-system integration. This guide covers the complete workflow, from extracting blobs out of a firmware dump to rebuilding AIDL interfaces, and then shows how to accelerate the entire process using **REA (Reverse Engineer Anything)** driven by a local AI model such as `mradermacher/gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic-GGUF`.

> **Legal and ethical note:** Use these techniques only on software you own or are explicitly authorized to examine. REA’s own disclaimer emphasizes lawful research, education, interoperability, and analysis of software you are authorized to inspect. Commercial tools like IDA Pro, Hopper, and JEB require valid licenses.

---

## Part 1 — Acquiring and Unpacking an Android Dump

Before you can reverse a `.so`, you need to get it out of the device or firmware image.

### 1.1 Pulling from a live device

If the device is rooted or you have a debuggable build, use ADB to pull the relevant APKs and native libraries.

```bash
# List packages and their APK paths
adb shell pm list packages -f | grep <package_name>

# Pull the base and split APKs
adb pull /data/app/~~.../base.apk
adb pull /data/app/~~.../split_config.arm64_v8a.apk

# Extract native libraries
unzip base.apk 'lib/*/lib*.so' -d extracted/
```

Native libraries are typically stored under `lib/arm64-v8a/`, `lib/armeabi-v7a/`, or `lib/x86_64/` inside the APK. If the app uses uncompressed native libraries, you can also find them on the device under `/data/app/.../lib/arm64/`.

### 1.2 Extracting from an OTA `payload.bin` or `super.img`

Factory images and OTA packages contain a `payload.bin` that holds partition images (`boot`, `system`, `vendor`, `product`, etc.). Extract the `vendor` partition to get vendor-specific `.so` blobs and service binaries.

**Option A — `payload-dumper-go` (recommended for speed):**
```bash
# Download from https://github.com/ssut/payload-dumper-go
payload-dumper-go -o output_dir payload.bin
```

**Option B — `image_anarchy` (Python, supports `super.img`):**
```bash
python image_anarchy.py --extract payload.bin -i vendor -o output_dir
# Or extract from a super partition image
python image_anarchy.py --image super.img
```

Once you have `vendor.img`, mount or extract it. On Linux, you can use `simg2img` (for sparse images) followed by a loop mount, or use `ext4` extraction tools. The vendor `.so` files are usually under `/vendor/lib64/` and `/vendor/bin/` for service executables.

### 1.3 Identifying the target architecture

Android devices are overwhelmingly ARM64 (AArch64). Check the ELF header to confirm:

```bash
file vendor/lib64/libbluetooth_audio_session_aidl_mtk.so
# ELF 64-bit LSB shared object, ARM aarch64, version 1 (SYSV), dynamically linked, ...

llvm-readelf -h vendor/lib64/libbluetooth_audio_session_aidl_mtk.so | grep Machine
# Machine: AArch64
```

---

## Part 2 — Manual Native Reverse Engineering

This is the core manual workflow. The example you provided for the MediaTek MIHC AIDL library is an excellent case study.

### 2.1 Static triage with LLVM tools

The Android NDK ships `llvm-readelf`, `llvm-objdump`, and `llvm-nm`. These are often more convenient than their GNU counterparts when working with Android binaries.

**Step 1 — Dump the `.rodata` section to find strings, descriptors, and RTTI names.**

```bash
llvm-readelf -p .rodata libbluetooth_audio_session_aidl_mtk.so
```

In your MIHC example, this revealed the canonical package names:
```
vendor.mediatek.hardware.bluetooth.audio.MihcCapabilities
vendor.mediatek.hardware.bluetooth.audio.MihcConfiguration
```

This immediately tells you the AIDL package and the names of the parcelables. It is often the fastest way to recover AIDL interface names from a stripped binary.

**Step 2 — Inspect dynamic symbols and demangle C++ names.**

```bash
llvm-readelf --dyn-syms libbluetooth_audio_session_aidl_mtk.so | grep -i mihc
```

If the library is not fully stripped, you will see Itanium ABI mangled names like:
```
_ZN4aidl6vendor8mediatek8hardware9bluetooth5audio17MihcConfiguration14readFromParcelEPK7AParcel
```

Use `llvm-cxxfilt` to demangle:
```bash
llvm-cxxfilt _ZN4aidl6vendor8mediatek8hardware9bluetooth5audio17MihcConfiguration14readFromParcelEPK7AParcel
# aidl::vendor::mediatek::hardware::bluetooth::audio::MihcConfiguration::readFromParcel(AParcel const*)
```

This confirms the namespace and the exact function signature. AIDL NDK-generated parcelables always implement `readFromParcel(const AParcel*)` and `writeToParcel(AParcel*)`.

**Step 3 — Check for JNI entry points (if the library also has a Java/Kotlin component).**

```bash
llvm-readelf --dyn-syms libfoo.so | grep -E 'JNI_OnLoad|Java_'
```

If the library uses `RegisterNatives` instead of name-based JNI exports, you will need to disassemble `JNI_OnLoad` to find the `JNINativeMethod` array and the function pointers.

### 2.2 Disassembling the serialization logic

In the AIDL NDK, `readFromParcel` and `writeToParcel` are highly predictable. They call a small set of `libbinder_ndk` functions. Disassembling these functions is the key to recovering the parcelable’s field layout.

```bash
llvm-objdump -d --no-show-raw-insn \
  --disassemble-symbols=_ZN4aidl6vendor8mediatek8hardware9bluetooth5audio17MihcConfiguration14readFromParcelEPK7AParcel \
  libbluetooth_audio_session_aidl_mtk.so
```

In your MIHC example, the disassembly showed:

```asm
bl  0x29e40 <AParcel_readInt32@plt>   ; sampleRateHz
bl  0x29e40 <AParcel_readInt32@plt>   ; ChannelMode enum
bl  0x29ec0 <AParcel_readByte@plt>    ; 1st byte
bl  0x29ec0 <AParcel_readByte@plt>    ; 2nd byte
...                                    ; 8 consecutive bytes in total
```

By mapping the sequence of `AParcel_read*` calls to the known AIDL NDK primitives, you can reconstruct the field order:

| Call sequence | Inferred field |
|---|---|
| `AParcel_readInt32` | `int sampleRateHz` |
| `AParcel_readInt32` | `ChannelMode channelMode` (enum, serialized as int32) |
| 8 × `AParcel_readByte` | `bitsPerSample`, `codecVersion`, `qualityIndex`, `maxQualityIndex`, `minQualityIndex`, `frameDuration`, `dataInterval`, `flags` (all `byte`) |

For `MihcCapabilities`, the read routine uses parallel arrays (`AParcel_readInt32Array`, `AParcel_readByteArray`, etc.), which correspond to `int[]`, `ChannelMode[]`, and `byte[]` in AIDL.

**Key insight:** AIDL NDK serialization is deterministic. The order of `AParcel_read*` calls exactly matches the order of fields in the `.aidl` file. You do not need to guess offsets; you just need to map the read calls to types.

### 2.3 Loading into a decompiler

While `llvm-objdump` is sufficient for small serialization functions, complex service logic benefits from a full decompiler. Ghidra is free and supports AArch64 well; IDA Pro and Hopper are commercial alternatives.

**Ghidra workflow:**
1.  Import the `.so`.
2.  Accept the default AArch64 language specification.
3.  Run auto-analysis.
4.  Navigate to `readFromParcel` / `writeToParcel` (or `JNI_OnLoad` if analyzing JNI).
5.  Use the decompiler to recover C-like pseudocode.

**Hopper workflow (macOS):**
REA can launch Hopper programmatically, but for manual analysis you can open the binary directly and use the “Decrypt” / “Decompile” features.

### 2.4 Recovering the AIDL interface (`CodecSpecific` union tag)

In AIDL, codecs are often grouped into a union (e.g., `CodecSpecific`). The compiled binary implements a `switch` on a numeric tag. By disassembling the `writeToParcel` or `readFromParcel` of the union, you can find the tag that Xiaomi assigned to MIHC.

Look for a comparison against a constant before branching to the `MihcConfiguration` read/write logic. That constant is the union tag. In your example, this allowed you to add `MihcConfiguration` to `CodecConfiguration.aidl` with the correct numeric tag.

---

## Part 3 — Reconstructing AIDL Files and Integrating into the Build

Once you have the field layout and the union tag, you can write the `.aidl` files.

### 3.1 Writing the `.aidl` definitions

**`MihcConfiguration.aidl`:**
```aidl
package vendor.mediatek.hardware.bluetooth.audio;

@VintfStability
parcelable MihcConfiguration {
    int sampleRateHz;
    ChannelMode channelMode;
    byte bitsPerSample;
    byte codecVersion;
    byte qualityIndex;
    byte maxQualityIndex;
    byte minQualityIndex;
    byte frameDuration;
    byte dataInterval;
    byte flags;
}
```

**`MihcCapabilities.aidl`:**
```aidl
package vendor.mediatek.hardware.bluetooth.audio;

@VintfStability
parcelable MihcCapabilities {
    int[] sampleRates;
    ChannelMode[] channelModes;
    byte[] bitsPerSample;
    // ... additional parallel arrays as discovered from the read routine
}
```

### 3.2 Propagating to frozen API snapshots

Android’s build system (Soong) enforces stability for vendor AIDL interfaces. If you modify a frozen interface, you must update the API snapshots and recalculate the `.hash` files, or the build will fail with a “stability violation” error.

The snapshots live under:
```
hardware/mediatek/interfaces/hardware/bluetooth/audio/aidl/aidl_api/vendor.mediatek.hardware.bluetooth.audio/
```

You must propagate your new parcelable definitions to versions `1` through `5` (or whichever versions are frozen) **and** to the `current` directory.

### 3.3 Generating the `.hash` files

Use the `hash_gen.sh` script from AOSP:

```bash
system/tools/aidl/build/hash_gen.sh \
  hardware/mediatek/interfaces/hardware/bluetooth/audio/aidl/aidl_api/vendor.mediatek.hardware.bluetooth.audio/1 \
  1 \
  hardware/mediatek/interfaces/hardware/bluetooth/audio/aidl/aidl_api/vendor.mediatek.hardware.bluetooth.audio/1/.hash
```

Repeat this for each frozen version. The script computes a SHA-1 hash over the interface definition; Soong compares this hash at build time to ensure binary compatibility.

### 3.4 Adding to the union

In `CodecConfiguration.aidl`, add your new parcelable to the union with the numeric tag you discovered:
```aidl
union CodecConfiguration {
    LhdcConfiguration lhdcConfig;
    Lc3Configuration lc3Config;
    MihcConfiguration mihcConfig = <discovered_tag>;
    // ...
}
```

Do the same for `CodecCapabilities.aidl`.

---

## Part 4 — AI-Assisted Reverse Engineering with REA and a Local Model

Manual analysis is precise but slow. REA (Reverse Engineer Anything) is an MCP server that gives an AI agent tools to inspect binaries, Android APKs, JavaScript, .NET assemblies, and more. By pairing REA with a **local GGUF model**, you keep the entire analysis on your machine—no code fragments or strings leave your computer.

The model you specified, `mradermacher/gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic-GGUF`, is a 12B-parameter, 4-bit quantized, uncensored Gemma variant. It is tool-capable and can be served by `llama.cpp`. While REA’s documentation suggests that 27B-class models are ideal for complex reasoning, a 12B model can still handle focused tasks such as:
- Triaging a `.so` and identifying exported symbols.
- Explaining the purpose of `readFromParcel` / `writeToParcel` functions.
- Correlating `.rodata` strings with AIDL package names.
- Drafting `.aidl` files from disassembly evidence.

### 4.1 Prerequisites

| Component | Requirement |
|---|---|
| **REA** | Node.js 22.23.4+, 24.22.1+, or 26.12.1+. Install globally: `npm install --global rea-agents` |
| **llama.cpp** | A build whose `llama-server --help` lists `--mcp-servers-config`. Build with CUDA for GPU acceleration. |
| **Model** | `mradermacher/gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic-GGUF`. Download from Hugging Face. |
| **Native analysis provider** | Ghidra, Hopper, IDA, or Kuna (for deep `.so` analysis). REA can use an existing installation. |
| **Agent** | Claude Code, Codex, Cursor, or any MCP-compatible client. Alternatively, use `llama-server`’s built-in web UI as the MCP host. |

> **Important:** `npx rea-agents setup` alone does not create a persistent installation. For llama.cpp integration, install REA in a stable location (globally or with `npm install --save-exact rea-agents` in a project directory) so the MCP configuration can point to a fixed entrypoint.

### 4.2 Start the model server with MCP enabled

`llama.cpp` supports MCP through the `--mcp-servers-config` flag, but it requires `--jinja` to enable function calling. Without `--jinja`, the model cannot call tools even if the MCP server is connected.

**Minimal launch command:**
```bash
./llama-server \
  -m /path/to/gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic.gguf \
  -c 32768 \
  --host 127.0.0.1 \
  --port 8080 \
  --jinja \
  --mcp-servers-config /path/to/rea-mcp.json
```

**Parameter notes:**
- `-c 32768` sets a 32K context window. The Gemma model may support more, but 32K is a reasonable starting point for analyzing a single `.so` and its surrounding context. REA’s ideal is 64K, but 32K can work for focused tasks.
- `--jinja` is **mandatory** for tool calling.
- `--mcp-servers-config` points to the JSON file that registers REA.

### 4.3 Register REA in the MCP configuration

Create `rea-mcp.json`:

```json
{
  "mcpServers": {
    "rea": {
      "command": "/absolute/path/to/node",
      "args": [
        "/absolute/path/to/rea-agents/scripts/rea.mjs",
        "mcp"
      ],
      "timeout_ms": 450000
    }
  }
}
```

**How to find the paths:**
- `node -p "process.execPath"` prints the Node.js executable.
- For a **global** REA installation: `echo "$(npm root -g)/rea-agents/scripts/rea.mjs"`
- For a **project-local** installation: run `npm root` in that project, then append `/rea-agents/scripts/rea.mjs`.

The `timeout_ms` should account for cold-start times of native analysis engines. REA’s default Ghidra startup budget is 330 seconds; the example above allows 450 seconds (330 + 120 for the operation).

### 4.4 Connect your agent

If you are using **Claude Code** or another agent as the MCP host, point the agent at the `llama-server` OpenAI-compatible endpoint (`http://127.0.0.1:8080/v1`) and ensure REA is registered as an MCP server. REA’s setup command can detect and configure Claude Code, Codex, Cursor, Gemini CLI, and others.

If you prefer to use `llama-server`’s built-in web UI, no separate agent is needed—the web interface acts as the MCP host. However, the web UI’s MCP support is marked experimental, and the CORS proxy (`--webui-mcp-proxy`) should **not** be enabled in untrusted environments.

**For Claude Code specifically:**
```bash
npx rea-agents setup
```
Choose Claude Code, review the proposed changes, and approve them. Then point Claude Code’s model configuration to your local `llama-server` endpoint. REA registers with the agent, not the model, so swapping from a cloud model to a local model is a base-URL change.

### 4.5 Use REA to analyze the Android `.so`

Once the stack is running, you can ask the agent to investigate the binary. REA provides tools for native analysis, Android APK inspection, and AIDL recovery.

**Example prompt:**
```
Analyze the file libbluetooth_audio_session_aidl_mtk.so from the extracted
vendor partition. Use REA’s native analysis tools to:

1. List the exported symbols related to MihcConfiguration and MihcCapabilities.
2. Disassemble the readFromParcel functions and identify the sequence of
   AParcel_read calls.
3. Reconstruct the AIDL parcelable definitions for MihcConfiguration and
   MihcCapabilities, including field names and types.
4. Identify the union tag used for MihcConfiguration in the CodecSpecific union.
5. Show the evidence for each conclusion.
```

REA will call its native analysis provider (Ghidra/Hopper/IDA) to inspect the binary and return pseudocode, assembly, and strings. The agent then synthesizes the findings into AIDL definitions.

**What REA can do automatically:**
- Map `.rodata` strings to package names.
- Demangle C++ symbols.
- Trace `readFromParcel` call sequences.
- Cross-reference the union switch statement.
- Generate a draft `.aidl` file with evidence annotations.

**What still requires human judgment:**
- Verifying the union tag against multiple code paths.
- Handling `@VintfStability` annotations and frozen API snapshots.
- Running `hash_gen.sh` and integrating into the Soong build.
- Testing the reconstructed AIDL against the original binary.

### 4.6 Model considerations for reverse engineering

The `gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic` model is an uncensored variant. This matters for reverse engineering because standard safety training often flags terms like “decompile,” “bypass,” “crack,” and “patch.” In a long agent run, a single refusal can derail the analysis. An uncensored model avoids this failure mode.

However, be aware of the trade-offs:

| Consideration | 12B model | 27B model (REA’s recommendation) |
|---|---|---|
| **Context window** | 32K–64K (depending on configuration) | 64K–128K |
| **Tool-calling reliability** | Good for focused tasks | More robust for long, multi-step investigations |
| **Hardware** | Runs on 8–12 GB VRAM (Q4) | Requires ~16–24 GB VRAM (Q4) |
| **Complex reasoning** | May lose track in very long traces | Better at correlating evidence across many tools |

If you find the 12B model struggling with a complex AIDL reconstruction, you can either:
- Break the task into smaller steps (e.g., “analyze only `MihcConfiguration` first”).
- Switch to a 27B model (Qwen 3.8 27B or a 27B Gemma variant) for the final synthesis.

### 4.7 Safety and privacy

Because the model runs locally via `llama.cpp`, **no binary content, strings, or code fragments leave your machine**. This is a significant advantage over cloud-based agents when analyzing proprietary or sensitive firmware. REA itself also analyzes targets locally; the tool results are sent only to the model you are running.

Do **not** enable `--webui-mcp-proxy` on a machine reachable from the network. The proxy turns `llama-server` into a middleman that can reach arbitrary addresses on behalf of the browser interface. For local analysis at `127.0.0.1`, the default configuration is safe.

---

## Part 5 — Putting It All Together: A Hybrid Workflow

The most effective approach combines manual precision with AI speed.

1. **Acquire the blob** (ADB pull or `payload.bin` extraction).
2. **Triage with LLVM tools** (`llvm-readelf -p .rodata`, `--dyn-syms`).
3. **Ask REA to disassemble and explain** the serialization functions, providing the output of step 2 as context.
4. **Review the AI-generated AIDL draft** against the raw disassembly. Verify the field order and types.
5. **Manually disassemble the union switch** to confirm the numeric tag.
6. **Write the final `.aidl` files** with proper `@VintfStability` annotations.
7. **Propagate to frozen snapshots** and regenerate `.hash` files with `hash_gen.sh`.
8. **Integrate into Soong** and build.
9. **Test** by compiling against the original vendor library and checking that the previously undefined symbols resolve.

This hybrid approach uses the AI for the tedious parts (mapping read sequences, drafting parcelable definitions, cross-referencing strings) while keeping the human in the loop for build-system correctness and final verification.

---

## Quick Reference: Commands and Paths

| Task | Command |
|---|---|
| Dump `.rodata` strings | `llvm-readelf -p .rodata lib.so` |
| List dynamic symbols | `llvm-readelf --dyn-syms lib.so \| grep -i <name>` |
| Demangle C++ symbol | `llvm-cxxfilt <mangled_name>` |
| Disassemble a function | `llvm-objdump -d --no-show-raw-insn --disassemble-symbols=<sym> lib.so` |
| Check JNI exports | `llvm-readelf --dyn-syms lib.so \| grep -E 'JNI_OnLoad\|Java_'` |
| Extract OTA partitions | `payload-dumper-go -o out payload.bin` |
| Generate AIDL hash | `system/tools/aidl/build/hash_gen.sh <api_dir> <version> <output.hash>` |
| Install REA globally | `npm install --global rea-agents` |
| Start llama.cpp with MCP | `llama-server -m model.gguf -c 32768 --jinja --mcp-servers-config rea-mcp.json` |
| Register REA with agent | `npx rea-agents setup` |

---

## Further Reading

- **REA documentation:** `docs/installation.md` (agent registration, provider configuration), `docs/native-investigation.md` (native analysis), `docs/mcp-contracts.md` (tool catalog and result schemas).
- **HackTricks:** “Reversing Native Libraries” for a practical `.so` triage workflow, including JNI and Ghidra usage.
- **Android AIDL Reconstruction Lab:** A step-by-step methodology for recovering Binder interfaces from compiled apps using JADX and static analysis.
- **llama.cpp MCP documentation:** The `--mcp-servers-config` format and the importance of `--jinja` for tool calling.
- **Hugging Face model card:** `mradermacher/gemma-4-12B-it-qat-q4_0-unquantized-uncensored-heretic-GGUF` for quantization details and `llama.cpp` usage instructions.

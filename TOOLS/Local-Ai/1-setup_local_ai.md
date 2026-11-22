# Local AI: Qwen3.8-9B AOSP Expert + Claude Code

Complete installation and optimization guide for running **Claude Code** against a locally-hosted **Qwen3.8-9B-Distill-uncensored-heretic-china_uncensored_dpo-GGUF (Q4_K_M, ~5.6 GB)** model via **Ollama** on Ubuntu Linux, tuned for advanced AOSP development and reverse engineering.

The guide covers GPU permissions, systemd tuning, GGUF chat-template patching (required to fix the `System message must be at the beginning` 500 error), the production-ready Modelfile, and a `claude-local` launcher that sets every Claude Code environment variable in one place.

---

## 📋 Table of Contents

1. [Overview & Architecture](#1-overview--architecture)
2. [Prerequisites](#2-prerequisites)
3. [Install Ollama & Grant GPU Permissions](#3-install-ollama--grant-gpu-permissions)
4. [Configure Ollama Systemd Service](#4-configure-ollama-systemd-service)
5. [Pull the Base Model](#5-pull-the-base-model)
6. [Extract the GGUF Blob](#6-extract-the-gguf-blob)
7. [Extract the Jinja Chat Template](#7-extract-the-jinja-chat-template)
8. [Patch the Jinja Template](#8-patch-the-jinja-template)
9. [Rewrite the GGUF with the Patched Template](#9-rewrite-the-gguf-with-the-patched-template)
10. [Create the Modelfile](#10-create-the-modelfile)
11. [Build the Patched Model](#11-build-the-patched-model)
12. [Create the `claude-local` Launcher](#12-create-the-claude-local-launcher)
13. [Run & Verify](#13-run--verify)
14. [Troubleshooting](#14-troubleshooting)
15. [Reference: Files Produced](#15-reference-files-produced)

---

## 1. Overview & Architecture

```
┌──────────────────┐      Anthropic-compatible       ┌──────────────┐
│   Claude Code    │ ──────────────────────────────▶ │    Ollama    │
│   (CLI client)   │   http://localhost:11434        │  (server)    │
└──────────────────┘                                  └──────┬───────┘
                                                             │
                                                             ▼
                                              ┌──────────────────────────┐
                                              │ aosp-expert-patched      │
                                              │ (Qwen3.8-9B Q4_K_M +     │
                                              │  patched chat template)  │
                                              └──────────────────────────┘
```

**Why the template patch is mandatory:** Claude Code sends a *mid-conversation* `system` message (the "Available agent types" block). The chat template baked into the upstream Qwen3.8 GGUF throws a hard `raise_exception('System message must be at the beginning.')`, which Ollama surfaces to Claude Code as a `500` error. Ollama ignores any `TEMPLATE` directive in a `Modelfile` when importing a GGUF (it always uses the embedded template), and its v0.32.15+ normalization fix does **not** apply to custom GGUFs. The only durable fix is to rewrite the GGUF with a patched template.

---

## 2. Prerequisites

| Requirement | Notes |
| :--- | :--- |
| Ubuntu Linux (x86_64) | Tested on Ubuntu 22.04 / 24.04. |
| ~15 GB free disk | 5.6 GB original blob + 5.6 GB patched copy + temp space. |
| Python 3.10+ with `venv` | Used for the `gguf` tooling. |
| `jq`, `curl`, `git` | JSON extraction and downloads. |
| `sudo` access | Required for the Ollama blob store and systemd config. |
| AMD or NVIDIA GPU | The model will run on CPU, but it is slow. |
| AOSP source tree | `~/clover` or similar; the target in this guide is `xiaomi/rodin`. |

Install the base packages:

```bash
sudo apt update
sudo apt install -y python3 python3-venv python3-pip jq curl git wget aria2
```

---

## 3. Install Ollama & Grant GPU Permissions

### 3.1 Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verify the version (v0.32.15+ is required for the Anthropic-compatibility layer):

```bash
ollama --version
```

Expected: `ollama version is 0.40.x` or newer.

### 3.2 Grant GPU Access (AMD)

If you use an AMD GPU, add your user and the `ollama` service account to the `render` and `video` groups:

```bash
sudo usermod -aG render,video $USER
sudo usermod -aG render,video ollama
```

Log out and back in (or `newgrp render`) so the groups take effect. Verify:

```bash
groups | grep -E 'render|video'
```

### 3.3 Confirm the Server Is Running

```bash
systemctl status ollama --no-pager
curl -s http://localhost:11434/api/version | jq
```

---

## 4. Configure Ollama Systemd Service

These environment variables materially affect performance and stability for a 9B Q4_K_M model at 65k context:

| Variable | Value | Purpose |
| :--- | :--- | :--- |
| `OLLAMA_FLASH_ATTENTION` | `1` | Faster attention, lower memory at long context. |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Quantize the KV cache; saves ~2 GB at 65k context. |
| `OLLAMA_GPU_OVERHEAD` | `536870912` | 512 MB reserved for driver overhead. |
| `OLLAMA_KEEP_ALIVE` | `-1` | Keep the model resident; avoids 30 s cold-start stalls. |

Create the drop-in:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q4_0"
Environment="OLLAMA_GPU_OVERHEAD=536870912"
Environment="OLLAMA_KEEP_ALIVE=-1"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Verify it took effect:

```bash
systemctl show ollama -p Environment --no-pager
```

---

## 5. Pull the Base Model

Pull the exact GGUF from Hugging Face via Ollama's registry:

```bash
ollama pull hf.co/mradermacher/Qwen3.8-9B-Distill-uncensored-heretic-china_uncensored_dpo-GGUF:Q4_K_M
```

Verify it downloaded (~5.6 GB):

```bash
ollama list | grep Qwen3.8
```

---

## 6. Extract the GGUF Blob

Ollama stores weights as content-addressed blobs owned by the `ollama` system user. Your normal user cannot read them, so you must copy the blob to a readable location first.

### 6.1 Locate the blob path

```bash
ollama show --modelfile hf.co/mradermacher/Qwen3.8-9B-Distill-uncensored-heretic-china_uncensored_dpo-GGUF:Q4_K_M \
  | grep -m1 '^FROM'
```

Expected output (the hash will match your install):

```
FROM /usr/share/ollama/.ollama/models/blobs/sha256-db63543950e255f4a786fe7282848d5531a61f4f3672b0a46165efc07d6c2371
```

### 6.2 Copy the blob and claim ownership

```bash
sudo cp /usr/share/ollama/.ollama/models/blobs/sha256-db63543950e255f4a786fe7282848d5531a61f4f3672b0a46165efc07d6c2371 \
        ~/qwen38_model.gguf

sudo chown $(whoami):$(whoami) ~/qwen38_model.gguf
ls -lh ~/qwen38_model.gguf
```

### 6.3 Sanity-check the GGUF magic bytes

```bash
head -c 4 ~/qwen38_model.gguf
```

Expected: `GGUF`. Anything else means the blob path is wrong.

---

## 7. Extract the Jinja Chat Template

```bash
python3 -m venv ~/venv
source ~/venv/bin/activate
pip install --upgrade gguf

python3 -m gguf.scripts.gguf_dump --no-tensors --json ~/qwen38_model.gguf \
  | jq -r '.metadata["tokenizer.chat_template"].value' \
  > ~/qwen38.jinja

wc -l ~/qwen38.jinja
head -5 ~/qwen38.jinja
```

You should see ~150 lines of Jinja, starting with `{%- set image_count = namespace(value=0) %}`.

---

## 8. Patch the Jinja Template

Open `~/qwen38.jinja` and apply **two** changes.

### 8.1 Change 1 — Allow mid-conversation system messages

**Find** (near line 80):

```jinja
{%- if message.role == "system" %}
    {%- if not loop.first %}
        {{- raise_exception('System message must be at the beginning.') }}
    {%- endif %}
```

**Replace** with:

```jinja
{%- if message.role == "system" %}
    {%- if not loop.first %}
        {{- '<|im_start|>system\n' + content + '<|im_end|>' + '\n' }}
    {%- endif %}
```

### 8.2 Change 2 — Remove the "no user query" exception

**Find** (near line 75):

```jinja
{%- if ns.multi_step_tool %}
    {{- raise_exception('No user query found in messages.') }}
{%- endif %}
```

**Delete it entirely.**

### 8.3 Verify

```bash
grep -n "raise_exception" ~/qwen38.jinja
```

Expected — only the unrelated content-type checks should remain:

```
10:  {{- raise_exception('System message cannot contain images.') }}
21:  {{- raise_exception('System message cannot contain videos.') }}
33:  {{- raise_exception('Unexpected item type in content.') }}
39:  {{- raise_exception('Unexpected content type.') }}
43:  {{- raise_exception('No messages provided.') }}
141: {{- raise_exception('Unexpected message role.') }}
```

✅ Neither `System message must be at the beginning` nor `No user query found in messages` should appear.

---

## 9. Rewrite the GGUF with the Patched Template

```bash
python3 -m gguf.scripts.gguf_new_metadata \
  --chat-template-file ~/qwen38.jinja \
  ~/qwen38_model.gguf \
  ~/qwen38_patched.gguf
```

Expected: a progress bar writing ~5.6 GB, finishing in a few minutes.

### 9.1 Verify the patch landed in the new GGUF

```bash
# Should print nothing
python3 -m gguf.scripts.gguf_dump --no-tensors --json ~/qwen38_patched.gguf \
  | jq -r '.metadata["tokenizer.chat_template"].value' \
  | grep "System message must be at the beginning"

# Should diff clean
python3 -m gguf.scripts.gguf_dump --no-tensors --json ~/qwen38_patched.gguf \
  | jq -r '.metadata["tokenizer.chat_template"].value' > ~/qwen38_embedded.jinja
diff ~/qwen38.jinja ~/qwen38_embedded.jinja
```

Both commands should produce **no output**.

---

## 10. Create the Modelfile

Create `~/Modelfile.aosp-expert` with the content below. This is the production version: `num_ctx 65536` (safe on 16 GB VRAM for a 5.6 GB model + q4_0 KV cache), tuned sampling, and a system prompt configured for a live Ubuntu shell running AOSP development.

```dockerfile
# ==============================================================================
# Modelfile for: aosp-expert-patched
# Base: ~/qwen38_patched.gguf (patched Qwen3.8 chat template)
# Purpose: Advanced AOSP Development & Reverse Engineering on Ubuntu Linux
# ==============================================================================

FROM /home/altair-linux/qwen38_patched.gguf

# --- Context Window -----------------------------------------------------------
# 65,536 tokens. Safe on a 16 GB GPU with q4_0 KV cache for a 5.6 GB model.
# If you see "21% CPU offload" in `ollama ps`, drop this to 32768.
PARAMETER num_ctx 65536

# --- Sampling Parameters ------------------------------------------------------
PARAMETER temperature 0.3
PARAMETER top_p 0.85
PARAMETER top_k 20
PARAMETER min_p 0.0
PARAMETER repeat_penalty 1.05

# --- Stop Tokens --------------------------------------------------------------
PARAMETER stop "<|im_start|>"
PARAMETER stop "<|im_end|>"

# --- System Prompt ------------------------------------------------------------
SYSTEM """
You are a principal-level AOSP engineer and senior reverse engineer running
locally on an Ubuntu Linux workstation. You have direct access to the user's
shell, filesystem, and the full suite of native Linux tools. You are NOT a
cloud assistant — you are a local pair-programmer operating inside the user's
actual development environment.

=== ENVIRONMENT ===
- OS: Ubuntu Linux (x86_64 host). The user's AOSP tree lives at ~/clover or
  similar; the target device in this session is `xiaomi/rodin`.
- Shell: bash. Python work happens inside a `venv` at ~/venv.
- Assume every command you suggest will be executed in this local Ubuntu
  shell. Prefer native Linux/Ubuntu commands over cross-platform advice.
- When you propose a shell command, use standard Ubuntu tools:
  * File/search: `find`, `grep -r`, `rg` (ripgrep), `fd`, `locate`, `tree`
  * Text/stream: `sed`, `awk`, `cut`, `sort`, `uniq`, `xargs`, `jq`, `tee`
  * Process/system: `ps`, `top`, `htop`, `pgrep`, `pkill`, `lsof`, `strace`,
    `ltrace`, `perf`, `dmesg`, `journalctl`, `systemctl`
  * Networking: `ip`, `ss`, `tcpdump`, `nmap`, `curl`, `wget`, `nc`
  * Archive/disk: `tar`, `zstd`, `xz`, `rsync`, `dd`, `mount`, `lsblk`
  * Permissions: `sudo`, `chown`, `chmod`, `setfacl`
- Android/AOSP tooling: `repo`, `git`, `soong`, `ninja`, `m`, `mm`, `mmm`,
  `adb`, `fastboot`, `aapt2`, `apktool`, `zipalign`, `d8`, `dexdump`,
  `baksmali`/`smali`, `oatdump`, `vdexExtractor`, `jadx`, `unzip`, `lz4`,
  `simg2img`, `img2simg`, `payload_dumper`, `erofs-utils`.
- Reverse-engineering tooling: `ghidra` (headless via `analyzeHeadless`),
  `rizin`/`radare2`, `objdump`, `readelf`, `nm`, `strings`, `xxd`, `binwalk`,
  `frida`, `frida-ps`, `frida-trace`, `gdb-multiarch`, `qemu-user`.
- Bluetooth/audio/net debug: `btmon`, `bluetoothctl`, `hcitool`, `hcidump`,
  `hciconfig`, `pactl`, `pw-cli`, `wpctl`, `iw`, `iwconfig`, `wpa_cli`,
  `hostapd_cli`, `logcat`, `dumpsys`.
- MediaTek specific: `mtkclient`, `mtk` python tools, `spflashtool`,
  `preloader`/`lk` image parsers.

=== OPERATIONAL GUIDELINES ===
*   **Be precise.** Always use correct C++/Java/Kotlin API names, header paths
    (e.g., `frameworks/native/libs/gui/SurfaceFlinger.cpp`), and build system
    syntax (`.bp`, `.mk`).
*   **Assume a live Ubuntu shell.** When the user asks "how do I…", give the
    exact `bash` command(s) they can paste. Use absolute paths where the
    context is known, and `~` or `$ANDROID_BUILD_TOP` where it is not.
*   **Prefer native tools.** No Windows-only utilities, PowerShell, or macOS
    `brew` commands unless explicitly requested. If a tool is not installed,
    say so and give the `apt install` line.
*   **Think full-stack.** When suggesting a framework change, consider the
    corresponding HAL interface (AIDL/HIDL) and vendor blob compatibility.
*   **Provide a methodology for RE tasks.** Outline static analysis
    (Ghidra/IDA/rizin), dynamic analysis (Frida/ptrace/gdb), and validation
    steps to confirm a blob's behavior. Name the exact commands to run.
*   **Respect the build system.** Use `m`, `mm`, `mmm`, or `soong_ui.bash`
    correctly. Remember `source build/envsetup.sh && lunch <target>` is a
    prerequisite for most AOSP commands.
*   **State risks.** If modifying a proprietary blob, explicitly state the
    risks and the need for rigorous testing in a sandboxed environment.
*   **No generic "how to root" advice.** Focus on architectural understanding,
    code modification, and safe integration paths.
*   **File edits.** When suggesting edits to source files, prefer showing a
    unified `diff` or the exact lines to change rather than rewriting whole
    files. The user will apply changes with `git apply` or an editor.
*   **Logs and debugging.** For runtime issues, default to `adb logcat`,
    `dumpsys`, `strace`, and `dmesg` before suggesting code changes.
"""
```

> **Path note:** If your username is not `altair-linux`, update the `FROM` line to your actual path (`~/qwen38_patched.gguf` works if you run `ollama create` from your home directory).

---

## 11. Build the Patched Model

```bash
cd ~
ollama create aosp-expert-patched -f Modelfile.aosp-expert
```

Expected output ends with:

```
writing manifest
success
```

Verify:

```bash
ollama list | grep aosp-expert-patched
```

Quick smoke test:

```bash
ollama run aosp-expert-patched "Respond with exactly the word: TEST"
```

---

## 12. Create the `claude-local` Launcher

This is the single most important step for a smooth Claude Code experience. Every environment variable Claude Code needs lives in one executable script, so you never launch it with a partial or stale environment again.

### 12.1 Create the launcher

```bash
mkdir -p ~/.local/bin

cat << 'EOF' > ~/.local/bin/claude-local
#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# claude-local — launch Claude Code against the patched local Qwen3.8-9B model
# -----------------------------------------------------------------------------

# Route all Anthropic API traffic to the local Ollama server
export ANTHROPIC_BASE_URL="http://localhost:11434"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY=""

# Extend the client-side timeout. A 9B model is slow at first token,
# especially at 65k context. 15 minutes prevents "check your network"
# retry loops during multi-file reads.
export API_TIMEOUT_MS=900000

# Match the Modelfile's num_ctx so Claude Code compacts before we overflow
export CLAUDE_CODE_MAX_CONTEXT_TOKENS=65536

# Keep background classifier traffic on the local model, not the cloud
export ANTHROPIC_MODEL="aosp-expert-patched"
export ANTHROPIC_DEFAULT_SONNET_MODEL="aosp-expert-patched"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="aosp-expert-patched"
export ANTHROPIC_DEFAULT_OPUS_MODEL="aosp-expert-patched"

# Disable telemetry, update checks, and other non-essential network calls
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Launch
exec claude --model aosp-expert-patched "$@"
EOF

chmod +x ~/.local/bin/claude-local
```

### 12.2 Ensure `~/.local/bin` is on `PATH`

```bash
grep -q '.local/bin' ~/.bashrc || \
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 12.3 Verify

```bash
which claude-local
```

Expected: `/home/altair-linux/.local/bin/claude-local`.

### 12.4 Optional — Mirror the env in `~/.claude/settings.json`

The launcher is sufficient, but if you also run `claude` directly (without the launcher) and want the same configuration, write a `~/.claude/settings.json`:

```bash
mkdir -p ~/.claude
cat << 'EOF' > ~/.claude/settings.json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:11434",
    "ANTHROPIC_AUTH_TOKEN": "ollama",
    "ANTHROPIC_API_KEY": "",
    "API_TIMEOUT_MS": "900000",
    "CLAUDE_CODE_MAX_CONTEXT_TOKENS": "65536",
    "ANTHROPIC_MODEL": "aosp-expert-patched",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "aosp-expert-patched",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "aosp-expert-patched",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "aosp-expert-patched",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  }
}
EOF
```

---

## 13. Run & Verify

### 13.1 Check the model loads on GPU

```bash
ollama run aosp-expert-patched "ok" &
ollama ps
```

Look at the `PROCESSOR` column. It should show **100% GPU**, or at worst a small CPU percentage. If it shows a large CPU share, the model is spilling to system RAM — reduce `num_ctx` in the Modelfile to `32768`, rebuild the model (`ollama create …`), and try again.

### 13.2 Confirm Claude Code reaches the local server

```bash
# Should return a JSON list including "aosp-expert-patched"
curl -s http://localhost:11434/api/tags | jq -r '.models[].name' | grep aosp
```

### 13.3 Launch Claude Code

```bash
cd ~/clover/device/xiaomi/rodin
claude-local
```

Inside the TUI, run:

```
/status
```

Verify all three lines:

| Field | Expected |
| :--- | :--- |
| **API Base URL** | `http://localhost:11434` |
| **Model** | `aosp-expert-patched` |
| **Context** | 65,536 tokens |

### 13.4 Resume an existing session

```bash
claude-local --resume 3fbac2ff-1b1e-4032-99f2-f83206283e5b
```

Because `claude-local` ends with `exec claude … "$@"`, all extra flags (`--resume`, `-p`, `--continue`) are forwarded unchanged.

### 13.5 Kill stuck sessions

```bash
pkill -f "claude" || true
```

---

## 14. Troubleshooting

### `500` error: `raise_exception('System message must be at the beginning.')`

The model Ollama is using still has the unpatched template. Confirm:

```bash
python3 -m gguf.scripts.gguf_dump --no-tensors --json ~/qwen38_patched.gguf \
  | jq -r '.metadata["tokenizer.chat_template"].value' \
  | grep "System message must be at the beginning"
```

If this matches, re-run Step 9 (GGUF rewrite) and re-create the model in Step 11.

If it does **not** match but you still get the error, Ollama is ignoring the embedded template. Fallback: run the small local proxy in the next section.

### `Waiting for API response · will retry in 3m 32s`

This is a stall between Claude Code and Ollama. In order of what to try:

1. **Confirm `API_TIMEOUT_MS` is set** — it lives in `~/.local/bin/claude-local`. Launch via `claude-local`, not `claude`.
2. **Check `ollama ps`** for CPU offload. If the model is spilling to RAM, reduce `num_ctx` to `32768` in the Modelfile, then `ollama create aosp-expert-patched -f Modelfile.aosp-expert` again.
3. **Check `OLLAMA_KEEP_ALIVE`** — it must be `-1` (set in Step 4). Otherwise the model unloads between turns and the next request pays a 30 s cold-start.
4. **Check the Ollama logs** for SSE errors:
   ```bash
   journalctl -u ollama -f
   ```
   A stream of `PingEvent` errors points to the known streaming bug; updating or reverting Ollama fixes it.

### `Model "aosp-expert-patched" isn't recognized · context assumed to be 1m tokens`

This is a **warning**, not an error. Claude Code has no built-in profile for custom names. `CLAUDE_CODE_MAX_CONTEXT_TOKENS=65536` in the launcher silences it.

### `Unexpected reasoning effort` exception

Some Qwen3.8 GGUFs contain a second hard-failing assertion for non-standard reasoning-effort tokens. If this fires, apply the binary patch below. It replaces the exception string *in place* (byte-preserving, same length) so the GGUF hash stays valid:

```bash
sudo python3 - << 'EOF'
import glob, os, subprocess

targets = (
    b"raise_exception('Unexpected reasoning effort ' ~ reasoning_effort "
    b"~ '. Supported types are xhigh (default), medium, and low.')",
    b'raise_exception("Unexpected reasoning effort " ~ reasoning_effort '
    b'~ ". Supported types are xhigh (default), medium, and low.")'
)

def pad(t):
    return b"''" + b" " * (len(t) - 2)

files = []
for pat in ("*.gguf",
            "/usr/share/ollama/.ollama/models/blobs/sha256-*",
            os.path.expanduser("~/.ollama/models/blobs/sha256-*")):
    files.extend(glob.glob(pat))

hit = 0
for f in files:
    try:
        with open(f, "r+b") as fh:
            head = fh.read(25 * 1024 * 1024)
            changed = False
            for t in targets:
                if t in head:
                    head = head.replace(t, pad(t))
                    changed = True
                    print(f"[✓] patched reasoning-effort exception: {f}")
            if changed:
                fh.seek(0); fh.write(head); hit += 1
    except Exception:
        pass

if hit:
    print(f"Patched {hit} file(s). Restarting Ollama…")
    subprocess.run(["systemctl", "restart", "ollama"], check=True)
else:
    print("No matching exception string found.")
EOF
```

Then rebuild the model:

```bash
ollama create aosp-expert-patched -f Modelfile.aosp-expert
```

### `PermissionError` reading `/usr/share/ollama/.ollama/models/blobs/…`

Re-run Step 6 with `sudo cp` and `sudo chown`. Never run `ollama` itself with `sudo`.

### Model runs but responses are extremely slow

- Confirm 100% GPU offload in `ollama ps`.
- If offload is fine but tokens/sec is still slow, the KV cache is the bottleneck. `OLLAMA_KV_CACHE_TYPE=q4_0` (Step 4) cuts it roughly in half. If you skipped that step, do it now.
- If you're running the 9B at `num_ctx 65536` on a 16 GB card and seeing swaps (`dmesg | tail` shows OOM), drop to `num_ctx 32768` and rebuild.

### Fallback: Local Proxy

If the patched GGUF still trips the system-message exception (Ollama ignoring the embedded template), run this proxy. It merges all system messages into the first one, then forwards to Ollama:

```python
# ~/claude_proxy.py
from fastapi import FastAPI, Request
import httpx, uvicorn

app = FastAPI()
OLLAMA = "http://localhost:11434"

@app.post("/v1/messages")
async def messages(req: Request):
    body = await req.json()
    msgs = body.get("messages", [])
    sys_parts, rest = [], []
    for m in msgs:
        if m.get("role") == "system":
            sys_parts.append(m.get("content") or "")
        else:
            rest.append(m)
    if sys_parts:
        body["messages"] = (
            [{"role": "system", "content": "\n\n".join(sys_parts)}] + rest
        )
    async with httpx.AsyncClient(timeout=None) as c:
        r = await c.post(f"{OLLAMA}/v1/messages", json=body)
        return r.text, r.status_code, dict(r.headers)

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8080)
```

```bash
pip install fastapi uvicorn httpx
python3 ~/claude_proxy.py &
# Then change the launcher: export ANTHROPIC_BASE_URL="http://localhost:8080"
```

### Cleanup — remove the patched model but keep the base

```bash
ollama rm aosp-expert-patched
rm -f ~/qwen38_patched.gguf ~/qwen38_embedded.jinja ~/Modelfile.aosp-expert
```

### Full cleanup — remove everything

```bash
ollama rm aosp-expert-patched
ollama rm hf.co/mradermacher/Qwen3.8-9B-Distill-uncensored-heretic-china_uncensored_dpo-GGUF:Q4_K_M
rm -f ~/qwen38_model.gguf ~/qwen38_patched.gguf ~/qwen38.jinja ~/qwen38_embedded.jinja ~/Modelfile.aosp-expert ~/.local/bin/claude-local
sudo rm -f /etc/systemd/system/ollama.service.d/override.conf
sudo systemctl daemon-reload
```

---

## 15. Reference: Files Produced

| Path | Purpose | Size |
| :--- | :--- | :--- |
| `~/qwen38_model.gguf` | Readable copy of the original blob | ~5.6 GB |
| `~/qwen38.jinja` | Extracted + patched Jinja template | ~5 KB |
| `~/qwen38_patched.gguf` | GGUF with the patched template embedded | ~5.6 GB |
| `~/qwen38_embedded.jinja` | Re-extraction of the patched GGUF (verification) | ~5 KB |
| `~/Modelfile.aosp-expert` | Production Modelfile with AOSP/Ubuntu system prompt | ~4 KB |
| `~/.local/bin/claude-local` | Launcher with every Claude Code env var preset | ~1 KB |
| `~/.claude/settings.json` | Optional mirror of the same env vars | ~500 B |
| `/etc/systemd/system/ollama.service.d/override.conf` | Flash attention, KV cache, keep-alive | ~200 B |
| Ollama model `aosp-expert-patched` | Registered model usable by Claude Code | — |

You can safely delete `~/qwen38_model.gguf` and `~/qwen38_embedded.jinja` after the build succeeds — Ollama keeps its own copy of `qwen38_patched.gguf` in its blob store.

---

## 🔄 Updating the System Prompt Later

Do **not** re-patch the GGUF if you only want to change the system prompt. Edit the `SYSTEM` block in `~/Modelfile.aosp-expert` and rebuild:

```bash
ollama create aosp-expert-patched -f ~/Modelfile.aosp-expert
```

The GGUF is reused; only the system-prompt layer is regenerated. This is fast (seconds) and does not touch the patched template.

---

**Last updated:** 2026-11-23
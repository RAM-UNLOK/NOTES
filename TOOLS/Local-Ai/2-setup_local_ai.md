# Local AI Setup: Qwen 3.8 27B Uncensored (IQ4_XS) + Claude Code

Complete installation and optimization guide for Ollama with Opencode Desktop

---

## 1. Install Ollama & Grant GPU Permissions

sudo apt update
sudo apt install -y python3 python3-venv python3-pip jq curl git wget aria2

# Install Ollama
curl -fsSL https://ollama.com/install.sh | sh

# Grant GPU access permissions
sudo usermod -aG render,video $USER
sudo usermod -aG render,video ollama

sudo mkdir -p /etc/systemd/system/ollama.service.d

sudo tee /etc/systemd/system/ollama.service.d/override.conf << 'EOF'
[Service]
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"
Environment="OLLAMA_GPU_OVERHEAD=2147483648"
Environment="OLLAMA_KEEP_ALIVE=-1"
Environment="OLLAMA_CONTEXT_LENGTH=262144"
Environment="OLLAMA_MAX_LOADED_MODELS=1"
Environment="OLLAMA_MAX_QUEUE=1024"
EOF

sudo systemctl daemon-reload
sudo systemctl restart ollama

wget -c --show-progress https://opencode.ai/update/api/latest/desktop/opencode/opencode-desktop-linux-amd64.deb

install the deb file

ollama run hf.co/mradermacher/DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic-GGUF:Q8_0
ollama run hf.co/mradermacher/Qwen3.8-9B-Distill-uncensored-heretic-china_uncensored_dpo-GGUF:Q8_0
ollama run hf.co/kataguru/Qwen3.8-9B-Distill-uncensored-heretic-Finnish-GGUF:Q4_K_M
ollama run hf.co/mradermacher/Gemma-4-12B-Uncensored-i1-GGUF:Q4_K_M

cat << 'EOF' > Modelfile
FROM ./hf.co/mradermacher/DeepSeek-V4-Pro-Qwen3.5-9B-UNCENSORED-heretic-GGUF:Q8_0

# Context size (64k tokens)
# PARAMETER num_ctx 65536

# Sampling settings tuned for systems & AOSP coding
PARAMETER temperature 0.6
PARAMETER top_p 0.95
PARAMETER top_k 20
PARAMETER min_p 0.05
PARAMETER repeat_penalty 1.05

# Dedicated Systems & AOSP Coding System Prompt
SYSTEM """You are an elite systems programmer and software architect specializing in low-level Linux systems, AOSP (Android Open Source Project), C, C++, modern Rust, AIDL/HIDL, and kernel internals.

Guidelines:
- Provide production-grade, memory-safe, and concurrency-safe code.
- Prioritize practical implementations, exact file diffs, or complete functions over vague explanations.
- Never add unnecessary disclaimers, moralizing warnings, or conversational fluff.
- Adhere strictly to POSIX, modern Android architectural standards, and kernel coding conventions."""
EOF

ollama create Mod_DeepSeek-V4-Pro-Qwen3.5:9B -f ./Modelfile

rm Modelfile

# Skills

# https://skillsllm.com/skill/ui-ux-pro-max-skill
npm install -g ui-ux-pro-max-cli
uipro init --ai opencode    # OpenCode
uipro init --ai opencode --global

uipro update                # Refresh skill files from installed CLI package
uipro update --global       # Refresh global skill files from installed CLI package
uipro init --offline        # Compatibility flag; installs bundled templates
uipro init --dry-run        # Preview install actions without writing files
uipro uninstall             # Remove skill (auto-detect platform)
uipro uninstall --ai claude # Remove specific platform
uipro uninstall --global    # Remove from global install

# https://skillsllm.com/skill/open-codesign

# https://github.com/erkamyaman/rust-anything#quick-start

# https://github.com/anomalyco/opencode

# https://github.com/android/skills

# https://github.com/aldefy/compose-skill

# https://github.com/abhixv/google-m3-expressive-design-skill

# https://github.com/NeverSight/learn-skills.dev





#!/usr/bin/env bash
set -e

echo "=== 1. Finishing Ollama Cleanup ==="

# Stop and disable the systemd service if any trace remains
if systemctl list-unit-files | grep -q "^ollama.service"; then
    sudo systemctl stop ollama || true
    sudo systemctl disable ollama || true
    sudo rm -f /etc/systemd/system/ollama.service
    sudo systemctl daemon-reload
fi

# Remove Ollama binaries and libraries
sudo rm -f /usr/local/bin/ollama /usr/bin/ollama
sudo rm -rf /usr/local/lib/ollama /usr/lib/ollama

# Remove Ollama user and force-remove group if still present
if id "ollama" &>/dev/null; then
    sudo userdel -r ollama 2>/dev/null || sudo userdel ollama || true
fi
if getent group "ollama" &>/dev/null; then
    sudo groupdel -f ollama 2>/dev/null || sudo groupdel ollama || true
fi

# Delete all Ollama models, keys, and config data
sudo rm -rf /usr/share/ollama
rm -rf ~/.ollama

echo "=== 2. Removing Claude Code ==="

# Kill any running Claude Code processes
pkill -f claude || true

# Uninstall via npm if installed globally (user or sudo)
if command -v npm &>/dev/null; then
    npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
    sudo npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
fi

# Remove via Linux package managers if installed that way
if command -v apt-get &>/dev/null && dpkg -l | grep -q claude-code; then
    sudo apt-get remove --purge -y claude-code
elif command -v dnf &>/dev/null && rpm -q claude-code &>/dev/null; then
    sudo dnf remove -y claude-code
elif command -v apk &>/dev/null && apk info -e claude-code &>/dev/null; then
    sudo apk del claude-code
fi

# Remove native binaries, symlinks, and version folders directly
CLAUDE_BINS=$(which -a claude 2>/dev/null || true)
for bin in $CLAUDE_BINS; do
    rm -f "$bin" 2>/dev/null || sudo rm -f "$bin" 2>/dev/null || true
done

rm -f ~/.local/bin/claude
sudo rm -f /usr/local/bin/claude /usr/bin/claude
rm -rf ~/.local/share/claude

# Delete all Claude Code config, auth, and cache data
rm -rf ~/.claude ~/.claude.json ~/.cache/claude-code ~/.config/claude-code

echo "=== 3. Verification ==="
echo "Ollama path: $(command -v ollama || echo 'Removed')"
echo "Claude path: $(command -v claude || echo 'Removed')"
echo "Cleanup complete."

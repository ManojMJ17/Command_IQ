#!/bin/bash

# ============================================
# CIQ CLI Installer Script (Linux / Kali)
# ============================================

# GitHub repo URL (replace with your actual repo)
REPO_URL="https://github.com/yourusername/linux-command-translator.git"

echo "===== CIQ Installer ====="

# 1️⃣ Check if pipx is installed
if ! command -v pipx &> /dev/null
then
    echo "Error: pipx is not installed."
    echo "Install pipx first: python3 -m pip install --user pipx"
    echo "Then run: python3 -m pipx ensurepath"
    exit 1
fi

# 2️⃣ Install CIQ via pipx directly from GitHub
echo "Installing CIQ via pipx from GitHub..."
pipx install "git+$REPO_URL" --force

# 3️⃣ Confirm installation
if command -v ciq &> /dev/null
then
    echo "✅ CIQ installed successfully!"
    echo "You can now run it from anywhere:"
    echo "   ciq \"your natural language query\""
else
    echo "❌ Installation failed. Please check for errors above."
fi

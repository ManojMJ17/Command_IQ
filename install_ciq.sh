#!/bin/bash

# ============================================
# CIQ CLI Installer Script (Linux / Kali)
# ============================================

# GitHub repo URL
REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"

# URLs for release assets (adjust if you change release version)
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

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

# 3️⃣ Download prebuilt assets
ASSETS_DIR="$HOME/.ciq_assets"
mkdir -p "$ASSETS_DIR"

echo "Downloading FAISS index and embedding model..."
curl -L -o "$ASSETS_DIR/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"
echo "Downloading T5 model..."
curl -L -o "$ASSETS_DIR/ciq_assets_t5.zip" "$T5_ZIP_URL"

# 4️⃣ Unzip assets into correct folders
echo "Extracting FAISS assets..."
unzip -o "$ASSETS_DIR/ciq_assets_faiss.zip" -d "$HOME/.ciq/faiss_index"
rm "$ASSETS_DIR/ciq_assets_faiss.zip"

echo "Extracting T5 model..."
unzip -o "$ASSETS_DIR/ciq_assets_t5.zip" -d "$HOME/.ciq/model"
rm "$ASSETS_DIR/ciq_assets_t5.zip"

# 5️⃣ Confirm installation
if command -v ciq &> /dev/null
then
    echo "✅ CIQ installed successfully!"
    echo "All prebuilt models and FAISS index are downloaded."
    echo "You can now run it from anywhere:"
    echo "   ciq \"your natural language query\""
else
    echo "❌ Installation failed. Please check for errors above."
fi

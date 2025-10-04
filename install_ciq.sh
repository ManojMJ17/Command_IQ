#!/bin/bash

# ============================================
# CIQ CLI Installer Script (Linux / Kali)
# ============================================

REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

# --------------- Paths ---------------------
CIQ_HOME="$HOME/.ciq"
VENV_PATH="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"

echo "===== CIQ Installer ====="

# 1️⃣ Ensure Python3 is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is required but not found. Install Python3 first."
    exit 1
fi

# 2️⃣ Ensure pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "pipx not found. Installing pipx..."
    python3 -m pip install --user pipx
    python3 -m pipx ensurepath
    echo "⚠️ Please restart your terminal after pipx installation and re-run this script."
    exit 0
fi

# 3️⃣ Create directories
mkdir -p "$CIQ_HOME"
mkdir -p "$PROJECT_SRC"

# 4️⃣ Create virtual environment if it doesn't exist
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# 5️⃣ Activate virtual environment and install dependencies
echo "Installing dependencies inside virtual environment..."
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# 6️⃣ Install CIQ CLI globally using pipx
echo "Installing CIQ globally via pipx..."
pipx install --force "git+$REPO_URL" --spec "$VENV_PATH"

# 7️⃣ Download prebuilt assets
ASSETS_DIR="$PROJECT_SRC"
mkdir -p "$ASSETS_DIR"

echo "Downloading FAISS index and embedding model..."
curl -L -o "$ASSETS_DIR/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"

echo "Downloading T5 model..."
curl -L -o "$ASSETS_DIR/ciq_assets_t5.zip" "$T5_ZIP_URL"

# 8️⃣ Extract assets into src/
echo "Extracting FAISS assets..."
unzip -o "$ASSETS_DIR/ciq_assets_faiss.zip" -d "$ASSETS_DIR"
rm "$ASSETS_DIR/ciq_assets_faiss.zip"

echo "Extracting T5 model..."
unzip -o "$ASSETS_DIR/ciq_assets_t5.zip" -d "$PROJECT_SRC"
rm "$ASSETS_DIR/ciq_assets_t5.zip"

# 9️⃣ Confirm installation
if command -v ciq &> /dev/null; then
    echo "✅ CIQ installed successfully!"
    echo "All dependencies and prebuilt models are ready."
    echo "You can now run it from any folder:"
    echo "   ciq \"your natural language query\""
else
    echo "❌ Installation failed. Please check for errors above."
fi

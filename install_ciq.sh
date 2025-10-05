# #!/bin/bash

# # ============================================
# # CIQ Installer Script (Linux / WSL)
# # ============================================

# set -e

# REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
# FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
# T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

# CIQ_HOME="$HOME/.ciq"
# VENV_PATH="$CIQ_HOME/venv"
# PROJECT_SRC="$CIQ_HOME/src"
# BIN_PATH="$HOME/.local/bin"
# WRAPPER="$BIN_PATH/ciq"

# echo "===== CIQ Installer ====="

# # -------------------------------
# # 1️⃣ Detect package manager & install system dependencies
# # -------------------------------
# install_pkg() {
#     PKG_NAME=$1
#     if command -v apt &> /dev/null; then
#         sudo apt update
#         sudo apt install -y "$PKG_NAME"
#     elif command -v dnf &> /dev/null; then
#         sudo dnf install -y "$PKG_NAME"
#     else
#         echo "⚠️ Unsupported package manager. Please install $PKG_NAME manually."
#     fi
# }

# # Ensure required system packages
# for pkg in python3-venv python3-pip curl unzip; do
#     if ! dpkg -s $pkg &> /dev/null 2>&1 && ! rpm -q $pkg &> /dev/null 2>&1; then
#         echo "Installing missing system package: $pkg"
#         install_pkg $pkg
#     fi
# done

# # -------------------------------
# # 2️⃣ Create directories
# # -------------------------------
# mkdir -p "$CIQ_HOME"
# mkdir -p "$PROJECT_SRC"
# mkdir -p "$BIN_PATH"

# # -------------------------------
# # 3️⃣ Create virtual environment
# # -------------------------------
# if [ ! -d "$VENV_PATH" ]; then
#     echo "Creating virtual environment..."
#     python3 -m venv "$VENV_PATH"
# fi

# # -------------------------------
# # 4️⃣ Activate venv and install dependencies
# # -------------------------------
# echo "Installing project dependencies in virtual environment..."
# source "$VENV_PATH/bin/activate"

# if [ ! -f "requirements.txt" ]; then
#     echo "❌ requirements.txt not found in project root!"
#     exit 1
# fi

# pip install --upgrade pip
# pip install -r requirements.txt
# deactivate

# # -------------------------------
# # 5️⃣ Download prebuilt assets
# # -------------------------------
# echo "Downloading FAISS index and embedding model..."
# curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"

# echo "Downloading T5 model..."
# curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"

# # -------------------------------
# # 6️⃣ Extract assets into src/
# # -------------------------------
# echo "Extracting FAISS assets..."
# unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC"
# rm "$PROJECT_SRC/ciq_assets_faiss.zip"

# echo "Extracting T5 model..."
# unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC"
# rm "$PROJECT_SRC/ciq_assets_t5.zip"

# # -------------------------------
# # 7️⃣ Create global CLI wrapper
# # -------------------------------
# echo "Creating global CLI wrapper at $WRAPPER..."
# cat > "$WRAPPER" <<EOL
# #!/bin/bash
# source "$VENV_PATH/bin/activate"
# python "$PROJECT_SRC/src/cli/main.py" "\$@"
# deactivate
# EOL

# chmod +x "$WRAPPER"

# # -------------------------------
# # 8️⃣ Confirm installation
# # -------------------------------
# if [ -f "$WRAPPER" ]; then
#     echo "✅ CIQ installed successfully!"
#     echo "You can now run it from any folder:"
#     echo "   ciq \"your natural language query\""
# else
#     echo "❌ Installation failed. Please check errors above."
# fi


#!/usr/bin/env bash
set -euo pipefail

# ============================================
# 🧠 CIQ Installer Script (Linux / Kali / WSL)
# Auto-handles Python 3.11 venv for PyTorch
# ============================================

REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

CIQ_HOME="$HOME/.ciq"
VENV_PATH="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"
BIN_PATH="$HOME/.local/bin"
WRAPPER="$BIN_PATH/ciq"
LOCAL_REPO="$HOME/Command_IQ"
CLONE_REPO_PATH="$CIQ_HOME/repo"

echo "==========================================="
echo "🧩 Installing Command IQ (CIQ)"
echo "==========================================="

# 1️⃣ Check system for Python 3.11
PYTHON_BIN=""

if command -v python3.11 &>/dev/null; then
    PYTHON_BIN="python3.11"
elif command -v python3 &>/dev/null; then
    PYTHON_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    if [[ "$PYTHON_VER" < "3.8" ]]; then
        echo "❌ Python >= 3.8 is required."
        exit 1
    elif [[ "$PYTHON_VER" > "3.11" ]]; then
        echo "⚠️  Your system Python ($PYTHON_VER) may be incompatible with PyTorch. Installing Python 3.11 venv."
        if ! command -v python3.11 &>/dev/null; then
            sudo apt update && sudo apt install -y python3.11 python3.11-venv python3.11-distutils python3.11-dev
        fi
        PYTHON_BIN="python3.11"
    else
        PYTHON_BIN="python3"
    fi
else
    echo "❌ Python3 not found. Please install Python 3.8–3.11 first."
    exit 1
fi

echo "🐍 Using Python: $($PYTHON_BIN --version)"

# 2️⃣ Ensure pip exists
if ! $PYTHON_BIN -m pip --version &>/dev/null; then
    echo "📦 Installing pip..."
    curl -sS https://bootstrap.pypa.io/get-pip.py | $PYTHON_BIN
fi

# 3️⃣ Prepare folders
mkdir -p "$CIQ_HOME" "$PROJECT_SRC" "$BIN_PATH"

# 4️⃣ Clone or use local repo
if [ -d "$LOCAL_REPO" ]; then
    SRC_REPO="$LOCAL_REPO"
    echo "📦 Using local repository at $SRC_REPO"
else
    SRC_REPO="$CLONE_REPO_PATH"
    if [ ! -d "$SRC_REPO" ]; then
        echo "⬇️  Cloning CIQ repository..."
        git clone --depth 1 "$REPO_URL" "$SRC_REPO"
    fi
fi

# 5️⃣ Copy project source (avoid nested cli)
echo "📂 Copying project source..."
if command -v rsync &>/dev/null; then
    rsync -a --delete "$SRC_REPO/src/" "$PROJECT_SRC/"
else
    rm -rf "$PROJECT_SRC"/*
    cp -r "$SRC_REPO/src/"* "$PROJECT_SRC/"
fi

# 6️⃣ Create Python 3.11 venv
if [ ! -d "$VENV_PATH" ]; then
    echo "🐍 Creating Python 3.11 virtual environment..."
    $PYTHON_BIN -m venv "$VENV_PATH"
fi

# 7️⃣ Install dependencies
if [ -f "$SRC_REPO/requirements.txt" ]; then
    echo "📦 Installing Python dependencies..."
    source "$VENV_PATH/bin/activate"
    pip install --upgrade pip
    pip install -r "$SRC_REPO/requirements.txt"
    deactivate
else
    echo "⚠️  No requirements.txt found — skipping dependency install."
fi

# 8️⃣ Download FAISS + T5 model assets
echo "⬇️  Downloading FAISS assets..."
curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"

echo "⬇️  Downloading T5 model assets..."
curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"

# 9️⃣ Extract assets
echo "📦 Extracting FAISS index..."
unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC" >/dev/null
rm -f "$PROJECT_SRC/ciq_assets_faiss.zip"

echo "📦 Extracting T5 model..."
unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC" >/dev/null
rm -f "$PROJECT_SRC/ciq_assets_t5.zip"

# Rename T5 model
if [ -f "$PROJECT_SRC/model/saved_model/t5_base_model.pt" ] && [ ! -f "$PROJECT_SRC/model/saved_model/t5_base_resumed.pt" ]; then
    mv "$PROJECT_SRC/model/saved_model/t5_base_model.pt" "$PROJECT_SRC/model/saved_model/t5_base_resumed.pt"
fi

# 10️⃣ Create universal CLI wrapper
echo "⚙️  Creating global CIQ command..."
cat > "$WRAPPER" <<'EOL'
#!/usr/bin/env bash
set -euo pipefail

CIQ_HOME="$HOME/.ciq"
VENV="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"

if [ ! -f "$VENV/bin/activate" ]; then
  echo "❌ Virtualenv not found at $VENV. Please reinstall CIQ."
  exit 1
fi

source "$VENV/bin/activate"
PYTHONPATH="$PROJECT_SRC" python -m cli.main "$@"
deactivate
EOL

chmod +x "$WRAPPER"

# 11️⃣ Final verification
if [ -f "$PROJECT_SRC/model/saved_model/t5_base_resumed.pt" ] && [ -f "$WRAPPER" ]; then
    echo "✅ CIQ installation completed successfully!"
    echo "👉 You can now use it globally:"
    echo "   ciq \"install vlc\""
else
    echo "❌ Installation incomplete. Please check logs above."
fi

echo "==========================================="
echo "🎉 CIQ setup finished."
echo "==========================================="

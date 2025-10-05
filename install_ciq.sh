#!/bin/bash

# ============================================
# CIQ Installer Script (Linux / WSL)
# ============================================

set -e

REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

CIQ_HOME="$HOME/.ciq"
VENV_PATH="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"
BIN_PATH="$HOME/.local/bin"
WRAPPER="$BIN_PATH/ciq"

echo "===== CIQ Installer ====="

# -------------------------------
# 1️⃣ Detect package manager & install system dependencies
# -------------------------------
install_pkg() {
    PKG_NAME=$1
    if command -v apt &> /dev/null; then
        sudo apt update
        sudo apt install -y "$PKG_NAME"
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y "$PKG_NAME"
    else
        echo "⚠️ Unsupported package manager. Please install $PKG_NAME manually."
    fi
}

for pkg in python3-venv python3-pip curl unzip git; do
    if ! dpkg -s $pkg &> /dev/null 2>&1 && ! rpm -q $pkg &> /dev/null 2>&1; then
        echo "Installing missing system package: $pkg"
        install_pkg $pkg
    fi
done

# -------------------------------
# 2️⃣ Create directories if missing
# -------------------------------
mkdir -p "$CIQ_HOME"
mkdir -p "$PROJECT_SRC"
mkdir -p "$BIN_PATH"

# -------------------------------
# 3️⃣ Create virtual environment if missing
# -------------------------------
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
else
    echo "Virtual environment already exists, skipping..."
fi

# -------------------------------
# 4️⃣ Activate venv and install dependencies
# -------------------------------
source "$VENV_PATH/bin/activate"

REQ_FILE="$PROJECT_SRC/requirements.txt"
if [ ! -f "$REQ_FILE" ]; then
    if [ ! -d "$PROJECT_SRC/.git" ]; then
        echo "Cloning repo..."
        git clone "$REPO_URL" "$PROJECT_SRC"
    else
        echo "Repo already exists at $PROJECT_SRC"
    fi
fi

REQ_FILE="$PROJECT_SRC/requirements.txt"
if [ -f "$REQ_FILE" ]; then
    echo "Installing Python dependencies from requirements.txt (excluding torch packages)..."
    pip install --upgrade pip
    grep -vE "torch|torchvision|torchaudio" "$REQ_FILE" | pip install -r /dev/stdin
else
    echo "❌ requirements.txt still not found. Exiting."
    exit 1
fi

# -------------------------------
# 5️⃣ Install PyTorch stack automatically
# -------------------------------
echo "Installing PyTorch stack..."
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# -------------------------------
# 6️⃣ Download FAISS index if missing
# -------------------------------
FAISS_DIR="$PROJECT_SRC/faiss_index"
if [ ! -d "$FAISS_DIR" ]; then
    echo "Downloading FAISS index..."
    curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"
    echo "Extracting FAISS index..."
    unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC"
    rm "$PROJECT_SRC/ciq_assets_faiss.zip"
else
    echo "FAISS index already exists, skipping..."
fi

# -------------------------------
# 7️⃣ Download T5 model if missing
# -------------------------------
T5_DIR="$PROJECT_SRC/src/model/saved_model"
if [ ! -d "$T5_DIR" ]; then
    echo "Downloading T5 model..."
    curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"
    echo "Extracting T5 model..."
    unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC"
    rm "$PROJECT_SRC/ciq_assets_t5.zip"
else
    echo "T5 model already exists, skipping..."
fi

# -------------------------------
# 8️⃣ Create global CLI wrapper if missing
# -------------------------------
if [ ! -f "$WRAPPER" ]; then
    echo "Creating global CLI wrapper at $WRAPPER..."
    cat > "$WRAPPER" <<EOL
#!/bin/bash
source "$VENV_PATH/bin/activate"
python "$PROJECT_SRC/src/cli/main.py" "\$@"
deactivate
EOL
    chmod +x "$WRAPPER"
else
    echo "CLI wrapper already exists, skipping..."
fi

# -------------------------------
# 9️⃣ Confirm installation
# -------------------------------
echo "✅ CIQ installation complete!"
echo "Activate with: source $VENV_PATH/bin/activate"
echo "Run anywhere with: ciq \"your natural language query\""

deactivate

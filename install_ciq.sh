#!/bin/bash

# ============================================
# CIQ Installer Script (Linux / Kali)
# ============================================

REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

CIQ_HOME="$HOME/.ciq"
VENV_PATH="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"
BIN_PATH="$HOME/.local/bin"
WRAPPER="$BIN_PATH/ciq"

echo "===== CIQ Installer ====="

# 1️⃣ Ensure Python3 and pip are available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 is required but not found. Install Python3 first."
    exit 1
fi

if ! command -v pip &> /dev/null; then
    echo "❌ pip is required but not found. Install python3-pip first."
    exit 1
fi

# 2️⃣ Create directories
mkdir -p "$CIQ_HOME"
mkdir -p "$PROJECT_SRC"
mkdir -p "$BIN_PATH"

# 3️⃣ Create virtual environment
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment..."
    python3 -m venv "$VENV_PATH"
fi

# 4️⃣ Activate venv and install dependencies
echo "Installing project dependencies in virtual environment..."
source "$VENV_PATH/bin/activate"
pip install --upgrade pip
pip install -r requirements.txt
deactivate

# 5️⃣ Download prebuilt assets
echo "Downloading FAISS index and embedding model..."
curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"

echo "Downloading T5 model..."
curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"

# 6️⃣ Extract assets
echo "Extracting FAISS assets..."
unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC"
rm "$PROJECT_SRC/ciq_assets_faiss.zip"

echo "Extracting T5 model..."
unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC"
rm "$PROJECT_SRC/ciq_assets_t5.zip"

# 7️⃣ Create global CLI wrapper
echo "Creating global CLI wrapper at $WRAPPER..."
cat > "$WRAPPER" <<EOL
#!/bin/bash
source "$VENV_PATH/bin/activate"
python "$PROJECT_SRC/src/cli/main.py" "\$@"
deactivate
EOL

chmod +x "$WRAPPER"

# 8️⃣ Confirm installation
if [ -f "$WRAPPER" ]; then
    echo "✅ CIQ installed successfully!"
    echo "You can now run it from any folder:"
    echo "   ciq \"your natural language query\""
else
    echo "❌ Installation failed. Please check errors above."
fi

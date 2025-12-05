#!/usr/bin/env bash
set -euo pipefail

# ============================================
# CIQ Installer Script (final, safe)
# - avoids torch/torchvision ABI conflicts
# - preserves existing faiss_index/model dirs unless --force-download
# - supports --no-download and --force-download
# ============================================

REPO_URL="https://github.com/ManojMJ17/Command_IQ.git"
FAISS_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_faiss.zip"
T5_ZIP_URL="https://github.com/ManojMJ17/Command_IQ/releases/download/v1.0/ciq_assets_t5.zip"

CIQ_HOME="${CIQ_HOME:-$HOME/.ciq}"
REPO_CLONE="$CIQ_HOME/repo"
PROJECT_SRC="$CIQ_HOME/src"
VENV_PATH="$CIQ_HOME/venv"
BIN_PATH="$HOME/.local/bin"
WRAPPER="$BIN_PATH/ciq"
LOCAL_REPO="$HOME/Command_IQ"

NO_DOWNLOAD=0
FORCE_DOWNLOAD=0

while [ $# -gt 0 ]; do
  case "$1" in
    --no-download) NO_DOWNLOAD=1; shift ;;
    --force-download) FORCE_DOWNLOAD=1; shift ;;
    -h|--help)
      cat <<'USAGE'
Usage: install_ciq.sh [--no-download] [--force-download]
--no-download     Skip downloading FAISS/T5 assets (use existing assets if present)
--force-download  Force redownload of FAISS/T5 assets (overwrites existing)
USAGE
      exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo
echo "=========================================="
echo " Installing Command_IQ (CIQ) — installer"
echo "=========================================="
echo

# detect package manager
PKG_MANAGER=""
if command -v apt >/dev/null 2>&1; then PKG_MANAGER="apt"; fi
if command -v dnf >/dev/null 2>&1; then PKG_MANAGER="dnf"; fi
if command -v yum >/dev/null 2>&1; then PKG_MANAGER="yum"; fi

install_system_packages() {
  if [ "$PKG_MANAGER" = "apt" ]; then
    echo "Installing system packages via apt (requires sudo)..."
    sudo apt update
    sudo apt install -y python3 python3-venv python3-pip curl unzip git rsync build-essential libopenblas-dev liblapack-dev
  elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then
    echo "Installing system packages via $PKG_MANAGER (requires sudo)..."
    sudo $PKG_MANAGER install -y python3 python3-venv python3-pip curl unzip git rsync gcc gcc-c++ openblas-devel lapack-devel
  else
    echo "⚠ Unsupported package manager; please install python3, python3-venv, pip, curl, unzip, git and rsync manually."
  fi
}

mkdir -p "$CIQ_HOME" "$PROJECT_SRC" "$BIN_PATH"

# ensure required commands exist (best-effort)
for cmd in git curl unzip rsync python3 pip3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "⚠ '$cmd' not found — attempting to install system packages (requires sudo)..."
    install_system_packages
    break
  fi
done

# get repo (prefer local copy)
if [ -d "$LOCAL_REPO" ]; then
  echo "Using local repository at $LOCAL_REPO"
  SRC_REPO="$LOCAL_REPO"
else
  SRC_REPO="$REPO_CLONE"
  if [ ! -d "$SRC_REPO/.git" ]; then
    echo "Cloning repository into $SRC_REPO..."
    git clone --depth 1 "$REPO_URL" "$SRC_REPO"
  else
    echo "Repository already cloned at $SRC_REPO. Pulling latest..."
    (cd "$SRC_REPO" && git pull --ff-only || true)
  fi
fi

# copy src/ contents into PROJECT_SRC (non-destructive)
echo "Copying repo 'src/' contents -> $PROJECT_SRC (non-destructive)"
if command -v rsync >/dev/null 2>&1; then
  rsync -a "$SRC_REPO/src/" "$PROJECT_SRC/"
else
  cp -r "$SRC_REPO/src/"* "$PROJECT_SRC/" || true
fi

# create virtualenv if absent
if [ ! -d "$VENV_PATH" ]; then
  echo "Creating virtualenv at $VENV_PATH..."
  python3 -m venv "$VENV_PATH"
else
  echo "Using existing virtualenv at $VENV_PATH"
fi

# cleanup on exit
trap 'deactivate 2>/dev/null || true' EXIT

# activate venv
# shellcheck disable=SC1090
source "$VENV_PATH/bin/activate"
PIP_BIN="$VENV_PATH/bin/pip"
PY_BIN="$VENV_PATH/bin/python"

# upgrade pip/wheel
"$PIP_BIN" install --upgrade pip setuptools wheel

# install repo requirements except torch/torchvision/torchaudio
REQ_SRC="$SRC_REPO/requirements.txt"
if [ -f "$REQ_SRC" ]; then
  echo "Installing requirements (omitting torch/torchvision/torchaudio)..."
  grep -vE "^(torch|torchvision|torchaudio)([ =<>=]|$)" "$REQ_SRC" | "$PIP_BIN" install -r /dev/stdin
else
  echo "No requirements.txt found in repo; skipping."
fi

# helper to query package versions in venv
py_pkg_ver() {
  pkg="$1"
  "$PY_BIN" - <<PY 2>/dev/null
try:
  import importlib, sys
  m = importlib.import_module("${pkg}")
  v = getattr(m, "__version__", getattr(m, "version", None))
  if v is None: v = "unknown"
  print(v)
except Exception:
  print("__MISSING__")
PY
}

# check torch / torchvision / torchaudio compatibility
TORCH_VER="$(py_pkg_ver torch)" || true
TV_VER="$(py_pkg_ver torchvision)" || true
TA_VER="$(py_pkg_ver torchaudio)" || true

# If torch present but torchvision/torchaudio mismatch, try to reinstall a known-good triple.
# We use the stable CPU set 2.9.1 from PyTorch CPU index as a sensible default.
ensure_torch_compat() {
  # If none are installed -> install
  if [ "$TORCH_VER" = "__MISSING__" ] && [ "$TV_VER" = "__MISSING__" ]; then
    if [ "$NO_DOWNLOAD" -eq 1 ]; then
      echo "Skipping torch install due to --no-download and torch is missing."
      return
    fi
    echo "Installing torch+torchvision+torchaudio (CPU) as they are missing..."
    "$PIP_BIN" install "torch==2.9.1+cpu" "torchvision==0.24.1+cpu" "torchaudio==2.9.1+cpu" --index-url https://download.pytorch.org/whl/cpu
    return
  fi

  # If torch present but torchvision/torchaudio missing or mismatch -> repair
  if [ "$TORCH_VER" != "__MISSING__" ]; then
    # if torchvision/torchaudio exist, check pair compatibility rough heuristic:
    if [ "$TV_VER" != "__MISSING__" ] && [ "$TA_VER" != "__MISSING__" ]; then
      # If torchvision or torchaudio version does not match torch major.minor, repair
      T_MAJOR_MINOR="$("$PY_BIN" - <<PY
import importlib
v = importlib.import_module("torch").__version__
parts = v.split("+")[0].split(".")[:2]
print(".".join(parts))
PY
)"
      TV_MM="$(python - <<PY
import importlib
v=importlib.import_module("torchvision").__version__
print(".".join(v.split("+")[0].split(".")[:2]))
PY
)" || TV_MM="x"
      if [ "$T_MAJOR_MINOR" != "$TV_MM" ]; then
        echo "Detected torch ($TORCH_VER) != torchvision ($TV_VER) ABI mismatch. Repairing to known-good CPU triple..."
        if [ "$NO_DOWNLOAD" -eq 1 ]; then
          echo "Cannot repair torch/torchvision mismatch with --no-download set. Please re-run installer without --no-download."
          exit 1
        fi
        "$PIP_BIN" install --force-reinstall "torch==2.9.1+cpu" "torchvision==0.24.1+cpu" "torchaudio==2.9.1+cpu" --index-url https://download.pytorch.org/whl/cpu
        return
      fi
    else
      # torchvision or torchaudio missing while torch present — install matching pair
      if [ "$NO_DOWNLOAD" -eq 1 ]; then
        echo "torch is present but torchvision/torchaudio missing. Re-run without --no-download to install required wheel."
        exit 1
      fi
      echo "Installing missing torchvision/torchaudio to match torch..."
      "$PIP_BIN" install --force-reinstall "torchvision==0.24.1+cpu" "torchaudio==2.9.1+cpu" --index-url https://download.pytorch.org/whl/cpu
      return
    fi
  fi
}

ensure_torch_compat

# install sentence-transformers/faiss only if needed
if [ "$NO_DOWNLOAD" -eq 1 ] && [ "$FORCE_DOWNLOAD" -eq 0 ]; then
  echo "Skipping faiss-cpu and sentence-transformers install due to --no-download"
else
  if [ "$(py_pkg_ver faiss)" = "__MISSING__" ] || [ "$(py_pkg_ver sentence_transformers)" = "__MISSING__" ]; then
    if [ "$NO_DOWNLOAD" -eq 1 ]; then
      echo "faiss or sentence-transformers missing but --no-download set. Please re-run without --no-download."
      exit 1
    fi
    echo "Installing faiss-cpu and sentence-transformers..."
    "$PIP_BIN" install faiss-cpu sentence-transformers || {
      echo "faiss-cpu/sentence-transformers install failed. Ensure build deps present and retry."
    }
  else
    echo "faiss and sentence-transformers already importable — skipping install."
  fi
fi

# ensure transformers is installed (after torch)
if [ "$(py_pkg_ver transformers)" = "__MISSING__" ]; then
  if [ "$NO_DOWNLOAD" -eq 1 ]; then
    echo "transformers missing but --no-download set. Please re-run without --no-download."
    exit 1
  fi
  echo "Installing transformers..."
  "$PIP_BIN" install transformers
else
  echo "transformers already installed — ensuring latest compatible"
  # safe reinstall could be expensive; skip unless user wants it
fi

# FAISS/T5 asset checks
FAISS_IDX="$PROJECT_SRC/faiss_index/faiss_index_combined.index"
FAISS_META="$PROJECT_SRC/faiss_index/faiss_metadata_combined.pkl"
T5_MODEL_FILE="$PROJECT_SRC/model/saved_model/t5_base_resumed.pt"

if [ "$FORCE_DOWNLOAD" -eq 1 ]; then
  echo "Force-download requested — removing existing asset dirs"
  rm -rf "$PROJECT_SRC/faiss_index" "$PROJECT_SRC/model"
fi

if [ "$NO_DOWNLOAD" -eq 1 ]; then
  if [ -f "$FAISS_IDX" ] && [ -f "$FAISS_META" ] && [ -f "$T5_MODEL_FILE" ]; then
    echo "Assets present — skipping downloads due to --no-download"
  else
    echo "ERROR: One or more assets missing but --no-download was specified."
    echo "Expected: $FAISS_IDX, $FAISS_META, $T5_MODEL_FILE"
    exit 1
  fi
else
  if [ -f "$FAISS_IDX" ] && [ -f "$FAISS_META" ]; then
    echo "FAISS index present — skipping FAISS download."
  else
    echo "Downloading FAISS assets..."
    mkdir -p "$PROJECT_SRC"
    curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"
    echo "Extracting FAISS assets..."
    unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC"
    rm -f "$PROJECT_SRC/ciq_assets_faiss.zip"
  fi

  if [ -f "$T5_MODEL_FILE" ]; then
    echo "T5 model present — skipping T5 download."
  else
    echo "Downloading T5 assets..."
    mkdir -p "$PROJECT_SRC"
    curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"
    echo "Extracting T5 assets..."
    unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC"
    rm -f "$PROJECT_SRC/ciq_assets_t5.zip"
  fi
fi

# write wrapper (safe PYTHONPATH)
echo "Creating/overwriting wrapper at $WRAPPER"
mkdir -p "$(dirname "$WRAPPER")"
cat > "$WRAPPER" <<'EOH'
#!/usr/bin/env bash
set -euo pipefail

CIQ_HOME="$HOME/.ciq"
VENV="$CIQ_HOME/venv"
PROJECT_SRC="$CIQ_HOME/src"

if [ ! -f "$VENV/bin/activate" ]; then
  echo "❌ Virtualenv not found at $VENV. Please re-run installer."
  exit 1
fi

# Activate venv
# shellcheck disable=SC1090
source "$VENV/bin/activate"

# make PYTHONPATH safe even if undefined
export PYTHONPATH="$PROJECT_SRC${PYTHONPATH:+:}${PYTHONPATH:-}"

python -m cli.main "$@"

deactivate
EOH
chmod +x "$WRAPPER"

echo
echo "=========================================="
echo "✅ CIQ installation complete."
echo " - CLI wrapper: $WRAPPER"
echo " - Project src: $PROJECT_SRC"
echo " - Virtualenv: $VENV_PATH"
echo
echo "Run: ciq \"check disk usage\""
echo "To force re-download: ./install_ciq.sh --force-download"
echo "To skip downloads (assets must already exist): ./install_ciq.sh --no-download"
echo "=========================================="
echo

# done (trap will deactivate)




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

# for pkg in python3-venv python3-pip curl unzip git; do
#     if ! dpkg -s $pkg &> /dev/null 2>&1 && ! rpm -q $pkg &> /dev/null 2>&1; then
#         echo "Installing missing system package: $pkg"
#         install_pkg $pkg
#     fi
# done

# # -------------------------------
# # 2️⃣ Create directories if missing
# # -------------------------------
# mkdir -p "$CIQ_HOME"
# mkdir -p "$PROJECT_SRC"
# mkdir -p "$BIN_PATH"

# # -------------------------------
# # 3️⃣ Create virtual environment if missing
# # -------------------------------
# if [ ! -d "$VENV_PATH" ]; then
#     echo "Creating virtual environment..."
#     python3 -m venv "$VENV_PATH"
# else
#     echo "Virtual environment already exists, skipping..."
# fi

# # -------------------------------
# # 4️⃣ Activate venv and install dependencies
# # -------------------------------
# source "$VENV_PATH/bin/activate"

# REQ_FILE="$PROJECT_SRC/requirements.txt"
# if [ ! -f "$REQ_FILE" ]; then
#     if [ ! -d "$PROJECT_SRC/.git" ]; then
#         echo "Cloning repo..."
#         git clone "$REPO_URL" "$PROJECT_SRC"
#     else
#         echo "Repo already exists at $PROJECT_SRC"
#     fi
# fi

# REQ_FILE="$PROJECT_SRC/requirements.txt"
# if [ -f "$REQ_FILE" ]; then
#     echo "Installing Python dependencies from requirements.txt (excluding torch packages)..."
#     pip install --upgrade pip
#     grep -vE "torch|torchvision|torchaudio" "$REQ_FILE" | pip install -r /dev/stdin
# else
#     echo "❌ requirements.txt still not found. Exiting."
#     exit 1
# fi

# # -------------------------------
# # 5️⃣ Install PyTorch stack automatically
# # -------------------------------
# echo "Installing PyTorch stack..."
# pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

# # -------------------------------
# # 6️⃣ Download FAISS index if missing
# # -------------------------------
# FAISS_DIR="$PROJECT_SRC/faiss_index"
# if [ ! -d "$FAISS_DIR" ]; then
#     echo "Downloading FAISS index..."
#     curl -L -o "$PROJECT_SRC/ciq_assets_faiss.zip" "$FAISS_ZIP_URL"
#     echo "Extracting FAISS index..."
#     unzip -o "$PROJECT_SRC/ciq_assets_faiss.zip" -d "$PROJECT_SRC"
#     rm "$PROJECT_SRC/ciq_assets_faiss.zip"
# else
#     echo "FAISS index already exists, skipping..."
# fi

# # -------------------------------
# # 7️⃣ Download T5 model if missing or incomplete
# # -------------------------------
# T5_MODEL_FILE="$PROJECT_SRC/model/saved_model/t5_base_resumed.pt"
# if [ ! -f "$T5_MODEL_FILE" ]; then
#     echo "Downloading T5 model..."
#     curl -L -o "$PROJECT_SRC/ciq_assets_t5.zip" "$T5_ZIP_URL"
#     echo "Extracting T5 model..."
#     unzip -o "$PROJECT_SRC/ciq_assets_t5.zip" -d "$PROJECT_SRC"
#     rm "$PROJECT_SRC/ciq_assets_t5.zip"
# else
#     echo "T5 model already exists, skipping..."
# fi

# # -------------------------------
# # 8️⃣ Create global CLI wrapper if missing
# # -------------------------------
# if [ ! -f "$WRAPPER" ]; then
#     echo "Creating global CLI wrapper at $WRAPPER..."
#     cat > "$WRAPPER" <<EOL
# #!/bin/bash
# # Activate virtual environment
# source "$VENV_PATH/bin/activate"

# # Set PYTHONPATH so Python can find 'cli' module
# export PYTHONPATH="$PROJECT_SRC/src:\$PYTHONPATH"

# # Run CLI using venv python
# "$VENV_PATH/bin/python" "$PROJECT_SRC/src/cli/main.py" "\$@"

# # Deactivate virtual environment
# deactivate
# EOL
#     chmod +x "$WRAPPER"
# else
#     echo "CLI wrapper already exists, skipping..."
# fi

# # -------------------------------
# # 9️⃣ Confirm installation
# # -------------------------------
# echo "✅ CIQ installation complete!"
# echo "Activate with: source $VENV_PATH/bin/activate"
# echo "Run anywhere with: ciq \"your natural language query\""

# deactivate

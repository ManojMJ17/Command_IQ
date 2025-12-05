#!/usr/bin/env bash
set -euo pipefail

# ============================================
# CIQ Installer — final patched version
# - Auto-repairs torch/torchvision/torchaudio ABI mismatches (GPU & CPU)
# - Preserves existing assets unless --force-download
# - Flags: --no-download, --force-download
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

# Flags
NO_DOWNLOAD=0
FORCE_DOWNLOAD=0

# Parse flags
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

# Detect package manager
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
    echo "⚠ Unsupported package manager; ensure python3, python3-venv, pip, curl, unzip, git and rsync are installed."
  fi
}

# Ensure important dirs
mkdir -p "$CIQ_HOME" "$PROJECT_SRC" "$BIN_PATH"

# Ensure essential commands (best-effort)
for cmd in git curl unzip rsync python3 pip3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "⚠ '$cmd' not found — attempting to install system packages (requires sudo)..."
    install_system_packages
    break
  fi
done

# Get repo (prefer local)
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

# Copy repo/src contents -> PROJECT_SRC (preserve existing asset dirs)
echo "Copying repo 'src/' contents -> $PROJECT_SRC (preserve existing assets)"
if command -v rsync >/dev/null 2>&1; then
  rsync -a "$SRC_REPO/src/" "$PROJECT_SRC/"
else
  cp -r "$SRC_REPO/src/"* "$PROJECT_SRC/" || true
fi

# Create virtualenv if missing
if [ ! -d "$VENV_PATH" ]; then
  echo "Creating Python virtual environment at $VENV_PATH..."
  python3 -m venv "$VENV_PATH"
else
  echo "Virtualenv exists at $VENV_PATH — reusing."
fi

# Ensure deactivation on exit
trap 'deactivate 2>/dev/null || true' EXIT

# Activate venv
# shellcheck disable=SC1090
source "$VENV_PATH/bin/activate"
PIP_BIN="$VENV_PATH/bin/pip"
PY_BIN="$VENV_PATH/bin/python"

# Upgrade pip/wheel
"$PIP_BIN" install --upgrade pip setuptools wheel

# Install requirements excluding direct torch lines
REQ_SRC="$SRC_REPO/requirements.txt"
if [ -f "$REQ_SRC" ]; then
  echo "Installing requirements (omitting torch/torchvision/torchaudio) ..."
  grep -vE "^(torch|torchvision|torchaudio)([ =<>=]|$)" "$REQ_SRC" | "$PIP_BIN" install -r /dev/stdin
else
  echo "No requirements.txt found in repo; continuing."
fi

# Helper: get package version with venv python
py_pkg_ver() {
  pkg="$1"
  "$PY_BIN" - <<PY 2>/dev/null
try:
  import importlib
  m = importlib.import_module("${pkg}")
  v = getattr(m,'__version__', getattr(m,'version', None))
  print(v if v is not None else "unknown")
except Exception:
  print("__MISSING__")
PY
}

# Detect current torch & friends
TORCH_VER="$(py_pkg_ver torch)" || true
TV_VER="$(py_pkg_ver torchvision)" || true
TA_VER="$(py_pkg_ver torchaudio)" || true
echo "Detected in venv: torch=$TORCH_VER torchvision=$TV_VER torchaudio=$TA_VER"

# TMPDIR helper for pip extraction (use existing TMPDIR env if set)
TMPDIR_FINAL="${TMPDIR:-$HOME/ciq_tmp}"
mkdir -p "$TMPDIR_FINAL"

# Function: attempt to install matching torchvision/torchaudio for an existing torch build
repair_matching_triple() {
  # Assume torch is present
  TORCH_FULL="$("$PY_BIN" -c 'import torch,sys; print(torch.__version__)' 2>/dev/null || echo "__MISSING__")"
  if [ "$TORCH_FULL" = "__MISSING__" ]; then
    return 1
  fi
  BASE="${TORCH_FULL%%+*}"
  SUFFIX="${TORCH_FULL#${BASE}}"
  echo "Repairing for torch version: $TORCH_FULL (base=$BASE suffix=$SUFFIX)"

  # Derive likely torchvision/torchaudio versions:
  # For some torch releases, torchvision uses a different numbering (e.g. torch 2.6.0 -> torchvision 0.21.0).
  # Provide a small known mapping, else attempt same-base fallback.
  declare -A TV_MAP
  declare -A TA_MAP
  # Known mappings (expand if you add more)
  TV_MAP["2.6.0"]="0.21.0"
  TA_MAP["2.6.0"]="2.6.0"
  TV_MAP["2.9.1"]="0.24.1"
  TA_MAP["2.9.1"]="2.9.1"

  TV_BASE="${TV_MAP[$BASE]:-$BASE}"
  TA_BASE="${TA_MAP[$BASE]:-$BASE}"

  # If suffix contains 'cu', construct index for CUDA wheels
  INDEX_ARG=""
  if echo "$SUFFIX" | grep -q "cu"; then
    CU_TAG="$(echo "$SUFFIX" | sed -E 's/\+([^+]+).*/\1/')"
    INDEX_ARG="--index-url https://download.pytorch.org/whl/${CU_TAG}"
    echo "Using PyTorch wheel index: $INDEX_ARG"
  else
    # CPU index is used when suffix is empty or '+cpu'
    INDEX_ARG="--index-url https://download.pytorch.org/whl/cpu"
  fi

  # Try likely torchvision / torchaudio versions (try TV_BASE + SUFFIX first)
  set -x
  if TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --force-reinstall --no-cache-dir \
       "torchvision==${TV_BASE}${SUFFIX}" "torchaudio==${TA_BASE}${SUFFIX}" ${INDEX_ARG:-} ; then
    set +x
    echo "Successfully installed matching torchvision/torchaudio: ${TV_BASE}${SUFFIX}, ${TA_BASE}${SUFFIX}"
    return 0
  fi
  set +x

  # If first attempt failed, try a small alternate: if TV_BASE differs from BASE,
  # also try TV_BASE with suffix again (sometimes only this one exists).
  # (This handles cases like torch 2.6.0 -> torchvision 0.21.0)
  if [ "$TV_BASE" != "$BASE" ]; then
    set -x
    if TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --force-reinstall --no-cache-dir \
         "torchvision==${TV_BASE}${SUFFIX}" ${INDEX_ARG:-} ; then
      set +x
      echo "Installed torchvision ${TV_BASE}${SUFFIX}; attempting torchaudio..."
      if TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --force-reinstall --no-cache-dir \
           "torchaudio==${TA_BASE}${SUFFIX}" ${INDEX_ARG:-} ; then
        echo "Installed torchaudio ${TA_BASE}${SUFFIX}"
        return 0
      fi
    fi
    set +x
  fi

  # If still failing, try PyPI fallback (plain pip) for general compatibility
  echo "Attempt to fall back to PyPI wheel installs (may or may not include CUDA wheels)..."
  set -x
  if TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --force-reinstall --no-cache-dir torchvision torchaudio; then
    set +x
    echo "Installed torchvision/torchaudio from PyPI."
    return 0
  fi
  set +x

  # Nothing worked
  return 2
}

# Function: install CPU-tested triple
install_cpu_triple() {
  echo "Installing tested CPU triple (recommended fallback)..."
  set -x
  TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --force-reinstall --no-cache-dir \
    "torch==2.9.1+cpu" "torchvision==0.24.1+cpu" "torchaudio==2.9.1+cpu" \
    --index-url https://download.pytorch.org/whl/cpu
  set +x
}

# If torch exists but its friends are missing or broken, try to repair
if [ "$TORCH_VER" != "__MISSING__" ]; then
  need_repair=0
  if [ "$TV_VER" = "__MISSING__" ] || [ "$TA_VER" = "__MISSING__" ]; then
    need_repair=1
  else
    # quick ABI heuristic: compare major.minor
    T_MM="$("$PY_BIN" -c 'import importlib,sys; v=importlib.import_module("torch").__version__.split("+")[0]; print(".".join(v.split(".")[:2]))' 2>/dev/null || echo "x")"
    TV_MM="$("$PY_BIN" -c 'import importlib,sys; v=importlib.import_module("torchvision").__version__.split("+")[0]; print(".".join(v.split(".")[:2]))' 2>/dev/null || echo "y")"
    if [ "$T_MM" != "$TV_MM" ]; then
      need_repair=1
    fi
  fi

  if [ "$need_repair" -eq 1 ]; then
    echo "Detected missing or mismatched torchvision/torchaudio. Attempting auto-repair..."
    if [ "$NO_DOWNLOAD" -eq 1 ]; then
      echo "ERROR: auto-repair requires downloads but --no-download was provided. Re-run without --no-download."
      exit 1
    fi

    # Try GPU-matching repair or PyPI fallback
    if repair_matching_triple; then
      echo "Repair succeeded."
    else
      echo "Auto-repair via matching wheels failed. Trying CPU fallback triple..."
      install_cpu_triple
    fi
  else
    echo "torch + torchvision + torchaudio appear compatible — skipping repair."
  fi
else
  # torch missing entirely -> install triple (prefer CPU triple by default)
  if [ "$NO_DOWNLOAD" -eq 1 ]; then
    echo "ERROR: torch missing and --no-download specified. Re-run installer without --no-download."
    exit 1
  fi
  echo "torch not installed in venv. Installing tested CPU triple by default..."
  install_cpu_triple
fi

# After install/repair, re-evaluate versions
TORCH_VER="$(py_pkg_ver torch)" || true
TV_VER="$(py_pkg_ver torchvision)" || true
TA_VER="$(py_pkg_ver torchaudio)" || true
echo "Post-install: torch=$TORCH_VER torchvision=$TV_VER torchaudio=$TA_VER"

# Install faiss-cpu and sentence-transformers if required
if [ "$NO_DOWNLOAD" -eq 1 ] && [ "$FORCE_DOWNLOAD" -eq 0 ]; then
  echo "Skipping faiss-cpu and sentence-transformers install due to --no-download"
else
  if [ "$(py_pkg_ver faiss)" = "__MISSING__" ] || [ "$(py_pkg_ver sentence_transformers)" = "__MISSING__" ]; then
    if [ "$NO_DOWNLOAD" -eq 1 ]; then
      echo "ERROR: faiss or sentence-transformers missing and --no-download set. Re-run without --no-download."
      exit 1
    fi
    echo "Installing faiss-cpu and sentence-transformers..."
    TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --no-cache-dir faiss-cpu sentence-transformers || {
      echo "Warning: faiss-cpu/sentence-transformers install failed. Ensure build deps are present and retry."
    }
  else
    echo "faiss and sentence-transformers already importable — skipping."
  fi
fi

# Ensure transformers installed
if [ "$(py_pkg_ver transformers)" = "__MISSING__" ]; then
  if [ "$NO_DOWNLOAD" -eq 1 ]; then
    echo "ERROR: transformers missing and --no-download set. Re-run without --no-download."
    exit 1
  fi
  TMPDIR="$TMPDIR_FINAL" "$PIP_BIN" install --no-cache-dir transformers
else
  echo "transformers present — OK"
fi

# -------------------------
# Asset checks: FAISS & T5
# -------------------------
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

# -------------------------
# Create CLI wrapper
# -------------------------
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
# Make PYTHONPATH safe even if undefined
export PYTHONPATH="$PROJECT_SRC${PYTHONPATH:+:}${PYTHONPATH:-}"
# Run the CLI as a module (keeps user cwd)
python -m cli.main "$@"
deactivate
EOH
chmod +x "$WRAPPER"

# Final guidance
echo
echo "=========================================="
echo "✅ CIQ installation completed."
echo " - CLI wrapper: $WRAPPER"
echo " - Project src: $PROJECT_SRC"
echo " - Virtualenv: $VENV_PATH"
echo
echo "Run: ciq \"check disk usage\""
echo "To force re-download: ./install_ciq.sh --force-download"
echo "To skip downloads (assets must already exist): ./install_ciq.sh --no-download"
echo "=========================================="
echo

# Done — deactivate venv
deactivate 2>/dev/null || true

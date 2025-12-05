# Command IQ (CIQ) — Natural Language to Linux Commands

Command IQ (CIQ) is an AI-powered tool that converts natural language instructions into accurate Linux commands. It comes with a prebuilt FAISS index and a T5 model for instant command prediction, so you don’t have to train anything manually.

---

## ⚡ Features

- Convert English instructions into working Linux commands
- Works offline with prebuilt FAISS and T5 model assets
- Supports major Linux distributions and WSL
- Cross-directory CLI: run `ciq "<your query>"` from anywhere
- Automatic environment setup via a single installer script

---

## 🚀 Quick Installation

1. **Clone the repository** (optional if you’re downloading directly from GitHub):

```bash
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ
```

2. **Install Python 3.11** (if not already installed):

```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-distutils python3.11-dev -y
```

> Make sure Python 3.11 **or higher** is installed. The installer will use Python 3.11 in a virtual environment to ensure compatibility with all dependencies.

3. **Run the installer script**:

```bash
chmod +x install_ciq.sh
./install_ciq.sh
```

The installer will:

- Create a virtual environment using Python 3.11
- Install all required Python dependencies (excluding PyTorch, which is installed separately)
- Download and extract FAISS index and T5 model
- Fix filenames and directory structure
- Create a global `ciq` command accessible from any directory

### If you already downlaoded assest you can run with
```bash
./install_ciq.sh --no-download
```

> ⚠️ The installer is **idempotent** — safe to re-run anytime. Existing virtual environments, FAISS indexes, and T5 models will be skipped.

### ❗ Installation Error: `No space left on device`

If you're running CIQ inside VirtualBox or WSL, PyTorch may fail to install due to limited `/tmp` space (even if your disk has free storage).

Fix:

```bash
mkdir -p ~/ciq_tmp
TMPDIR=~/ciq_tmp ./install_ciq.sh
```

4. **Verify installation**:

```bash
ciq "check disk usage"
```

Example output:

```text
Disk usage for /home/user:
df -h
```

---

## 🖥️ Usage

```bash
ciq "<natural language query>"
```

**Examples:**

```bash
ciq "install VLC media player"
ciq "list all files recursively"
ciq "show current disk usage"
```

The CLI will display:

- The interpreted Linux command
- Optionally execute it if enabled in future updates

---

## ⚙️ Notes

- Ensure Python 3.11 or higher is installed. Older versions may cause dependency issues (especially with PyTorch and TorchVision).
- On Linux/WSL, ensure `curl` and `unzip` are installed:

```bash
sudo apt install curl unzip -y
```

- If the CLI is not recognized, ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 📂 Directory Structure after Installation

```
~/.ciq/
├─ src/
│  ├─ cli/
│  │  ├─ __init__.py
│  │  ├─ main.py
│  │  └─ predict.py
│  ├─ model/
│  │  ├─ saved_model/t5_base_resumed.pt
│  │  ├─ t5_base_arch/
│  │  └─ t5_base_tokenizer/
│  └─ faiss_index/
│     └─ faiss_index_combined.index
├─ venv/
└─ bin/
   └─ ciq  (global CLI wrapper)
```

---

## 💡 Troubleshooting

- **Python not found:** Make sure Python 3.11+ is installed and accessible
- **Dependency errors:** Re-run the installer; it upgrades pip and installs all requirements
- **CLI not working:** Ensure `~/.local/bin` is in your PATH

---

## 📜 License

MIT License — see `LICENSE` file

---

## 🧠 Author

Manoj Kumar
GitHub: [https://github.com/ManojMJ17](https://github.com/ManojMJ17)

---

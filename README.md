🚀 Command IQ (CIQ) — Natural Language → Linux Commands

Command IQ is an AI-powered CLI tool that converts plain English instructions into accurate Linux commands.
It uses a hybrid system:

FAISS semantic search (offline & instant)

T5-based command generation model (offline)

CIQ requires zero training, works on any directory, and includes a robust installer that configures everything automatically.

⚡ Features

🔍 Convert natural language to real Linux commands

⚙️ Offline-capable (FAISS + T5 model shipped as assets)

📦 One-command setup via install_ciq.sh

💻 Works on Ubuntu, Kali, Debian, Fedora, WSL2, VirtualBox

🔁 Idempotent installer (safe to re-run anytime)

🌍 Global ciq command available from any folder

🧰 Requirements

Python 3.11 or newer

~3 GB disk space for FAISS + T5 assets

curl, unzip, git installed

To install missing tools:

sudo apt install python3.11 python3.11-venv curl unzip git -y

🚀 Installation
1. Clone repository (recommended):
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ

2. Make installer executable
chmod +x install_ciq.sh

3. Run installer (downloads assets automatically)
./install_ciq.sh


Installer will:

Create ~/.ciq directory

Set up a virtual environment

Install dependencies

Install the correct PyTorch, TorchVision, Torchaudio CPU versions

Download + extract FAISS index & T5 model

Create a global CLI wrapper: ciq

🔄 Reinstall / Update

The installer is idempotent — you can safely run it again anytime.

⛔ Skip downloading assets (if already downloaded)
./install_ciq.sh --no-download


Assets must already exist in:

~/.ciq/src/faiss_index/
~/.ciq/src/model/

🔁 Force re-download of assets
./install_ciq.sh --force-download

❗ Fix for “No space left on device” During PyTorch Install

In VMs (Oracle/VirtualBox) and WSL2, /tmp may be too small.

Use a custom temp dir:

mkdir -p ~/ciq_tmp
TMPDIR=~/ciq_tmp ./install_ciq.sh

## 🧪 Verify CIQ

```bash
ciq "check disk usage"
```

Example result:

```
Final Suggest : df -h
```

---

## 🖥️ Usage Examples

```bash
ciq "list all files recursively"
ciq "install VLC media player"
ciq "find large files in this folder"
ciq "show memory usage"
ciq "how to create a new user"
```

---

## 📁 Directory Structure After Installation

```
~/.ciq/
├── src/
│   ├── cli/
│   │   ├── main.py
│   │   └── predict.py
│   ├── faiss_index/
│   │   ├── faiss_index_combined.index
│   │   └── faiss_metadata_combined.pkl
│   └── model/
│       ├── saved_model/t5_base_resumed.pt
│       ├── t5_base_arch/
│       └── t5_base_tokenizer/
├── venv/
└── bin/
    └── ciq  ← Global CLI wrapper
```

---

## 🔧 Troubleshooting

### ❌ `T5ForConditionalGeneration` or TorchVision import error

Run:

```bash
./install_ciq.sh
```

Installer auto-fixes incompatible Torch/TorchVision versions.

---

### ❌ `ciq: command not found`

Add to PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

### ❌ Assets missing (FAISS or T5)

```bash
./install_ciq.sh --force-download
```

---

## 📜 License

MIT License — see `LICENSE`

---

## 👤 Author

**Manoj Kumar**
GitHub: [https://github.com/ManojMJ17](https://github.com/ManojMJ17)

```

---

# 🎉 Your README is now fully updated and polished.

If you want:

✅ A GIF demo  
✅ A logo/banner  
✅ Shields.io badges  
Just tell me — I can generate everything.
```

Here is the **final cleaned README**, formatted exactly so you can **copy-paste directly into your README.md file** with zero modifications.

---

# ✅ **COPY-PASTE READY README.md**

````markdown
# Command IQ (CIQ) — Natural Language → Linux Commands

Command IQ is an AI-powered CLI tool that converts **plain English instructions** into accurate Linux commands.  
It uses a hybrid offline system powered by:

- **FAISS semantic search**
- **T5 command generation model**

CIQ requires **zero training**, works from **any directory**, and includes a powerful installer that configures everything automatically.

---

## ⚡ Features

- Convert natural language into real Linux commands  
- Offline-capable with bundled FAISS + T5 model  
- One-command installation via `install_ciq.sh`  
- Works on Ubuntu, Kali, Debian, Fedora, WSL2, VirtualBox  
- Installer is **idempotent** — safe to re-run anytime  
- Global `ciq` command works from any folder  

---

## 🧰 Requirements

- **Python 3.11+**
- `curl`, `unzip`, `git` installed
- ~3 GB free space for model assets

Install missing packages on Debian/Ubuntu/Kali:

```bash
sudo apt install python3.11 python3.11-venv curl unzip git -y
````

---

## 🚀 Installation

### 1. Clone the repository:

```bash
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ
```

### 2. Make installer executable:

```bash
chmod +x install_ciq.sh
```

### 3. Run installer:

```bash
./install_ciq.sh
```

Installer will:

* Create `~/.ciq`
* Create a Python virtual environment
* Install dependencies (Torch, Transformers, FAISS)
* Download + extract FAISS index & T5 model
* Create the global CLI wrapper `ciq`

---

## 🔄 Reinstall / Update

### Skip asset downloads (if already extracted):

```bash
./install_ciq.sh --no-download
```

### Force re-download assets:

```bash
./install_ciq.sh --force-download
```

---

## ❗ Fix: “No space left on device” on WSL/VM

If PyTorch fails due to `/tmp` being too small:

```bash
mkdir -p ~/ciq_tmp
TMPDIR=~/ciq_tmp ./install_ciq.sh
```

---

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

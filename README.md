# Command IQ (CIQ) — Natural Language to Linux Commands

Command IQ (CIQ) is an AI-powered tool that converts natural language instructions into accurate Linux commands. It ships with a prebuilt FAISS index and a pretrained T5 model, enabling instant predictions without any manual training.

---

## ⚡ Features

* Convert English instructions into working Linux commands
* Works fully offline using prebuilt FAISS + T5 model assets
* Supports major Linux distributions, WSL, and virtual machines
* CLI works from any directory using the `ciq` global command
* Automatic setup using a single installer script (`install_ciq.sh`)
* Idempotent installer — safe to run multiple times

---

## 🚀 Quick Installation

### **1. Clone the repository** (or download directly):

```bash
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ
```

### **2. Install Python 3.11+** (required for compatibility):

```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-distutils python3.11-dev -y
```

> Ensure Python 3.11 **or higher** is installed. The installer will automatically use Python 3.11 for creating the virtual environment.

### **3. Run the installer script:**

```bash
chmod +x install_ciq.sh
./install_ciq.sh
```

The installer will:

* Create a Python 3.11 virtual environment
* Install required Python dependencies
* Download & extract FAISS index and T5 model
* Create the global `ciq` command

### **If you already downloaded assets:**

```bash
./install_ciq.sh --no-download
```

### **Force re-download assets:**

```bash
./install_ciq.sh --force-download
```

---

## ❗ Installation Error: `No space left on device`

If you're using **WSL** or **VirtualBox**, PyTorch may fail to install due to limited `/tmp` space.

Fix:

```bash
mkdir -p ~/ciq_tmp
TMPDIR=~/ciq_tmp ./install_ciq.sh
```

---

## ✅ Verify Installation

```bash
ciq "check disk usage"
```

Example output:

```
df -h
```

---

## 🖥️ Usage

```bash
ciq "<natural language query>"
```

Examples:

```bash
ciq "install VLC media player"
ciq "list all files recursively"
ciq "show current disk usage"
```

The CLI will show:

* FAISS suggestion
* T5 model suggestion
* Final merged Linux command

---

## ⚙️ Notes

* Requires Python **3.11+**
* Ensure `curl` and `unzip` are installed:

```bash
sudo apt install curl unzip -y
```

* Ensure global CLI path is available:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 📂 Directory Structure After Installation

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
│     ├─ faiss_index_combined.index
│     └─ faiss_metadata_combined.pkl
├─ venv/
└─ bin/
   └─ ciq  (global CLI wrapper)
```

---

## 🧰 Troubleshooting

### **Python not found**

Install Python 3.11:

```bash
sudo apt install python3.11 -y
```

### **Dependencies failed**

Re-run the installer:

```bash
./install_ciq.sh
```

### **Global CLI not recognized**

Add to PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 📜 License

MIT License — see `LICENSE` file.

---

## 🧠 Author

**Manoj Kumar**
GitHub: [https://github.com/ManojMJ17](https://github.com/ManojMJ17)

---

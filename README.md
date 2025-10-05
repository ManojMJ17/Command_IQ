# 🧠 Command IQ (CIQ)

**Command IQ** is an AI-powered Linux command helper that converts natural language queries into accurate Linux commands.  
It works offline using a local FAISS index + T5 model, or online via cloud/local AI integration.

With CIQ, you can type:

```bash
ciq "install VLC"
ciq "check disk usage"
ciq "list all files"
````

…and get the exact Linux command to execute.

---

## ⚡ Features

* Converts natural language queries to Linux commands
* Offline execution with **FAISS + T5** models
* Works globally via `ciq` CLI command
* Safe, idempotent installation — can re-run anytime
* No manual environment setup needed

---

## 📦 Installation (Linux / WSL / Kali)

**Step 1: Clone or download the repository**

```bash
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ
```

**Step 2: Make installer executable and run it**

```bash
chmod +x install_ciq.sh
./install_ciq.sh
```

> This installer will:
>
> * Create a Python virtual environment
> * Install all dependencies
> * Download and extract FAISS + T5 model assets
> * Ensure correct file structure
> * Create the global `ciq` command

**Step 3: Add CIQ to your PATH (if needed)**

```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 🏃 Using CIQ

Run CIQ from **any directory**:

```bash
ciq "check disk usage"
ciq "install vlc"
ciq "list all files"
```

Expected output example:

```
Query         : check disk usage
Final Suggest : df -h
Executing command...

Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        50G   20G   28G  42% /
```

---

## 🔄 Reinstall / Update

CIQ is fully **idempotent**.
If you need to update or fix something:

```bash
./install_ciq.sh
```

No manual cleanup is needed.

---

## 🔧 Post-install Verification

Make sure everything is installed correctly:

```bash
# Check CLI package layout
ls -la ~/.ciq/src/cli
# Should see: __init__.py  main.py  predict.py ...

# Check T5 model file
ls ~/.ciq/src/model/saved_model/t5_base_resumed.pt

# Check FAISS index
ls ~/.ciq/src/faiss_index/
```

Then try:

```bash
ciq "check disk usage"
```

---

## ⚙️ Advanced Options

* Use local AI models (T5 + FAISS) — offline
* Cloud AI mode (DeepInfra / OpenRouter) — optional
* Auto-run suggested commands or get explanations
* Configuration stored under:

```
~/.ciq/
```

---

## 🛠 Requirements

* Python 3.8+
* pip
* Linux / WSL / Kali compatible

Installer handles all dependencies automatically.

---

## 💡 Troubleshooting

* **Command not found** → Make sure `~/.local/bin` is in PATH.
* **Virtualenv missing** → Re-run installer.
* **Assets missing** → Ensure `curl` and `unzip` are installed:

```bash
sudo apt install curl unzip -y
```

* **Module import errors** → Fixed by installer copying `src/cli` correctly and running `python -m cli.main`.

---

## 📁 File Structure After Installation

```
~/.ciq/
├─ src/                  # CIQ source code
│  └─ cli/               # Python package
├─ model/saved_model/    # T5 model
├─ faiss_index/          # FAISS index
├─ venv/                 # Python virtual environment
└─ ciq                   # Global CLI wrapper
```

---

## 📖 Contributing

Contributions welcome! Fork, modify, and submit pull requests.

---

## ⚖️ License

MIT License – see [LICENSE](LICENSE) for details.

```

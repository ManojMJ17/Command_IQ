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

````

2. **Install Python 3.11** (if not already installed):

```bash
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-distutils python3.11-dev -y
```

3. **Run the installer script**:

```bash
chmod +x install_ciq.sh
./install_ciq.sh
```

> The installer will:
>
> - Create a virtual environment using Python 3.11
> - Install all required Python dependencies
> - Download and extract FAISS index and T5 model
> - Fix filenames and directory structure
> - Create a global `ciq` command accessible from any directory

4. **Verify installation**:

```bash
ciq "check disk usage"
```

Expected output should show your current directory and a suggested Linux command.

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
- Optionally execute it if enabled in the future updates

---

## ⚙️ Notes

- Make sure Python 3.11 is installed. Older versions may cause dependency issues (especially with PyTorch and TorchVision).
- If running in WSL or Linux, ensure you have `curl` and `unzip` installed:

```bash
sudo apt install curl unzip -y
```

- The installer is **idempotent**: safe to re-run anytime without breaking existing setup.

---

## 📂 Directory Structure after Installation

```
~/.ciq/
├─ src/
│  ├─ cli/
│  │  ├─ __init__.py
│  │  ├─ main.py
│  │  └─ predict.py
│  ├─ model/saved_model/t5_base_resumed.pt
│  └─ faiss_index/...
├─ venv/
└─ bin/
   └─ ciq  (global CLI wrapper)
```

---

## 💡 Troubleshooting

- **Python not found:** Make sure `python3.11` is installed and accessible.
- **Dependency errors:** Run the installer again; it upgrades pip and installs all requirements.
- **CLI not working:** Ensure `~/.local/bin` is in your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

---

## 📜 License

MIT License — see `LICENSE` file.

---

## 🧠 Author

Manoj Kumar
GitHub: [https://github.com/ManojMJ17](https://github.com/ManojMJ17)

```

````

# 🧠 Command IQ (CIQ)

**Command IQ** is an AI-powered Linux command helper that converts natural language queries into accurate Linux commands. It works offline using a local FAISS index and T5 model, or online via cloud/local AI integration.

With CIQ, you can type commands like:

```bash
ciq "install VLC"
ciq "check disk usage"
ciq "list all files"
````

…and get the exact Linux command to run.

---

## ⚡ Features

* Offline execution with prebuilt **FAISS index** + **T5 model**
* Converts natural language queries to Linux commands
* Supports **multiple Linux distributions** and WSL
* Global CLI command: `ciq`
* Safe, **idempotent installation**
* No manual setup required

---

## 📦 Installation (Linux / WSL / Kali)

1. **Clone the repository (optional if using local CIQ repo)**

```bash
git clone https://github.com/ManojMJ17/Command_IQ.git
cd Command_IQ
```

2. **Download and run the installer**

```bash
chmod +x install_ciq.sh
./install_ciq.sh
```

> The installer will:
>
> * Create a Python virtual environment
> * Install dependencies
> * Download FAISS + T5 model assets
> * Set up the global `ciq` command

3. **Ensure `~/.local/bin` is in your PATH**

```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 🏃 Using CIQ

Run CIQ from **any directory**:

```bash
ciq "install VLC"
ciq "check disk usage"
ciq "list all files"
```

Example output:

```
Query         : check working directory
Final Suggest : pwd
Executing command...

/home/username
```

---

## 🔄 Reinstall / Update

CIQ is **idempotent**, so you can safely re-run the installer to update:

```bash
./install_ciq.sh
```

No manual cleanup is required.

---

## ⚙️ Advanced Options

* Use local AI models: `T5 + FAISS` (offline)
* Add cloud AI API key (DeepInfra / OpenRouter) for online command generation
* Auto-run suggested commands or explain them before running

All configuration is stored under:

```
~/.ciq/
```

---

## 🛠 Requirements

* Python 3.8+
* pip
* Linux / WSL / Kali compatible

The installer handles all Python dependencies automatically.

---

## 💡 Troubleshooting

* **Command not found after installation?**
  Ensure `~/.local/bin` is in your PATH:

```bash
echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

* **Virtual environment missing?**
  Re-run the installer:

```bash
./install_ciq.sh
```

* **Assets not downloaded?**
  Make sure `curl` and `unzip` are installed:

```bash
sudo apt install curl unzip -y
```

---

## 📁 File Structure

After installation:

```
~/.ciq/
├─ src/                  # CIQ source code
├─ model/saved_model/     # T5 model
├─ faiss_index/           # FAISS index
├─ venv/                  # Python virtual environment
└─ ciq                    # Global CLI wrapper
```

---

## 📖 Contributing

Contributions are welcome! Fork the repository, make changes, and submit a pull request.

---

## ⚖️ License

MIT License – see [LICENSE](LICENSE) for details.

```

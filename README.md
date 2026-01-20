# Dotfiles

個人電腦環境設定自動化工具。

## 快速開始

### 新電腦首次安裝

```bash
# 1. Clone repository
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles

# 2. 執行 bootstrap（安裝基本工具）
cd ~/.dotfiles
./install.sh

# 3. 執行完整安裝
make install
```

### 選擇性安裝

```bash
# 開發機（zsh + 完整工具）
make dev

# 測試機/伺服器（bash + 基本工具）
make server
```

## 可用指令

```bash
make help          # 顯示所有可用指令
make install       # 完整安裝
make packages      # 只安裝軟體套件
make shell-zsh     # 設定 zsh
make shell-bash    # 設定 bash
make git           # 設定 git
make vim           # 設定 vim
make uv            # 安裝 uv (Python 套件管理器)
make nvm           # 安裝 nvm 和 Node.js
make symlinks      # 建立所有 symlinks
make backup        # 備份現有設定
make clean         # 移除 symlinks
make list          # 列出可用模組
```

## 目錄結構

```
dotfiles/
├── Makefile              # 主入口
├── install.sh            # Bootstrap 腳本
├── config/               # 設定檔
│   ├── shell/            # Shell 設定
│   │   ├── common/       # 共用 aliases/functions
│   │   ├── bash/         # Bash 設定
│   │   └── zsh/          # Zsh 設定
│   ├── git/              # Git 設定
│   └── vim/              # Vim 設定
├── scripts/              # 安裝腳本
│   ├── common/           # 跨平台腳本 (symlinks, uv, nvm)
│   ├── linux/            # Linux 專用
│   └── macos/            # macOS 專用
├── packages/             # 軟體清單
│   ├── linux/            # Linux 套件 (apt, snap, flatpak)
│   └── macos/            # macOS 套件 (brew)
└── lib/                  # 共用函數庫
```

## 自訂設定

### 新增軟體套件

依照作業系統編輯對應的套件清單，一行一個套件名稱：

**Linux:**
- `packages/linux/apt.txt` - APT 套件
- `packages/linux/snap.txt` - Snap 套件
- `packages/linux/flatpak.txt` - Flatpak 套件

**macOS:**
- `packages/macos/brew.txt` - Homebrew 套件

### 新增 Shell Aliases

編輯 `config/shell/common/aliases.sh`。

### 機器專屬設定

建立 `~/.bashrc.local` 或 `~/.zshrc.local`，這些檔案不會被 git 追蹤。

## 支援的作業系統

- [x] Ubuntu / Debian
- [x] macOS (Homebrew)
- [ ] Windows（規劃中）

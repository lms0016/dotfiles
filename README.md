# Dotfiles

個人電腦環境設定自動化工具。

## 快速開始

支援 macOS、Ubuntu / Linux、WSL2 和 Windows (PowerShell 7)。

**Linux / macOS / WSL2：**

```bash
git clone https://github.com/lms0016/dotfiles.git
cd dotfiles
./install.sh    # Bootstrap（安裝基本工具）
make install    # 完整安裝
```

**Windows（PowerShell 7）：**

```powershell
git clone https://github.com/lms0016/dotfiles.git
cd dotfiles
pwsh -ExecutionPolicy Bypass -File install.ps1
```

## 可用指令

執行 `make help` 查看所有指令。

### make install 包含

| 模組 | 說明 |
| ---- | ---- |
| packages | 系統軟體套件 |
| configs | 設定檔（shell, git, vim） |
| tmux | tmux + TPM |
| uv | Python 套件管理器 |
| nvm | nvm + Node.js |
| ai-agents | AI CLI 工具 (Copilot, Codex, Gemini, Claude) |
| oh-my-zsh | Oh My Zsh + Powerlevel10k |
| ssh | SSH 多帳號設定（互動式） |
| ssh-server | SSH 服務（僅 Linux） |
| firewall | 防火牆（僅 Linux） |

### 測試機

```bash
make tester        # 不含 ai-agents, oh-my-zsh
```

### 維護

```bash
make backup        # 備份現有設定
```

## 目錄結構

```text
dotfiles/
├── Makefile              # 主入口
├── install.sh            # Bootstrap 腳本
├── config/               # 設定檔
│   ├── shell/            # Shell 設定
│   │   ├── common/       # 共用 aliases/functions
│   │   ├── bash/         # Bash 設定
│   │   ├── zsh/          # Zsh 設定
│   │   └── powershell/   # PowerShell 設定 + oh-my-posh 主題
│   ├── git/              # Git 設定
│   ├── ssh/              # SSH 設定模板
│   ├── vim/              # Vim 設定
│   └── tmux/             # Tmux 設定
├── scripts/              # 安裝腳本
│   ├── common/           # 跨平台腳本 (configs, uv, nvm, tmux, ai-agents, oh-my-zsh)
│   ├── linux/            # Linux 專用 (packages, ssh-server, firewall)
│   ├── macos/            # macOS 專用
│   └── windows/          # Windows 專用 (setup-powershell.ps1)
├── packages/             # 軟體清單
│   ├── linux/            # Linux 套件 (apt, snap, flatpak)
│   ├── macos/            # macOS 套件 (brew)
│   └── windows/          # Windows 套件 (winget.txt)
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
- `packages/macos/cask.txt` - Homebrew Cask 應用程式

**Windows:**

- `packages/windows/winget.txt` - winget 套件

### 新增 Shell Aliases

編輯 `config/shell/common/aliases.sh`。

### 機器專屬設定

建立 `~/.bashrc.local` 或 `~/.zshrc.local`，用於存放：

- 機器特定的環境變數或 PATH
- API keys、tokens 等敏感資訊
- 不想同步到 git 的個人設定

這些檔案不會被 git 追蹤。

## SSH 多帳號設定

支援 GitHub 多帳號自動切換（個人 + 工作帳號）。

### 設定流程

此功能已包含在 `make install`，或可單獨執行 `make ssh`。

```bash
# 1. 複製 SSH key 到 ~/.ssh/（從備份）
cp /path/to/backup/id_ed25519_work ~/.ssh/
cp /path/to/backup/id_ed25519_work.pub ~/.ssh/
chmod 600 ~/.ssh/id_ed25519_work

# 2. 執行互動式設定（已包含在 make install）
make ssh
```

### 互動式設定會做的事

1. **設定 Global Git Config** - 確認或設定個人帳號的 name/email
2. **建立 SSH Config** - 設定多個 GitHub host（使用不同 key）
3. **Git URL Rewrite** - 自動將組織 repo 導向對應的 SSH host
4. **Git includeIf** - 依專案目錄自動切換 Git 身份

### 設定完成後的結構

```text
~/.ssh/config          # SSH 多 host 設定
~/.gitconfig           # 包含 URL rewrite 和 includeIf
~/.gitconfig-work      # 工作帳號的 user.name/email
```

### 範例：設定後的效果

```bash
# 個人專案（~/Projects/Personal/）
git config user.email  # → lms001616@gmail.com

# 工作專案（~/Projects/Work/）
git config user.email  # → alan@company.com

# Clone 組織 repo 時自動使用對應的 SSH key
git clone git@github.com:MyCompany/repo.git
# 自動轉換為 → git@github-work:MyCompany/repo.git
```

## Linux 系統設定 (Ubuntu)

以下功能已包含在 `make install` 中，僅在 Linux 環境執行。此處為詳細說明。

### SSH 服務設定

```bash
make ssh-server
```

**功能：**

- 安裝 `openssh-server`
- 設定安全的 `sshd_config`
- 啟用並啟動 SSH 服務

**主要設定：**

| 設定 | 預設值 | 說明 |
| ---- | ------ | ---- |
| Port | 22 | SSH 連線 port |
| PermitRootLogin | no | 禁止 root 直接登入 |
| PasswordAuthentication | yes | 允許密碼登入（可在互動時改為 no） |
| PubkeyAuthentication | yes | 允許金鑰登入 |
| ClientAliveInterval | 60 | Keep-alive 間隔（秒） |
| ClientAliveCountMax | 3 | Keep-alive 最大嘗試次數 |

### 防火牆設定

```bash
make firewall
```

**功能：**

- 安裝 `ufw`
- 設定預設規則（拒絕進入、允許外出）
- 開放 SSH port
- 啟用防火牆

**預設規則：**

```text
預設拒絕 incoming（外部連入）
預設允許 outgoing（對外連線）
允許 SSH（port 22）
```

**互動選項：**

- 可選擇開放 HTTP/HTTPS (80, 443)
- 可選擇開放 RDP (3389) 供遠端桌面使用

## Windows 設定

### 完整安裝

使用 PowerShell 7 執行 `install.ps1`，會自動完成所有步驟：

```powershell
pwsh -ExecutionPolicy Bypass -File install.ps1
```

`install.ps1` 會依序執行：

1. 從 `packages/windows/winget.txt` 安裝 winget 套件
2. 執行 `scripts/windows/setup-powershell.ps1`，包含：
   - `oh-my-posh font install CascadiaCode`（Nerd Font）
   - `Install-Module Terminal-Icons`
   - `Install-Module PSReadLine -AllowPrerelease`
   - 複製 profile (`Microsoft.PowerShell_profile.ps1`) 和 oh-my-posh 主題

> 安裝完成後需在 Windows Terminal 的設定中將字型改為 **CascadiaCode NF**。

### 套件清單

編輯 `packages/windows/winget.txt` 新增或移除套件，一行一個 package ID：

```powershell
# 查看目前清單
cat packages/windows/winget.txt

# 匯出目前機器已安裝的套件（JSON 格式，可用 winget import）
winget export -o winget-export.json
```

## 支援的作業系統

- [x] Ubuntu / Debian
- [x] macOS (Homebrew)
- [x] WSL2 (視為獨立平台，執行 Linux 腳本)
- [x] Windows (PowerShell 7 + `install.ps1`)

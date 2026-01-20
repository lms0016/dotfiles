# Ubuntu 新機器初始化設計

## 目標

讓新安裝的 Ubuntu 桌面機可以快速設定好 SSH 服務和防火牆，以便遠端連線管理。

## 使用情境

1. 安裝好 Ubuntu 桌面版
2. 執行 `make ssh-server` 啟用 SSH 服務
3. 執行 `make firewall` 設定防火牆
4. 從其他機器 SSH 連入，進行後續設定

## 新增模組

### 1. `make ssh-server`

**檔案：** `scripts/linux/ssh-server.sh`

**功能：**
- 安裝 `openssh-server`
- 備份原始 `/etc/ssh/sshd_config`
- 套用安全設定
- 啟用並啟動 `sshd` 服務
- 顯示連線資訊（IP、port）

**sshd_config 設定：**

```
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding yes
PrintMotd no
AcceptEnv LANG LC_*
ClientAliveInterval 60
ClientAliveCountMax 3
```

**互動選項：**
- SSH Port（預設 22）
- 是否禁用密碼登入（預設否，保留密碼登入）

### 2. `make firewall`

**檔案：** `scripts/linux/firewall.sh`

**功能：**
- 安裝 `ufw`（如未安裝）
- 設定預設規則（deny incoming, allow outgoing）
- 開放 SSH port
- 啟用防火牆
- 顯示 `ufw status`

**預設規則：**

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh  # 或自訂 port
```

**互動選項：**
- 確認是否啟用防火牆

## Makefile 新增

```makefile
.PHONY: ssh-server
ssh-server:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/ssh-server.sh
else
	@echo "ssh-server is only available on Linux"
endif

.PHONY: firewall
firewall:
ifeq ($(OS_FAMILY),linux)
	@bash scripts/linux/firewall.sh
else
	@echo "firewall is only available on Linux"
endif
```

## 檔案結構變更

```
scripts/
└── linux/
    ├── packages.sh        # 既有
    ├── ssh-server.sh      # 新增
    └── firewall.sh        # 新增
```

## 測試方式

1. 在新的 Ubuntu VM 上執行 `make ssh-server`
2. 確認 `systemctl status sshd` 顯示 active
3. 執行 `make firewall`
4. 確認 `ufw status` 顯示 active 且有 SSH 規則
5. 從另一台機器測試 SSH 連線

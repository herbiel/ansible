# Ansible Deployment for FreeSWITCH & PHP (Debian 13)

本项自动化部署方案基于 **Debian 13 (Trixie)**，旨在提供灵活的 FreeSWITCH 和 PHP 环境安装。支持单机部署或集群化部署，并支持多种 PHP 版本切换。

---

## 1. 准备工作 (Prerequisites)

1.  **目标系统**: Debian 13 (Trixie)。
2.  **管理机**: 安装有 Ansible (2.10+)。
3.  **FreeSWITCH Token**: 需要一个有效的 **SignalWire Personal Access Token** 用于安装 FreeSWITCH。

---

## 2. 核心配置说明 (Configuration)

所有的配置都集中在两个地方：

### 2.1 主机资产 (`inventory.ini`)
控制“谁”安装“什么”：
- **[voip]**: 该组下的主机将安装 FreeSWITCH。
- **[web]**: 该组下的主机将安装 PHP + Nginx + Redis + MariaDB + Supervisor。
- **[all_in_one]**: 这是一个逻辑组，包含 `voip` 和 `web`。如果你想在一台机器上装全套，可以把 IP 同时写在 `[voip]` 和 `[web]` 下。

### 2.2 全局变量 (`vars/all.yml`)
控制“安装细节”：
- **`signalwire_freeswitch_key`**: **必填**。填入你的 SignalWire Token。
- **`php_version`**: 可选 `"7.1"`, `"7.3"`, `"8.2"`。程序会自动配置 Sury PHP 仓库。
- **`freeswitch_modules`**: 定义需要加载的 FreeSWITCH 模块列表。
- **服务开关**: 例如 `deploy_nginx: yes/no` 可以控制是否执行特定的安装任务。

### 2.3 交互式输入
如果您不想在文件中写 Token，可以在运行剧本时根据提示手动输入。剧本已配置 `vars_prompt`，当检测到 `vars/all.yml` 中的 Token 为默认占位符时，会提示您输入。

### 2.4 命令行传参 (推荐)
您也可以通过 `-e` 直接通过命令行输入任何变量：
```bash
ansible-playbook -i inventory.ini playbook.yml -e "signalwire_freeswitch_key=你的TOKEN"
```

---

## 3. 部署方式 (Deployment)

### 全量部署 (针对所有组)
```bash
ansible-playbook -i inventory.ini playbook.yml
```

### 仅安装特定服务 (使用 Tags)
本方案为每个服务都打上了标签，可以精确控制：
- **仅安装 FreeSWITCH**:
  ```bash
  ansible-playbook -i inventory.ini playbook.yml --tags freeswitch
  ```
- **仅安装 PHP 环境**:
  ```bash
  ansible-playbook -i inventory.ini playbook.yml --tags php
  ```
- **仅安装 Nginx/Redis/MariaDB**:
  ```bash
  ansible-playbook -i inventory.ini playbook.yml --tags nginx,redis,mariadb
  ```

---

## 4. 服务管理 (Service Management)

部署完成后，可以使用标准的 `systemctl` 命令管理服务：
- **FreeSWITCH**: `systemctl status freeswitch`
- **PHP-FPM**: `systemctl status php7.3-fpm` (根据版本名变化)
- **Nginx**: `systemctl status nginx`
- **MySQL/MariaDB**: `systemctl status mariadb`

---

## 5. 项目结构 (Layout)

```text
.
├── README.md               # 本文档
├── inventory.ini           # 节点定义
├── playbook.yml            # 主剧本
├── vars/all.yml            # 变量集合 (版本、Token、模块)
├── tasks/                  # 任务逻辑 (freeswitch.yml, php.yml 等)
├── templates/              # 配置文件模板 (Jinja2)
└── handlers/               # 服务重启触发器
```

---

## 6. 注意事项
- **PHP 7.1/7.3**: 由于 Debian 13 较新，旧版 PHP 通过 `sury.org` 仓库提供。
- **Security**: 请确保 `inventory.ini` 中的 `ansible_user` 和 `ansible_become` 设置正确（建议使用 sudo 用户）。

---

## 7. 版本控制 (Git Multi-Remote Push)

项目配置了同时推送到 GitLab 和 GitHub。

### 7.1 查看配置
```bash
git remote -v
```
你应该能看到 `origin` 远程库有两个 push 地址。

### 7.2 如何手动添加 (供参考)
如果你需要重新配置，可以使用以下命令：
```bash
# 添加第一个 push 地址 (GitLab)
git remote set-url --add --push origin git@gitlab.tangbull.com:devops/ansible.git
# 添加第二个 push 地址 (GitHub)
git remote set-url --add --push origin git@github.com:herbiel/ansible.git
```

### 7.3 推送命令
执行一次 `git push` 会同时更新两个仓库：
```bash
git push origin main
```

---

## 8. Docker 部署模板 (Laravel)

项目包含了一个通用的 Laravel Docker 部署模板，位于 `laravel-docker/` 目录。
该模板支持动态 PHP 版本切换、Horizon 队列管理、Redis 和 DB 服务，并支持多项目共存。

### 8.1 使用方法
将模板复制到任意 Laravel 项目根目录：
```bash
cp -r /path/to/ansible/laravel-docker/* /path/to/your-laravel-project/
```

### 8.2 配置
复制 `.env.example` 并编辑：
```bash
cp .env.example .env
```
重点修改 `APP_NAME` (用于区分 Docker 容器名) 和 `PHP_VERSION`：
```ini
APP_NAME=my-project-name
PHP_VERSION=7.4
APP_PORT=8080
```

### 8.3 启动
使用提供的脚本一键启动：
```bash
./deploy.sh
```
这将自动构建镜像（使用 `archive.debian.org` 源以兼容旧版 PHP）、启动服务并运行迁移。


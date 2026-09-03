# 运维规范（本仓库内约定）

## 1. 目录与命名

- `playbooks/*.yml` —— 编排入口，要"薄"，只负责按顺序 include_role。
- `roles/hc_<专项>/` —— 一个专项一个 role：
  - `tasks/collect.yml`  采集（纯数据，不判定）
  - `templates/body.md.j2`  判定+渲染正文
  - `tasks/render.yml`  写三件套事实
  - `tasks/main.yml`  编排三阶段(可含 root 探测)
- 采集变量统一 `hc_<专项>_<名字>.out` 结构；专项事实统一 `hc_section_<key>_body/_title/_severity`。
- 命令产物一律走 `hc_common/exec` 宏，**禁止在 collect 里裸写 shell 任务**。

## 2. 变量分层

| 层 | 放哪 | 用途 |
|---|---|---|
| 全局默认 | `inventory/group_vars/all.yml` | 阈值 / 专项开关 / 关键服务 / 报告目录 |
| 环境差异 | 建议 `inventory/group_vars/prod.yml` 等(按组) | 不同机房/环境不同值 |
| 单机特例 | `inventory/host_vars/<host>.yml` | 个别机器覆盖 |
| 运行时 | Semaphore 模板 Arguments / 命令行 `-e` | 临时目标、临时阈值 |

阈值只在 all.yml 定义并在 role 内以 `th.xxx | default(y)` 引用 —— **不许硬编码魔法数**。

## 3. 敏感信息

- **密钥/密码/证书绝不进明文 YAML**；用 `ansible-vault encrypt` 后放 `group_vars/*/vault.yml`。
- vault 密码本身不入库(`.gitignore` 已挡 `.vault_pass*`)；在 Semaphore 的项目里配置 vault 密码。
- inventory 里的密码字段同样建议 vault 或 Semaphore 凭据(SSH key)方式，避免明文仓库。
- `.gitignore` 已忽略 `__pycache__/*.retry/.env/*.log` 等。

## 4. 兼容与稳定（写新采集前必读）

- 目标机系统差异：Debian/RHEL 双路径用变量或 `ansible_os_family` 判断；systemd 相关用 `ansible_service_mgr` 把关。
- 工具缺失(ethtool/smartctl/nginx…) → 该段降级 `ℹ️ 工具缺失`，不许报错中止。
- 目录扫描类命令(du/find/journalctl)一律加 `timeout`，防大库拖死。
- 需要 root 的采集：无 `hc_root_ok` 时 `when` 跳过 + 渲染层 `ℹ️ 需 root 跳过`。
- JSON 输出的采集记得 `hc_json: true`(见 ARCHITECTURE §2)。

## 5. 提交流程

1. 本地改 → `scripts/check.sh`(语法 + localhost 冒烟)全绿
2. commit message 中文一句话点明改了什么
3. `git push`（本机已配免交互）
4. 若已接入 Semaphore：面板里对仓库点一次 Fetch / 或直接 Run 看新逻辑

## 6. Roadmap 维护

做/想做什么，随时在 `docs/ROADMAP.md` 勾选/增补 —— 别只放在脑子里或聊天记录里。

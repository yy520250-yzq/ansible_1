# ansible_1 · 多用途 Ansible 巡检体系

一个把「主机健康检查」做成 **纯 Ansible、可扩展、可视化** 的运维工具集。核心是一套
**通用框架 + 七个专项巡检**：采集 → 判定 → 报告，全部声明式 YAML，阈值一处可调，
既能本地命令行跑，也能接入 **Semaphore / AWX** 在网页上点按钮、看实时日志。

> 设计铁律：**采集单项失败绝不中断、工具/权限缺失自动降级、判定不写死**。

---

## ✨ 能力总览（七个专项）

| 专项 | role | 检查什么 | 覆盖 |
|---|---|---|---|
| 系统通用 | `hc_os` | uptime/负载÷核数、内存/Swap、磁盘容量+inode、CPU/内存 Top 进程、僵尸、网卡错误、可登录用户/UID0、失败登录、dmesg 异常、重启历史、failed 服务、时间同步、需重启标记 | 每台主机 |
| 安全 | `hc_security` | SSH 加固基线(递归解析 Include)、**危险端口是否暴露 0.0.0.0**、防火墙联动判级、口令策略(PASS_MAX_DAYS)、空密码、SUID、计划任务、自动更新/fail2ban/auditd | 每台主机 |
| 服务 | `hc_service` | **关键服务清单逐个探活+自启**、enabled 却未运行、failed、反复重启(NRestarts)、24h 错误日志归因 | 每台主机 |
| 网络 | `hc_network` | 网关/公网连通矩阵、DNS 解析耗时、实体网卡速率/状态、TCP 状态分布/重传率、连接 Top 对端 | 每台主机 |
| 内存 | `hc_memory` | 真实可用 vs cache 可回收、**PSI 内存压力**、overcommit/swappiness、cgroup 限制 | 每台主机 |
| 磁盘 | `hc_disk` | 容量+inode、大目录/大文件 Top、**/var/log 膨胀**、块设备、只读挂载告警 | 每台主机 |
| k8s | `hc_k8s` | 节点状态/版本/压力/taint、CrashLoop/Pending/ImagePull/OOM/高重启、Deployment 副本、PVC 绑定、系统组件、Warning 事件 | 控制机(kubectl) |

每个专项输出独立一段 Markdown 正文 + `ok/warn/crit` 级判定；全部汇成**一份报告**。

## 📁 目录结构

```
├── playbooks/
│   ├── inspect.yml          # ★ 巡检入口:七专项按 hc_profiles 开关执行
│   └── toolbox.yml          # 老版通用工具箱示例(保留作参考)
├── inventory/
│   ├── hosts.yml            # 主机清单(真实机器照注释填)
│   └── group_vars/all.yml   # ★ 配置中心:阈值/专项开关/关键服务
├── roles/
│   ├── hc_common/           # 框架:安全采集宏 exec / 报告渲染 md+json
│   ├── hc_os / hc_security / hc_service / hc_network
│   ├── hc_memory / hc_disk / hc_k8s
│   └── nginx/               # 示例能力(工具箱时代遗留,与巡检无关)
├── docs/                    # 架构 / 规范 / 路线图 / 样例报告
├── scripts/check.sh         # 提交前自检(语法 + 本机冒烟)
└── ansible.cfg
```

## 🚀 快速开始

**前提**：目标机有 Linux + python3；控制机有 `ansible`(≥2.15)。跑 k8s 专项需控制机有 `kubectl`+kubeconfig。

```bash
# 1) 填入要巡检的机器(inventory/hosts.yml),或先用 localhost 试跑
# 2) 全量巡检(默认对 local 组 = localhost)
ansible-playbook playbooks/inspect.yml

# 指定机器 / 关掉某个专项
ansible-playbook playbooks/inspect.yml -e "target=web01" \
    -e "hc_profiles={'os':true,'k8s':false}"
```

报告产出在目标机的 `~/ops-healthcheck/<主机>-<日期>.md`(人读) 和 `.json`(机读)，
同时在控制台/面板日志打印一屏**摘要**。阈值、关键服务、专项开关都在
`inventory/group_vars/all.yml`，改配置不用动任何 role。

> 需要 root 的采集(空密码/SUID/dmesg/失败登录/重启历史/日志归因)在无提权时**自动降级为 ℹ️**；
> 给巡检账号配免密 sudo 后自动点亮。

## 🖥 对接 Semaphore / AWX

在面板里建 **Project → Repository(本仓库) → 建一个 Inventory → Task Template**：
- **Playbook path**：`playbooks/inspect.yml`
- **Inventory**：指向真实主机清单(Semaphore 自带 或 仓库 `inventory/hosts.yml`)
- 可选：`Arguments` 传 `-e target=xxx`

面板里点 **Run** 即触发，滚动日志里直接看每台机的判定摘要；可再用 Semaphore 定时任务做每日巡检。
（本仓库 ansible.cfg 自带 inventory 指向，模板也可不另配清单直接跑 localhost 冒烟。）

## 🧩 加一个新专项(约 30 分钟)

1. `cp -r roles/hc_os roles/hc_<新名>`，删掉无用文件
2. `tasks/collect.yml` 里写采集 —— **一律走 `hc_common.exec` 宏**：
   ```yaml
   - include_role: {name: hc_common, tasks_from: exec}
     vars: {hc_cmd: "你的命令", hc_var: hc_xxx_yyy, hc_timeout: 20}
   # 输出 JSON 的命令加 hc_json: true(采集宏会显式解析,兼容 ansible 2.17/2.20)
   ```
3. `templates/body.md.j2` 里按 `rank(0/1/2)` 判级、逐段输出,结尾 `<!--SEV:xx-->`
4. `tasks/render.yml` 写入 `hc_section_<key>_body/_title/_severity` 三件套
5. `playbooks/inspect.yml` 加 include_role + `group_vars/all.yml` 加开关 → 完事

详见 [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)。

## 📚 文档

- [架构与约定](docs/ARCHITECTURE.md) — 数据流、判定模型、采集宏、报告格式
- [运维规范](docs/CONVENTIONS.md) — 目录/命名/变量分层/敏感信息/提交流程
- [路线图](docs/ROADMAP.md) — 已完成与待办(云专项/n8n/持久化/定时)
- [样例报告](docs/sample-report.md) — 一段真实输出示例

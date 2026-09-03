# 路线图

> 状态: ✅ 已完成 · 🔨 进行中 · ⬜ 待做

## 核心框架
- ✅ `hc_common` 框架:安全采集宏 / root 探测 / 报告渲染(Markdown+JSON+摘要) / 自动清理
- ✅ 阈值中心化 `inventory/group_vars/all.yml`
- ✅ 采集类型双版本兼容(`hc_json`, ansible 2.17 / 2.20)

## 专项(每项含 采集→判定→报告段)
| 专项 | 状态 | 备注 |
|---|---|---|
| 系统通用 `hc_os` | ✅ | |
| 安全 `hc_security` | ✅ | 含 root 增强项(空密码/SUID/cron) |
| 服务 `hc_service` | ✅ | 关键服务清单 `hc_critical_services` |
| 网络 `hc_network` | ✅ | 需 root 项待补(如 ethtool 深度、tcpdump 采样) |
| 内存 `hc_memory` | ✅ | 泄漏趋势需二次采样(基线)后实现 |
| 磁盘 `hc_disk` | ✅ | 增长趋势/告警需历史基线 |
| k8s `hc_k8s` | ✅ | 需控制机 kubectl;Semaphore 容器内自动降级 |
| 云 `hc_cloud` | ⬜ | **阻塞:待提供云厂商 + 只读 AK**;框架将做成 providers/ 适配器 |

## 工程化
- ✅ 本地 CLI + Semaphore 面板双通道跑通
- ✅ GitHub 托管、README/docs 完善
- ✅ 定时可用 Semaphore Scheduler / 系统 cron 触发 API
- 🔨 自动化定时巡检落地(本机)
- ⬜ **持久化**:git daemon 本地镜像固化为 systemd 服务;面板报告拉回宿主机归档
- ⬜ **告警/解读**:n8n(或 cron+脚本)解析 JSON → ❌/⚠️ 推 钉钉/飞书/邮件;ollama 生成中文诊断
- ⬜ root 完整体检验收(免密 sudo 配置后,空密码/SUID/登录审计/dmesg 点亮)

## 未来方向(点子)
- 基线化:首次巡检存基线,后续 diff(新增 SUID/大文件/端口)
- 趋势:磁盘/内存/日志增长率的双次快照曲线
- 自动修复 playbook 草案(报告 crit → 对应修复模板,人工确认后点 Run)

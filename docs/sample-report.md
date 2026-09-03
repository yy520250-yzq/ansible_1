# 样例报告(节选·主机名已匿名)

```markdown
# 巡检报告 · <host> · 2026-09-03 12:55:15

系统: Ubuntu 22.04 · 内核 6.18.33.1 · x86_64
平台: wsl · CPU 14 核

## 总评: ❌ 有关键问题
## ❌ 系统通用巡检 (crit)
### 1. 运行时长与负载
09:55 up 6 days, 9:00, 3 users, load average: 0.26, 0.60, 0.57
load 1/5/15 = 0.26 / 0.60 / 0.57 · CPU 28 核 · 负载系数 0.01
### 2. 内存与 Swap
内存: 总量 31.3GB · 可用 23.4GB · 已用 25.4%
Swap: 总量 8.0GB · 已用 0.0%
### 3. 磁盘容量与 inode
✅ /  (ext4 /dev/sdd):  容量 7%  |  inode 2%
### 4. 进程健康
进程数 330 · 线程数 2627 · 僵尸进程 0
  CPU Top:
· 7.2% 1.9 618MB claude
· 3.9% 1.1 361MB kube-apiserver
### 6. 用户与登录
UID=0 账号: root
  可登录普通用户: yy
当前在线: 3 人
### 7. 服务 · 内核 · 时间
❌ systemd 存在 failed 服务: kb-backup.service   ← 真实故障示例
时间同步: 正常 · Time zone: Asia/Shanghai

## ⚠️ 安全专项巡检 (warn)
### 2. 暴露面与危险端口
TCP 共监听 21 个端口
⚠️ 危险端口暴露到 0.0.0.0: 5432@0.0.0.0   ← 已启防火墙 → warn(未启则 crit)
### 4. 口令策略与账号
PASS_MAX_DAYS = 99999 天 ⚠️ 建议 ≤90
### 6. 补丁与防护服务
自动安全更新: ✅ 已启用 · fail2ban: ℹ️ inactive

## ✅ k8s 专项巡检 (ok)
### 1. 集群节点
✅ itops-control-plane · k8s v1.31.0 · 28核 / 31GB
### 4. 系统组件与事件
近期 Warning 事件: 1 条
· Readiness probe failed: HTTP probe failed with statuscode: 500
```

> 同目录还有一份 `.json`(机读),字段 `verdict` + `sections[{key,title,severity,body}]`,
> 供后续告警网关 / AI 解读消费。

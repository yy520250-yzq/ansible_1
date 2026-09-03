# 架构与约定

## 1. 总体数据流

```
        ┌────────────── 每台主机上执行 ──────────────┐
inspect.yml ─► hc_os / hc_security / hc_service / …   │
        │  每专项:  collect(采集) → body.md.j2(判定)   │
        │           → 写主机事实:                     │
        │             hc_section_<key>_body/_title/_severity
        └──────────────────────────────────────────────┘
                           │
                 hc_common/report(汇总渲染)
                           │
     Markdown(人读) + JSON(机读) + 控制台/Semaphore 摘要
```

- 每个专项 **只与两个事实契约**：写 `hc_section_<key>_body/_title/_severity`，由 `hc_common` 汇总。
- 因此加/删专项互不影响，报告模板自动发现存在的 section(`key in vars`)。

## 2. 采集宏 `hc_common/tasks/exec.yml`（唯一命令入口）

所有探测命令必须经它执行，保证：

- `failed_when: false` + `timeout` → **单项失败绝不中断整个巡检**，结果留空由判定层标 `ℹ️/⚠️`
- `hc_become: true` 的任务配合 `when: hc_root_ok` —— 无提权就 **跳过而非硬跑**（避免误报"无异常"）
- 结果统一入 `{{ hc_var }} = {rc, out, err}`
- **`hc_json: true`**：输出是 JSON 的命令显式 `from_json`。原因：ansible 2.17 会自动把 JSON 型 stdout
  解析成 dict/list，而 2.20 不再隐式转换——显式解析保证两个版本行为一致，`.out` 直接是 dict/list。
- 需 root 的采集用 include_role 自带的 `when:` 包裹(见各专项 collect.yml)。

## 3. 判定模型（阈值中心化）

- 阈值全部在 `inventory/group_vars/all.yml` 的 `hc_thresholds`，role 里只写 `default()` 兜底。
- 专项正文模板以 `namespace(rk=0)` 累加严重度：`0 ok / 1 warn / 2 crit`，末尾映射成
  `<!--SEV:xxx-->` 注释行。
- `render.yml` 三步：`lookup('template','body.md.j2')` 渲染 → 按 marker 提取段级 severity →
  用 `regex_replace` 剥掉 marker，正文干净。

## 4. 判定/报告模板写法的坑（本仓库已经踩平）

| 坑 | 正确做法 |
|---|---|
| Jinja 不支持列表推导 `[x for x in y]` | 用 `for` + `list.append`(在模板顶层定义 list，循环里 `{% set _ = list.append(k) %}` 变更持久) |
| for 循环里 `{% set %}` 不持久 | 用 `namespace`(如 `namespace(rk=0)`)、或 list.append 后再判断 |
| `vars.get(k) is defined` 对 None 恒真 | 判存在性用 `k in vars` |
| 模板里 `-%}` 会吞掉行间换行致文本粘连 | 需要分行时用 `%}` 或加空白行，不要到处 `-%}` |
| JSON 型 stdout 依赖隐式解析 | 采集宏加 `hc_json: true` 显式解析 |
| `group_vars/xxx.yml` 会被当"xxx 主机组" | 只有 `group_vars/all.yml`(或组名)才生效；且目录在 `inventory/group_vars/` 下(跟随 inventory 文件位置) |

## 5. 报告格式

- **Markdown**：标题(主机/时间/系统/内核) → 总评(取最差 severity) → 各专项段落
- **JSON**：`{host, date, os, kernel, verdict, sections:[{key,title,severity,body}]}` —— 供二期
  n8n / ollama / 告警网关机读。
- **摘要**：控制台/面板滚动日志打一屏总评 + 各专项状态。

报告落点：目标机 `$HOME/ops-healthcheck/`(可用 `hc_report_dir` 覆盖)；保留天数
`hc_report_retain_days` 默认 30，超期自动清理。

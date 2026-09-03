# ansible_1 —— 多用途运维工具箱

一个**声明式、可扩展**的 Ansible 仓库骨架：想加新能力，就加一个 `roles/xxx/`，
不改已有任何文件；在 Semaphore（或其他 AWX/Tower 类平台）里一个模板对应一个用途。

```
.
├── ansible.cfg              # 本地默认配置(远程执行以平台配置为准)
├── inventory/
│   └── hosts.yml            # 机器清单(本地测试用;平台里也可自建 Inventory)
├── group_vars/
│   └── all.yml              # 全局变量
├── playbooks/
│   └── toolbox.yml          # ★ 通用工具箱入口:按 tool 变量执行对应 role
└── roles/
    ├── nginx/               # 示例能力:装好并启动 nginx
    │   └── tasks/main.yml
    └── ...                  # 以后加新 role 放这里
```

## 本地快速验证(不依赖任何平台)

```bash
# 只对本机(localhost)执行 nginx 安装
ansible-playbook playbooks/toolbox.yml -e "target=localhost tool=nginx"
```

## 设计思路:改输入不改代码

- **同一入口,换 `tool` 就是换一个用途** —— 不需要为每件事写一个新 playbook。
- `target` 控制跑哪台/哪些机器;平台里可以把它做成每次执行时填写的表单。
- 加新能力 = `cp -r roles/nginx roles/新名字` → 改 `tasks/main.yml` → 完事。
- 想支持 RedHat(apt→dnf)等系统,在 task 里加 `when: ansible_os_family == "RedHat"` 分支即可,结构不变。

## 对接 Semaphore(可视化面板)

1. 在 Semaphore 建 **Project**,把本仓库(URL)加为 **Repository** 并提供认证。
2. 建一个 **Environment**,Inventory 可指向仓库的 `inventory/hosts.yml`,
   也可在 Semaphore 里自建(勾选"启用 Semaphore 自己的 inventory")。
3. 建 **Task Template**:
   - Name: 比如 `安装 nginx`
   - Playbook file path: `playbooks/toolbox.yml`
   - Inventory / Environment: 选上一步
   - Variables 填: `tool=nginx`
4. 每次想跑别的事,再建一个模板、`tool` 指向别的 role 即可;仓库和机器无需改动。

## 常用变量

| 变量 | 含义 | 示例 |
|---|---|---|
| `target` | 目标机器或主机组 | `web01` / `linux` / `all` |
| `tool`   | 要执行的 role 名 | `nginx` / `docker` / `certbot`… |

> 敏感信息(密码/密钥)用 `ansible-vault` 加密后放 `group_vars/`,不要把明文提交进仓库。

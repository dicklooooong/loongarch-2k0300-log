# 把这份日志发布到 GitHub（首次配置 → 日常提交）

**当前状态：已经推送成功**——本地 `main` = 远程 `main` = `5554d49`。日常只需要 `git add` / `git commit` / `git push` 三步。

本机（`E:\deepseek\第一个工作区`）的实测结论，重点是**同一个操作在不同权限层级下表现完全不同**：

| 检查项 | 受限 shell 下 | 完整权限下 | 结论 |
| --- | --- | --- | --- |
| 安装 Git | `winget.exe` 是 0 字节应用执行别名，执行无输出、退出码 1 | `winget v1.29.380` 正常，成功装上 **Git 2.55.0.5** | 受限时改用官方安装包 |
| HTTPS 出网 | 所有站点 `schannel: AcquireCredentialsHandle failed: SEC_E_NO_CREDENTIALS (0x8009030e)` | 连通；GitHub 另需 `http.schannelCheckRevoke=false` 绕开 `CRYPT_E_NO_REVOCATION_CHECK` | 换普通终端，或关闭吊销检查 |
| 推送认证 | `Cannot prompt because user interactivity has been disabled` | `git push` 直接用 GCM 已存凭据成功，**无需手输 PAT** | 确认 `credential.helper manager` 生效 |

> 遇到"什么都不通"时先别改方案：**换一档权限、换一个站点、换一个版本各测一次**，通常能立刻定位到是哪一层的问题。

## 第 0 步之前：本仓库其实已经就绪

- 本地仓库已 `git init` 并完成首次提交，远程已关联：`origin` = <https://github.com/dicklooooong/loongarch-2k0300-log.git>
- 提交身份为**仓库级**配置（未改全局）：`dicklooooong` / `250634730+dicklooooong@users.noreply.github.com`
- 远程建仓库时勾选过 README，已有 `e92fa3c Initial commit`；本次是**整合历史后快进推送**，没有强推

> 所以下面第 1～4 步主要是"换新机器 / 重装环境"时的参考流程。

---

## 第 0 步：仓库规划

| 项目 | 值 |
| --- | --- |
| 仓库名 | `loongarch-2k0300-log` |
| 远程地址 | <https://github.com/dicklooooong/loongarch-2k0300-log> |
| 可见性 | 建议 **Private**（想公开随时可改，反之则难收回） |
| 默认分支 | `main` |
| 内容边界 | 不放密码、公司内部 SDK、他人隐私 → 这类内容放到已被忽略的 `private/` |

## 第 1 步：安装 Git

**方式 A（推荐，任何环境都能用）**：下载官方安装包
<https://git-scm.com/download/win> → 运行 → 一路默认即可（安装器会自己处理 PATH）。

**方式 B（winget，实测可用）**：

```powershell
winget --version      # 受限 shell 里可能毫无输出、退出码 1（别名不可用），换普通终端再试
winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements
# 实测：winget v1.29.380 + Git 2.55.0.5 安装成功，路径 C:\Program Files\Git\cmd\git.exe
```

装完**必须新开一个终端窗口**（让 PATH 生效），然后验证：

```powershell
git --version         # 期望输出 git version 2.x.x
```

> 若这里报"无法识别"，先用 `Test-Path "C:\Program Files\Git\cmd\git.exe"` 判断是
> "没装成功"还是"PATH 没刷新"——两者的修法完全不同。

## 第 2 步：配置身份（只需一次，全局生效）

`init-and-push.cmd` 会在缺少配置时提示你输入；也可以手敲：

```powershell
git config --global user.name "你的名字"
git config --global user.email "你的GitHub邮箱"
git config --global init.defaultBranch main
git config --global core.quotepath false      # 中文文件名不乱码
git config --global credential.helper manager # 记住凭据，避免每次输入
git config --global --list                    # 复核
```

> 不想暴露真实邮箱：GitHub → Settings → Emails 勾选 "Keep my email addresses private"，
> 用它给出的 `noreply` 地址。

## 第 3 步：初始化并首次提交

在仓库目录内执行（`init-and-push.cmd` 已包含这些步骤）：

```powershell
cd E:\deepseek\第一个工作区\loongarch-2k0300-log
git init
git add .
git commit -m "chore: 初始化 2K0300 学习日志模板与目录结构"
```

## 第 4 步：关联远程并推送

```powershell
git remote add origin https://github.com/dicklooooong/loongarch-2k0300-log.git
git branch -M main
git push -u origin main
```

### 认证：HTTPS + PAT

首次推送要求输入用户名与密码，**密码处必须填 Personal Access Token（PAT），不能填账号密码**。

生成：GitHub → Settings → Developer settings → Personal access tokens → Fine-grained tokens
→ 只授予目标仓库 **Contents: Read and write** 权限。

### 认证：SSH（长期更省事，一次配置免输入）

```powershell
ssh-keygen -t ed25519 -C "你的GitHub邮箱"      # 一路回车，密码可留空
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
ssh -T git@github.com                          # 看到 successfully authenticated 即可
git remote set-url origin git@github.com:dicklooooong/loongarch-2k0300-log.git
git push -u origin main
```

> 把剪贴板内容粘贴到 GitHub → Settings → SSH and GPG keys → New SSH key。

---

## 日常提交（三行命令）

```powershell
git add .
git commit -m "log(daily): 2026-10-16 串口无输出排查"
git push
```

| 前缀 | 用途 |
| --- | --- |
| `log(daily):` | 每日日志 |
| `log(weekly):` | 每周复盘 |
| `log(topic):` | 专题笔记新增或大幅更新 |
| `assets:` | 补充串口日志、波形、截图 |
| `docs:` | 模板、说明文档调整 |
| `chore:` | 结构、配置、忽略规则 |
| `fix:` | 修正已有记录中的错误结论 |

## 常见问题排查（含本机实测项）

| 现象 | 原因 | 解决 |
| --- | --- | --- |
| `无法将"git"项识别为 cmdlet` | 未安装，或装了但 PATH 未刷新 | 装完**新开终端**；用 `Test-Path` 区分两种原因 |
| `winget` 无输出、退出码 1 | `winget.exe` 是 0 字节应用执行别名，受限进程调用无法启动 | 换普通终端／提高权限；或改用官方安装包下载 |
| `schannel: SEC_E_NO_CREDENTIALS (0x8009030e)` | 该 shell 根本拿不到 TLS 凭据（**所有**站点同样报错） | 换到普通终端执行；不要在这个 shell 里做下载/推送 |
| `CRYPT_E_NO_REVOCATION_CHECK (0x80092012)` | 凭据拿到了，但查不到证书吊销列表（OCSP/CRL 不可达） | `git config http.schannelCheckRevoke false`；curl 加 `--ssl-no-revoke` |
| `Cannot prompt because user interactivity has been disabled` | 为防挂起设了 `credential.interactive=false`，把凭据读取也禁掉了 | 需要认证时不要禁用交互；配合 `credential.helper manager` |
| `couldn't create signal pipe, Win32 error 5`（`sh.exe`/`true.exe`） | git 会拉起 **MSYS 的 sh** 来执行编辑器，而受限沙箱禁止命名管道 | 避免任何会启动编辑器的 git 操作：用 `commit -m`；冲突解完后 `git commit -m` + `git reset --hard <sha>` 收尾 |
| `fatal: not a git repository` | 不在仓库目录内 | `cd` 到含 `.git` 的目录 |
| 要求密码但 PAT 被拒 | 用了账号密码，或 PAT 缺 `Contents` 权限 | 重新生成 token，勾选目标仓库写权限 |
| `Authentication failed` 而 PAT 正确 | 凭据管理器缓存了旧密码 | Windows 凭据管理器删除 `git:https://github.com` 后重试 |
| 中文文件名显示为 `\xxx` | 未关闭 quotepath | `git config core.quotepath false` |
| 推送被拒 `non-fast-forward` | 远程有本地没有的提交（例如建仓库时勾了 README） | `git fetch` 后整合历史（rebase/merge）再推；**不要**直接强推 |
| 运行 `.ps1` 报"禁止运行脚本" | 执行策略为 Restricted | 用 `.cmd` 启动器，或 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` |
| 中文 `.ps1` 报 `Unexpected token` | 文件无 BOM，PS 5.1 按 ANSI 解析 | 另存为 **UTF-8 with BOM** |
| 误提交了不该公开的内容 | — | 立即删除并提交；同时视为已泄露（历史仍可查），必要时用 `git filter-repo` 清理 |

## 建议的进阶用法

- **每日自动提交**：任务计划程序每天 22:30 执行 `git add . ; git commit -m "log(daily): auto" ; git push`（无改动时提交失败属正常）
- **大文件注意**：串口日志、固件、镜像别直接进 Git（100 MB 限制），放 `assets/` 只存文本片段与截图
- **在线检索**：GitHub 仓库内按 `/` 可直接搜关键字，日志多了以后非常好用

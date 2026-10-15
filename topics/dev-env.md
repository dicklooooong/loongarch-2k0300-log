---
topic: 开发环境与版本管理
started: 2026-10-16
status: 进行中
sdk: _待填_
toolchain: _待填_
tags: [环境搭建, 工具链, 版本管理]
---

# 专题：开发环境与版本管理

> 这是一份**已填好的示例**，展示专题笔记如何随日志逐步积累。内容全部来自真实排查过程。

## 一、为什么需要它（动机与用途）

- 触发场景：需要一套能长期运行的记录环境，把 2K0300 的学习过程纳入版本管理，随时回溯
- 掌握后能做什么：换机器时 10 分钟内重建开发环境；每一条实验结论都能对应到明确的版本组合
- 不做会怎样：结论散落在聊天记录和临时文件里，换台电脑就等于从零开始

## 二、硬件与版本事实（先固定变量，再谈结论）

| 项目 | 值 |
| --- | --- |
| 芯片 / 板卡 | 2K0300 / 久久派 |
| SDK / 内核版本 | _待填_ |
| 工具链版本 | _待填_ |
| 相关外设与地址 / 引脚 | 不涉及 |
| 参考文档与章节 | Git 官方文档、GitHub Docs（PAT / SSH 配置） |
| 主机环境 | Windows，工作目录 `E:\deepseek\第一个工作区`，PowerShell 5.1（Desktop 版） |

## 三、地图（先搭骨架，再填肉）

| 子模块 | 掌握程度 | 备注 |
| --- | --- | --- |
| 环境事实核查（有什么、在哪、什么版本） | 会用 | 已形成固定检查命令，见下 |
| 版本管理（Git） | 未开始 | 本机尚未安装，是当前唯一阻塞项 |
| 远端授权（PAT / SSH） | 了解 | 两条路径均已写清步骤，待实机验证 |
| 日志与目录约定 | 会用 | 见仓库 `README.md` |
| 交叉工具链接入 | 未开始 | 依赖 Git 装好后一并做 |

## 四、核心概念

### 概念 1：先确认环境事实，再设计方案

- **一句话定义**：动手前先用命令确认"本机到底有什么"，而不是假设。
- **为什么存在 / 解决什么问题**：避免把时间花在错误方向的排错上（以为"没配 PATH"，其实"根本没装"）。
- **和相邻概念的区别**：不同于"照教程走一遍"，它先确定起点，因此教程跑不通时能立刻定位差异。
- **最小可复现验证**：

```powershell
(Get-Command git -ErrorAction SilentlyContinue).Source      # 空 = 未安装或不在 PATH
Test-Path "C:\Program Files\Git\cmd\git.exe"                # False = 确实没装
(Get-Command winget -ErrorAction SilentlyContinue).Source   # 有路径不代表可用，见踩坑清单
```

### 概念 2：报错要区分"工具没装"和"环境不允许"

- **一句话定义**：同一条命令失败，原因可能在工具本身，也可能在操作系统/网络策略层。
- **为什么存在 / 解决什么问题**：混在一起会导致反复重装、白折腾。
- **最小可复现验证**：同一个 TLS 失败在多台主机上复现 ⇒ 判定为环境策略问题，而非目标站点问题。
- **证据**：`https://www.bing.com`、`https://github.com` 等**所有** HTTPS 请求均返回
  `schannel: AcquireCredentialsHandle failed: SEC_E_NO_CREDENTIALS` ⇒ 与本机 TLS 凭据/出网策略有关，不是 GitHub 的问题。

## 五、实践记录（按时间倒序追加）

### 2026-10-16 环境核查，确认阻塞项

- 环境：Windows，PowerShell 5.1
- 操作与命令：逐项检查 Git、GitHub CLI、winget 的存在性与可用性；测试多站点 HTTPS
- 现象：
  - `git`、`gh` 均不存在，常见安装路径全部为 False
  - `winget.exe` 存在但为 **0 字节**，执行无任何输出、退出码 1
  - 所有 HTTPS 请求失败：`schannel: SEC_E_NO_CREDENTIALS (0x8009030e)`
- 结论：
  1. 当前环境**无法安装 Git**（winget 不可用、无法下载安装包）
  2. 即使装上 Git，**当前 shell 也无法访问 GitHub**（TLS 层被阻断）
  3. 因此推送必须在**普通终端**里由本人执行 → 已提供 `init-and-push.cmd`
- 证据：`logs/2026/10/2026-10-16.md`

## 六、踩坑清单（越用越长，排错先看这里）

| 现象（原文关键词） | 原因 | 解决 | 适用版本 |
| --- | --- | --- | --- |
| `无法将"git"项识别为 cmdlet` | 未安装，或装了但当前终端沿用旧 PATH | 用 `Test-Path` 区分两种情况；装完**新开终端** | Windows PS 5.1 |
| `winget` 无输出、退出码 1 | `winget.exe` 是 0 字节应用执行别名，从非交互进程调用无法启动 | 改从 <https://git-scm.com/download/win> 下载安装包 | Windows 11 |
| `schannel: SEC_E_NO_CREDENTIALS (0x8009030e)` | shell 进程的 TLS 出网被环境策略阻断（非站点问题） | 在普通（非沙箱）终端中执行下载与推送 | Windows PS 5.1 / curl 8.x |
| 运行 `.ps1` 报"禁止运行脚本" | 默认执行策略为 Restricted | 用 `.cmd` 启动器（已内置 `-ExecutionPolicy Bypass`），或 `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` | Windows PS 5.1 |
| 中文 `.ps1` 报 `Unexpected token` | 文件无 BOM，PS 5.1 按 ANSI 解析 | 脚本另存为 **UTF-8 with BOM** | Windows PS 5.1 |
| `.cmd` 里中文注释被当成命令执行 | cmd 按 ANSI 读取，UTF-8 中文乱码破坏行首关键字 | `.cmd` 注释只用 ASCII | Windows cmd |

## 七、参考资料

| 来源 | 类型 | 版本 / 页码 | 评价 |
| --- | --- | --- | --- |
| Git for Windows 下载页 | 官方 | 最新 | 有用（winget 不可用时的唯一路径） |
| GitHub Docs：Personal access token | 官方文档 | — | 有用（明确 PAT 需 Contents 写权限） |
| GitHub Docs：SSH 连接配置 | 官方文档 | — | 有用 |
| `about_Execution_Policies` | 官方文档 | PS 5.1 | 有用 |

## 八、复述检验（能讲清才算学会）

我能不查资料讲清：为什么"命令找不到"要分两种原因排查；为什么同一个 TLS 报错在所有
站点上都出现时，应怀疑环境而不是站点；以及 `.ps1` 的 BOM、`.cmd` 的 ANSI 这两个
"看不见的编码坑"分别在什么条件下咬人。

## 九、下一步

- [ ] 在普通终端安装 Git for Windows，`git --version` 验证
- [ ] 运行 `init-and-push.cmd` 完成首次推送
- [ ] 推送成功后，把「远端授权」一行的掌握程度更新为"会用"，并回填本文件第二节的版本事实
- [ ] 接入 2K0300 交叉工具链后，在本文件新增一节记录版本与验证命令

---
topic: 开发环境与版本管理
started: 2026-10-16
status: 进行中
sdk: LoongOS（内核 4.19.190+）
toolchain: loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6
tags: [环境搭建, 工具链, 版本管理]
---

# 专题：开发环境与版本管理

> 这是**首个专题**，记录本仓库自身的环境搭建过程（内容全部来自真实排查）。
> 可参照它的写法：先把版本事实固定下来，再写结论；每条坑都带上"适用版本"。

## 一、为什么需要它（动机与用途）

- 触发场景：需要一套能长期运行的记录环境，把 2K0300 的学习过程纳入版本管理，随时回溯
- 掌握后能做什么：换机器时 10 分钟内重建开发环境；每一条实验结论都能对应到明确的版本组合
- 不做会怎样：结论散落在聊天记录和临时文件里，换台电脑就等于从零开始

## 二、硬件与版本事实（先固定变量，再谈结论）

| 项目 | 值 |
| --- | --- |
| 芯片 / 板卡 | 2K0300 / 久久派 |
| SDK / 内核版本 | 板卡 LoongOS，内核 `4.19.190+`；开源库 `LS2K0300_Library`（master 分支，2026-03-31 clone） |
| 工具链版本 | `loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6`（gcc 8.3.0 / 20241115），装在虚拟机 `/opt/ls_2k0300_env/` |
| 相关外设与地址 / 引脚 | 板卡 eth0 = `192.168.137.140`（MAC `64:48:48:48:48:60`）；板卡 SSH = **Dropbear 2020.81**（只支持老式 scp，故用 `scp -O`）；OpenCV 4.10 交叉编译版（51 MB，板卡 `/home/root/opencv_4_10_build`） |
| 参考文档与章节 | 《逐飞科技-龙芯久久派》第 7~10 页（工具链与 OpenCV 部署）、第 13~16 页（编译开源库） |
| 主机环境 | Windows，工作目录 `E:\deepseek\第一个工作区`，PowerShell 5.1；VMware 虚拟机 **Ubuntu 24.04.3**（用户 `seekfree`），8 vCPU；串口 `COM4 / 115200 / 8N1` |

## 三、地图（先搭骨架，再填肉）

| 子模块 | 掌握程度 | 备注 |
| --- | --- | --- |
| 环境事实核查（有什么、在哪、什么版本） | 会用 | 已形成固定检查命令，见下 |
| 版本管理（Git） | 会用 | Git 2.55.0 已装（winget 安装），首个提交已推送 |
| 远端授权（PAT / SSH） | 会用 | 实测：完整权限下 GCM 直接复用 Windows 凭据管理器中的凭据，未手输 PAT |
| 日志与目录约定 | 会用 | 见仓库 `README.md` |
| 交叉工具链接入 | 会用 | rc1.6 已接入，虚拟机内编译出 ELF64 LoongArch（2026-10-17） |
| 板卡接入与文件上传 | 会用 | 虚拟机 → 板卡免密 scp；`./build.sh` 一键"编译+上传"；实机重启后已验证 |

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

### 2026-10-17 接入工具链 + 打通"虚拟机 → 板卡"上传链路

- 环境：Ubuntu 24.04.3 虚拟机（`seekfree`）+ 久久派板卡（LoongOS 4.19.190+），板卡网口接主机「以太网」（ICS）
- 操作与命令：

```bash
# ① 文档 15/16/20 页的工具链导出（必须粘成一整行，PDF 里是折行的）
export PATH=/opt/ls_2k0300_env/loongson-gnu-toolchain-8.3-x86_64-loongarch64-linux-gnu-rc1.6/bin:$PATH
which loongarch64-linux-gnu-gcc && loongarch64-linux-gnu-gcc -dumpmachine   # → loongarch64-linux-gnu

# ② 正确的工程路径（文档第 14 页少了一层 LS2K300_Library）
cd ~/LS2K0300_Library/LS2K300_Library/Seekfree_LS2K0300_Opensource_Library/project/user
./build.sh        # 清理 out/ → cmake → make -j8 → scp 上传，全程免密
```

- 现象与结论：
  - **文档没错**：`...-rc1.6` 路径真实存在（gcc 8.3.0 / 20241115）；`ls /opt` 里看到的 `loongson-...-rc1.3-1` 是解压位置不同的**另一份旧工具链**，与文档不冲突
  - 虚拟机连不上板卡的根因是**网段撞车**：VMnet8(NAT) 与 ICS 网口都是 `192.168.137.0/24`，但属于两个二层网络 → 虚拟机判定"同网段"后直接在 VMnet8 里 ARP，永远问不到。解决：给虚拟机加第二块网卡（桥接到「以太网」）并配 `/32` + 精确路由：

```bash
# 第二块网卡 ens37（桥接）：只给 /32，避免与 NAT 网段抢 on-link 路由
sudo nmcli con add type ethernet ifname ens37 con-name board-link \
     ipv4.method manual ipv4.addresses 192.168.137.150/32 ipv4.never-default yes \
     ipv4.routes "192.168.137.1/32,192.168.137.140/32" ipv6.method disabled
```

  - 板卡 `eth0` 开机拿不到 IPv4（`/etc/rc.local` 里原有 `udhcpc -i eth0 &`，但 **Windows ICS 的 DHCP 不应答**，虚拟机 DHCP 也超时）→ 在板卡 `/etc/rc.local` 里改成静态 IP（原文件备份 `/etc/rc.local.bak-dsh`）
  - 免密：虚拟机 `~/.ssh/id_rsa.pub` 写入板卡 `/root/.ssh/authorized_keys`；板卡 host key 用 `ssh-keyscan` 预信任（否则第一次会卡在 yes/no）
  - 板卡跑不起来的最后一环：`libopencv_*.so.410` 缺失。这块 rootfs **没有 `ldconfig`、也没有 `/etc/ld.so.conf.d`**，所以文档第 10 页那步做不了；改用**程序自带 RPATH 的软链接**（见下）
  - **真机重启后复查通过**：IP、免密、OpenCV、`./project`、`./build.sh` 全部自动就位

```bash
# 板卡侧：OpenCV 运行时（51MB，实测传输 6 秒；tar 走 ssh 保留软链接）
tar -C /opt/ls_2k0300_env -cf - opencv_4_10_build | ssh root@192.168.137.140 'tar -C /home/root -xf -'
# 关键：工程编译时记录的 RPATH 就是 /opt/ls_2k0300_env/opencv_4_10_build/lib，做成软链接即可
ssh root@192.168.137.140 'mkdir -p /opt/ls_2k0300_env && \
  ln -sfn /home/root/opencv_4_10_build /opt/ls_2k0300_env/opencv_4_10_build'
```

- 证据：`logs/2026/10/2026-10-17.md`、`assets/2026-10-17-build-upload-log.txt`、`assets/2026-10-17-net-and-reboot-check.txt`

### 2026-10-16（同日后续）打通首次推送

- 环境：同一台 Windows 主机，改用完整权限的 shell
- 操作与命令：
  1. `winget install --id Git.Git -e --source winget` → 装上 **Git 2.55.0.5**
  2. 用 GitHub API 取账号 id，配置提交身份为 `id+username@users.noreply.github.com`
  3. `git init` → `git add` → `git commit` → `git remote add origin`
  4. `git ls-remote origin` → 发现远程已有 `Initial commit`，于是 `git fetch` + 整合历史
  5. 解决 `README.md` 冲突（保留自己版本，补入板卡名「久久派」）
  6. `git push -u origin main`
- 现象与结论：
  - **同一批命令在受限权限下全部失败、在完整权限下全部成功** ⇒ 之前的"无法安装/无法出网"只对受限模式成立
  - TLS 报错从 `SEC_E_NO_CREDENTIALS` 变为 `CRYPT_E_NO_REVOCATION_CHECK` ⇒ 前者是拿不到凭据，后者是拿到凭据后卡在吊销检查，用 `http.schannelCheckRevoke=false` 解决
  - `git rebase --continue` 报 `couldn't create signal pipe, Win32 error 5` ⇒ git 需要拉起 MSYS `sh.exe` 执行编辑器，而沙箱禁止命名管道；改用 `git commit -m` + `git reset --hard <sha>` 收尾即可
  - 推送成功：`e92fa3c..5554d49  main -> main`，远程与本地 `main` 完全一致
- 证据：`logs/2026/10/2026-10-16.md`

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
- 后续更正（同日）：换到完整权限后，winget 与 HTTPS 均恢复正常，上述第 1、2 条**只对受限模式成立**。
  教训：结论必须写清"在什么权限/环境下成立"，否则会误导未来的自己。
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
| `CRYPT_E_NO_REVOCATION_CHECK (0x80092012)` | 拿到凭据后卡在证书吊销检查（查不到 OCSP/CRL） | `git config http.schannelCheckRevoke false`；curl 用 `--ssl-no-revoke` | Git 2.55 / curl 8.x |
| `fatal error - couldn't create signal pipe, Win32 error 5` | git 拉起 MSYS `sh.exe`/`true.exe` 执行编辑器，沙箱禁止命名管道 | 避免任何会启动编辑器的 git 操作：用 `commit -m`，冲突解完后 `git commit -m` + `git reset --hard <sha>` 收尾 | Git for Windows 在受限沙箱内 |
| `Cannot prompt because user interactivity has been disabled` | 为了防挂起设了 `credential.interactive=false`，反而禁掉了凭据读取 | 需要认证时不要禁用交互；确认 `credential.helper manager` 可读已存凭据 | Git 2.55 |
| 推送被拒 `non-fast-forward` | 建仓库时勾了 README，远程已有提交 | 先 `git fetch`，再整合历史（rebase/merge）后推送；**不要**直接强推 | Git 2.55 |
| `bash: <半截路径>: 没有那个文件或目录`，紧接着 `ls: 未找到命令` | 从 PDF 复制**折行的长命令**，中间的换行被当成回车：第一行把 `PATH` 直接赋值成半截路径（没有接 `:$PATH`），第二行被当作命令名执行 | 复制前先粘到编辑器拼成一行；PATH 被覆盖时用 `export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin` 救回 | Ubuntu 24.04 bash |
| 虚拟机 ping 板卡 `Destination Host Unreachable` / `ARP FAILED` | 两个二层网络用了同一网段（VMnet8 NAT 与 Windows ICS 都是 `192.168.137.0/24`），内核判定"同网段"后只在 VMnet8 里 ARP | 加第二块桥接网卡，用 `/32` 地址 + 目标 `/32` 精确路由；排查时先看 `ip neigh` | Ubuntu 24.04 / VMware 17 |
| 板卡开机 `eth0` 只有 `inet6 fe80::…`，没有 IPv4 | ICS 的 DHCP 不应答（`udhcpc -i eth0` 拿不到租约），虚拟机 DHCP 同样超时 | 板卡 `/etc/rc.local` 里改成静态 IP + 默认网关（幂等写法：`route add … 2>/dev/null \|\| true`） | LoongOS 4.19.190+ |
| `command -v udhcpc` 说没有，其实存在 | 非交互 SSH 会话的 `PATH` 只有 `/usr/bin:/bin`，看不到 `/sbin`、`/usr/sbin` | 先 `export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin`，或用绝对路径 | LoongOS（Dropbear ssh） |
| `error while loading shared libraries: libopencv_gapi.so.410` | 板卡没有 OpenCV 运行时；且程序记录的 `RPATH` 是交叉编译路径 `/opt/ls_2k0300_env/opencv_4_10_build/lib` | 传 `opencv_4_10_build` 到板卡 `/home/root/`，再把 RPATH 路径做成软链接（板卡无 `ldconfig`） | OpenCV 4.10 / LoongOS |
| `sh: /etc/ld.so.conf.d/opencv.conf: No such file or directory`，且没有 `ldconfig` | 该 rootfs 未装 ldconfig、也没有 `ld.so.conf.d` 目录（文档第 10 页假设它存在） | 不依赖 ldconfig：用 RPATH 软链接，或运行时 `LD_LIBRARY_PATH=` 指定 | LoongOS 4.19.190+ |

## 七、参考资料

| 来源 | 类型 | 版本 / 页码 | 评价 |
| --- | --- | --- | --- |
| Git for Windows 下载页 | 官方 | 最新 | 有用（winget 不可用时的唯一路径） |
| GitHub Docs：Personal access token | 官方文档 | — | 有用（明确 PAT 需 Contents 写权限） |
| GitHub Docs：SSH 连接配置 | 官方文档 | — | 有用 |
| `about_Execution_Policies` | 官方文档 | PS 5.1 | 有用 |

## 八、复述检验（能讲清才算学会）

我能不查资料讲清：为什么"命令找不到"要分两种原因排查；为什么**同一个操作在不同权限层级下
表现完全不同**（这是本次最大的教训）；`SEC_E_NO_CREDENTIALS` 与 `CRYPT_E_NO_REVOCATION_CHECK`
分别卡在 TLS 握手的哪一步、各怎么绕；以及 `.ps1` 的 BOM、`.cmd` 的 ANSI、MSYS 的命名管道
这三类"看不见的环境坑"分别在什么条件下咬人。

## 九、下一步

- [x] 安装 Git for Windows，`git --version` 验证 → Git 2.55.0.5
- [x] 完成首次推送 → `e92fa3c..5554d49  main -> main`
- [x] 把「远端授权」一行的掌握程度更新为"会用"，并回填本文件第二节的版本事实
- [x] 接入 2K0300（久久派）交叉工具链 → `...-rc1.6`（gcc 8.3.0），并跑通文档 13~16 页的编译
- [x] 板子上电、串口可用（COM4/115200）、虚拟机 → 板卡免密上传打通（`./build.sh` 一键完成）
- [ ] 查清 Windows ICS 的 DHCP 为什么不应答（UDP 67/68），争取让板卡与虚拟机都改回自动获取
- [ ] 板卡外网：清掉那两条没有网关的默认路由，或关掉 connman 对 eth0 的管理

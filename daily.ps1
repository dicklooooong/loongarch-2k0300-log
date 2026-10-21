<#
.SYNOPSIS
    每天一条命令：打开今天的日志，写完关闭后自动提交并推送到 GitHub。
.DESCRIPTION
    1) 按当天日期创建 logs\年\月\YYYY-MM-DD.md（已存在则直接打开，不覆盖）
    2) 用编辑器打开并等待你保存、关闭
    3) 有改动才提交（信息为 log(daily): 日期 主题），然后 git push
.EXAMPLE
    .\daily.ps1
    .\daily.ps1 "串口无输出排查"
#>
[CmdletBinding()]
param(
    [string]$Topic,
    # 默认用记事本：最简单、不会认错文件。想用 VS Code 就加 -Editor code
    [ValidateSet('notepad', 'code')]
    [string]$Editor = 'notepad'
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

function Get-GitPath {
    $git = (Get-Command git -ErrorAction SilentlyContinue).Source
    if ($git) { return $git }
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
    )
    return ($candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1)
}

Write-Host ''
Write-Host '========== 每天记录 ==========' -ForegroundColor Cyan

# ---------- 1. 准备今天的文件 ----------
$today = Get-Date
# 凌晨 6 点之前算作前一天（熬夜写的记录归到前一晚）
if ($today.Hour -lt 6) {
    $today = $today.AddDays(-1)
    Write-Host ("[i] 现在 " + (Get-Date).ToString('HH:mm') + "，按规则归到前一天：" + $today.ToString('yyyy-MM-dd')) -ForegroundColor DarkGray
}
$relDir = Join-Path 'logs' (Join-Path $today.Year ('{0:D2}' -f $today.Month))
$absDir = Join-Path $PSScriptRoot $relDir
$file = Join-Path $absDir ($today.ToString('yyyy-MM-dd') + '.md')
$template = Join-Path $PSScriptRoot 'templates\daily.md'

New-Item -ItemType Directory -Force -Path $absDir | Out-Null

if (Test-Path $file) {
    Write-Host ("[1/3] 今天的日志已存在，直接打开：" + $today.ToString('yyyy-MM-dd') + '.md') -ForegroundColor Yellow
} else {
    $weekday = @('星期日','星期一','星期二','星期三','星期四','星期五','星期六')[[int]$today.DayOfWeek]
    if (Test-Path $template) {
        $content = Get-Content -Raw -Encoding UTF8 $template
        $content = $content -replace 'YYYY-MM-DD', $today.ToString('yyyy-MM-dd')
        $content = $content -replace '(?m)^weekday:.*$', "weekday: $weekday"
        Set-Content -Path $file -Value $content -Encoding UTF8
    } else {
        New-Item -ItemType File -Path $file | Out-Null
    }
    Write-Host ("[1/3] 已创建今天的日志：" + $today.ToString('yyyy-MM-dd') + '.md') -ForegroundColor Green
}

# ---------- 2. 打开编辑器并等待关闭 ----------
Write-Host '[2/3] 正在打开编辑器……写完保存后关闭窗口，就会自动进入下一步。' -ForegroundColor Cyan
Write-Host '      只填四格就够：做了什么 / 现象 vs 预期 / 卡点 / 明天第一步' -ForegroundColor DarkGray

$code = $null
if ($Editor -eq 'code') {
    $code = (Get-Command code -ErrorAction SilentlyContinue).Source
}
if ($code) {
    Write-Host '      用 VS Code 打开（关闭该标签页即表示写完）' -ForegroundColor DarkGray
    & $code --wait $file | Out-Null
} else {
    Write-Host '      用记事本打开（保存后关闭记事本即表示写完）' -ForegroundColor DarkGray
    Start-Process -FilePath 'notepad.exe' -ArgumentList ('"' + $file + '"') -Wait
}
Write-Host '[2/3] 编辑器已关闭。' -ForegroundColor Green

# ---------- 3. 提交并推送 ----------
$git = Get-GitPath
if (-not $git) {
    Write-Host '[3/3] 未找到 git，无法发布。请先安装 Git for Windows：https://git-scm.com/download/win' -ForegroundColor Red
    exit 1
}

$dirty = & $git status --porcelain
if (-not $dirty) {
    Write-Host '[3/3] 内容没有变化，不需要发布。' -ForegroundColor Yellow
    exit 0
}

if (-not $Topic) {
    $Topic = Read-Host '这次记录的简短主题（直接回车用 daily update）'
}
if (-not $Topic) { $Topic = 'daily update' }

$message = "log(daily): " + $today.ToString('yyyy-MM-dd') + " $Topic"
$msgFile = Join-Path $env:TEMP ("log-commit-" + [guid]::NewGuid().ToString('N') + ".txt")
[System.IO.File]::WriteAllText($msgFile, $message, (New-Object System.Text.UTF8Encoding($false)))
try {
    & $git add -A
    & $git commit -F $msgFile | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[3/3] 提交失败，已中止（没有推送）。' -ForegroundColor Red
        exit 1
    }
} finally {
    Remove-Item $msgFile -Force -ErrorAction SilentlyContinue
}

Write-Host '[3/3] 正在推送到 GitHub...' -ForegroundColor Cyan
& $git push
if ($LASTEXITCODE -ne 0) {
    Write-Host '推送失败。常见原因：网络不通，或远程有新提交 —— 先执行 git pull --rebase 再重试。' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '完成！今天的记录已经上传。' -ForegroundColor Green
Write-Host '在线查看：https://github.com/dicklooooong/loongarch-2k0300-log' -ForegroundColor Green

<#
.SYNOPSIS
    把改动提交并推送到 GitHub（一键发布）。
.DESCRIPTION
    等价于 git add -A → git commit -m "log(daily): 日期 主题" → git push。
    - 提交信息以 UTF-8 写入临时文件再提交，中文不乱码，也不会弹出编辑器
    - 没有改动时不产生空提交
    - 即使当前终端 PATH 里还没有 git（刚装完 Git 常见），也会去常见安装路径找
.EXAMPLE
    .\publish.ps1 "串口无输出排查"
    .\publish.ps1            # 交互式输入主题
#>
[CmdletBinding()]
param(
    [string]$Topic
)

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# 解析 git：先在 PATH 里找，再回退到常见安装路径
$git = (Get-Command git -ErrorAction SilentlyContinue).Source
if (-not $git) {
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Git\cmd\git.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Git\cmd\git.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Git\cmd\git.exe')
    )
    $git = $candidates | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
}
if (-not $git) {
    Write-Host '未找到 git，请先安装 Git for Windows：https://git-scm.com/download/win' -ForegroundColor Red
    exit 1
}

# 有改动才提交
$dirty = & $git status --porcelain
if (-not $dirty) {
    Write-Host '没有需要提交的改动。' -ForegroundColor Yellow
} else {
    if (-not $Topic) {
        $Topic = Read-Host '这次记录的简短主题（直接回车用 daily update）'
    }
    if (-not $Topic) { $Topic = 'daily update' }

    $date = (Get-Date).ToString('yyyy-MM-dd')
    $message = "log(daily): $date $Topic"

    # 用 -F + UTF-8(无 BOM) 提交，中文不会乱码，也不会触发编辑器
    $msgFile = Join-Path $env:TEMP ("log-commit-" + [guid]::NewGuid().ToString('N') + ".txt")
    [System.IO.File]::WriteAllText($msgFile, $message, (New-Object System.Text.UTF8Encoding($false)))

    try {
        & $git add -A
        & $git commit -F $msgFile | Out-Host
        if ($LASTEXITCODE -ne 0) {
            Write-Host '提交失败，已中止（没有推送）。' -ForegroundColor Red
            exit 1
        }
    } finally {
        Remove-Item $msgFile -Force -ErrorAction SilentlyContinue
    }
    Write-Host ("已提交：" + $message) -ForegroundColor Green
}

Write-Host '正在推送到 GitHub...' -ForegroundColor Cyan
& $git push
if ($LASTEXITCODE -ne 0) {
    Write-Host '推送失败。常见原因：网络不通，或远程有新提交 —— 先执行 git pull --rebase 再重试。' -ForegroundColor Red
    exit 1
}
Write-Host '完成，已同步到 GitHub。' -ForegroundColor Green

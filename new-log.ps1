<#
.SYNOPSIS
    为今天创建学习日志文件（若已存在则直接打开，不覆盖）。
.EXAMPLE
    .\new-log.ps1
    .\new-log.ps1 -Date 2026-10-16
#>
[CmdletBinding()]
param(
    [datetime]$Date
)

$ErrorActionPreference = 'Stop'

# 凌晨 6 点之前算作前一天（熬夜写的记录归到前一晚）
if (-not $PSBoundParameters.ContainsKey('Date')) {
    $Date = Get-Date
    if ($Date.Hour -lt 6) {
        $Date = $Date.AddDays(-1)
        Write-Host ("[i] 现在 " + (Get-Date).ToString('HH:mm') + "，按规则归到前一天：" + $Date.ToString('yyyy-MM-dd')) -ForegroundColor DarkGray
    }
}
$root = $PSScriptRoot

$relDir  = Join-Path 'logs' (Join-Path $Date.Year ('{0:D2}' -f $Date.Month))
$absDir  = Join-Path $root $relDir
$fileName = $Date.ToString('yyyy-MM-dd') + '.md'
$absFile  = Join-Path $absDir $fileName
$template = Join-Path $root 'templates\daily.md'

New-Item -ItemType Directory -Force -Path $absDir | Out-Null

if (Test-Path $absFile) {
    Write-Host "已存在，直接打开：$relDir\$fileName" -ForegroundColor Yellow
} else {
    if (Test-Path $template) {
        $content = Get-Content -Raw -Encoding UTF8 $template
        $content = $content -replace 'YYYY-MM-DD', $Date.ToString('yyyy-MM-dd')
        $weekday = @('星期日','星期一','星期二','星期三','星期四','星期五','星期六')[[int]$Date.DayOfWeek]
        $content = $content -replace '(?m)^weekday:.*$', "weekday: $weekday"
        Set-Content -Path $absFile -Value $content -Encoding UTF8
    } else {
        New-Item -ItemType File -Path $absFile | Out-Null
    }
    Write-Host "已创建：$relDir\$fileName" -ForegroundColor Green
}

# 有 VS Code 就用它打开，否则用记事本
if (Get-Command code -ErrorAction SilentlyContinue) { code $absFile } else { Start-Process notepad.exe $absFile }

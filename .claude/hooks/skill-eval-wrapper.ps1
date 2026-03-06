# Skill Eval Wrapper - Windows
# Cross-platform hook execution wrapper for skill-forced-eval

$ErrorActionPreference = "Stop"

# === 配置 ===
$LogFile = ".claude\logs\skill-eval.log"
$Debug = if ($env:CLAUDE_HOOK_DEBUG) { [int]$env:CLAUDE_HOOK_DEBUG } else { 0 }

# === 日志函数 ===
function Log-Message {
    param([string]$Level, [string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMsg = "[$timestamp] [$Level] $Message"

    if ($Debug -eq 1) {
        Write-Host $logMsg -ForegroundColor DarkGray
    }

    # 写入日志文件
    try {
        $logDir = Split-Path -Parent $LogFile
        if (-not (Test-Path $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        Add-Content -Path $LogFile -Value $logMsg -ErrorAction SilentlyContinue
    } catch {
        # 静默失败
    }
}

Log-Message "INFO" "=== skill-eval-wrapper.ps1 started ==="
Log-Message "INFO" "USER_PROMPT: $($env:USER_PROMPT -replace '\r?\n',' ')"

# === 环境变量逃生通道 ===
if ($env:CLAUDE_NO_HOOKS -eq "1" -or $env:CLAUDE_SKIP_SKILL_EVAL -eq "1") {
    Log-Message "INFO" "Hook disabled via environment variable"
    exit 0
}

# === 斜杠命令逃生通道 ===
$userPrompt = $env:USER_PROMPT -replace '^\s*',''
if ($userPrompt -match '^/') {
    Log-Message "INFO" "Command detected, skipping eval"
    exit 0
}

# === 获取脚本目录 - 多重 fallback ===
$HookDir = if ($MyInvocation.MyCommand.Path) {
    Split-Path -Parent $MyInvocation.MyCommand.Path
} elseif ($PSScriptRoot) {
    $PSScriptRoot
} else {
    # Fallback to current directory
    (Get-Location).Path
}

# 转换为绝对路径
$HookDir = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($HookDir)
Log-Message "INFO" "Hook directory: $HookDir"

# === 检查 Node.js ===
try {
    $nodeVersion = & node --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Log-Message "INFO" "Node.js version: $nodeVersion"
    } else {
        Log-Message "ERROR" "Node.js not available (exit code: $LASTEXITCODE)"
        exit 0
    }
} catch {
    Log-Message "ERROR" "Node.js not found: $_"
    exit 0
}

# === 执行评估脚本 ===
# Try .cjs first (ES Module projects)
$CjsScript = Join-Path $HookDir "skill-forced-eval.cjs"
if (Test-Path $CjsScript) {
    Log-Message "INFO" "Executing: $CjsScript"
    & node $CjsScript 2>&1 | ForEach-Object {
        Log-Message "OUTPUT" $_
        Write-Host $_
    }
    $exitCode = $LASTEXITCODE
    Log-Message "INFO" "Exit code: $exitCode"
    exit $exitCode
}

# Fallback to .js (CommonJS projects)
$JsScript = Join-Path $HookDir "skill-forced-eval.js"
if (Test-Path $JsScript) {
    Log-Message "INFO" "Executing: $JsScript"
    & node $JsScript 2>&1 | ForEach-Object {
        Log-Message "OUTPUT" $_
        Write-Host $_
    }
    $exitCode = $LASTEXITCODE
    Log-Message "INFO" "Exit code: $exitCode"
    exit $exitCode
}

# No script found
Log-Message "WARN" "No skill-forced-eval script found in $HookDir"
exit 0

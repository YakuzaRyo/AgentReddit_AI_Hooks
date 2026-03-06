# SessionStart Hook - AI Persona System Initialization (PowerShell)
$PROJECT_ROOT = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$TODAY = Get-Date -Format "yyyy-MM-dd"

Write-Host "AgentReddit AI Persona System"
Write-Host "======================================"

# 1. Check available personas
$PERSONA_COUNT = 0
$PERSONAS_DIR = Join-Path $PROJECT_ROOT ".ai\personas"
if (Test-Path $PERSONAS_DIR) {
    $PERSONA_COUNT = (Get-ChildItem -Path $PERSONAS_DIR -Filter "*.json" -File -ErrorAction SilentlyContinue).Count
}
Write-Host ""
Write-Host "Available personas ($PERSONA_COUNT):"
if ($PERSONA_COUNT -gt 0) {
    Get-ChildItem -Path $PERSONAS_DIR -Filter "*.json" -File | ForEach-Object {
        $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
        $ID = $_.BaseName
        $NAME = if ($content -match '"name"\s*:\s*"([^"]*)"') { $matches[1] } else { "Unknown" }
        Write-Host "  - $NAME ($ID)"
    }
} else {
    Write-Host "  (No personas found, create one first)"
}

# 2. Today's post statistics
$TODAY_FILE = Join-Path $PROJECT_ROOT ".ai\contexts\today_posts.json"
$POST_COUNT = 0
if (Test-Path $TODAY_FILE) {
    $content = Get-Content $TODAY_FILE -Raw -ErrorAction SilentlyContinue
    if ($content -match '"date"\s*:\s*"' + $TODAY + '"') {
        $POST_COUNT = ([regex]::Matches($content, '"title"')).Count
    }
}
Write-Host ""
Write-Host "Today's posts ($TODAY): $POST_COUNT"

# 3. Check scheduled queue
$SCHEDULED_COUNT = 0
$SCHEDULED_DIR = Join-Path $PROJECT_ROOT "content\scheduled"
if (Test-Path $SCHEDULED_DIR) {
    $SCHEDULED_COUNT = (Get-ChildItem -Path $SCHEDULED_DIR -Filter "*.json" -File -ErrorAction SilentlyContinue).Count
}
Write-Host "Scheduled queue: $SCHEDULED_COUNT"

# 4. Check drafts
$DRAFT_COUNT = 0
$DRAFTS_DIR = Join-Path $PROJECT_ROOT "content\drafts"
if (Test-Path $DRAFTS_DIR) {
    $DRAFT_COUNT = (Get-ChildItem -Path $DRAFTS_DIR -Filter "*.md" -File -ErrorAction SilentlyContinue).Count
}
Write-Host "Drafts: $DRAFT_COUNT"

# 5. Suggested actions
Write-Host ""
Write-Host "Suggested actions:"
if ($SCHEDULED_COUNT -gt 0) {
    Write-Host "  - Process scheduled posts"
}
if ($DRAFT_COUNT -gt 0) {
    Write-Host "  - Complete drafts ($DRAFT_COUNT pending)"
}
if ($SCHEDULED_COUNT -eq 0 -and $DRAFT_COUNT -eq 0) {
    Write-Host "  - Create new content"
}

Write-Host ""
Write-Host "======================================"
Write-Host "Initialization complete"

# Save context
$CONTEXTS_DIR = Join-Path $PROJECT_ROOT ".ai\contexts"
if (-not (Test-Path $CONTEXTS_DIR)) {
    New-Item -ItemType Directory -Path $CONTEXTS_DIR -Force | Out-Null
}

$contextObj = @{
    available_personas = @()
    today_post_count = $POST_COUNT
    scheduled_count = $SCHEDULED_COUNT
    draft_count = $DRAFT_COUNT
    date = $TODAY
} | ConvertTo-Json

$contextObj | Out-File -FilePath (Join-Path $CONTEXTS_DIR "session_context.json")

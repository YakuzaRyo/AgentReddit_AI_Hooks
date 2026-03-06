# SessionStart Persona Prompt Loader
# Reads AI Persona system initialization prompt from external file

$promptFile = ".ai/prompts/persona_system_prompt.md"

if (Test-Path $promptFile) {
    $content = Get-Content $promptFile -Raw
    Write-Output $content
} else {
    Write-Output "Default prompt file not found. Please create .ai/prompts/persona_system_prompt.md"
}

# Instalador do Sentinela (auditoria de segurança) para Claude Code, Codex CLI,
# Gemini CLI e Cursor, no Windows/PowerShell.
#
# Uso rápido (instala tudo, global, pra usar em qualquer projeto seu):
#   irm https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.ps1 | iex
#
# Escolhendo só uma ferramenta (baixe o script primeiro pra passar parâmetros):
#   irm https://raw.githubusercontent.com/fonsecafns/sentinela/main/install.ps1 -OutFile install.ps1
#   .\install.ps1 -Claude
#   .\install.ps1 -Codex
#   .\install.ps1 -Gemini
#   .\install.ps1 -Cursor
#   .\install.ps1 -Project   (instala só no projeto atual, em vez de globalmente)
#
# SPDX-License-Identifier: MIT (veja LICENSE-MIT neste repositório)

param(
    [switch]$Claude,
    [switch]$Codex,
    [switch]$Gemini,
    [switch]$Cursor,
    [switch]$All,
    [switch]$Global,
    [switch]$Project
)

$ErrorActionPreference = "Stop"

$RepoUrl = "https://github.com/fonsecafns/sentinela.git"
$RepoZip = "https://github.com/fonsecafns/sentinela/archive/refs/heads/main.zip"

$InstallClaude = $false
$InstallCodex = $false
$InstallGemini = $false
$InstallCursor = $false
$AnyFlag = $false

if ($Claude) { $InstallClaude = $true; $AnyFlag = $true }
if ($Codex)  { $InstallCodex  = $true; $AnyFlag = $true }
if ($Gemini) { $InstallGemini = $true; $AnyFlag = $true }
if ($Cursor) { $InstallCursor = $true; $AnyFlag = $true }
if ($All)    { $InstallClaude = $true; $InstallCodex = $true; $InstallGemini = $true; $InstallCursor = $true; $AnyFlag = $true }
if (-not $AnyFlag) {
    $InstallClaude = $true; $InstallCodex = $true; $InstallGemini = $true; $InstallCursor = $true
}

$Scope = if ($Project) { "project" } else { "global" }

Write-Host "Sentinela: baixando o repositorio..."

$WorkDir = Join-Path ([System.IO.Path]::GetTempPath()) ("sentinela-install-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $WorkDir | Out-Null

try {
    $Src = Join-Path $WorkDir "sentinela"
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git clone --depth 1 --branch main $RepoUrl $Src *> $null
    } else {
        $ZipPath = Join-Path $WorkDir "sentinela.zip"
        Invoke-WebRequest -Uri $RepoZip -OutFile $ZipPath
        Expand-Archive -Path $ZipPath -DestinationPath $WorkDir
        $Extracted = Get-ChildItem -Path $WorkDir -Directory | Where-Object { $_.Name -like "sentinela-*" } | Select-Object -First 1
        Rename-Item -Path $Extracted.FullName -NewName "sentinela"
    }

    function Add-SentinelaBlock {
        param([string]$FilePath, [string]$Content)
        $dir = Split-Path -Parent $FilePath
        if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (-not (Test-Path $FilePath)) { New-Item -ItemType File -Path $FilePath | Out-Null }
        $existing = Get-Content -Path $FilePath -Raw -ErrorAction SilentlyContinue
        if ($existing -and $existing.Contains("<!-- sentinela:start -->")) {
            Write-Host "Ja existe uma secao do Sentinela em $FilePath, deixei como estava. Edite manualmente se quiser atualizar."
        } else {
            Add-Content -Path $FilePath -Value ""
            Add-Content -Path $FilePath -Value "<!-- sentinela:start -->"
            Add-Content -Path $FilePath -Value $Content
            Add-Content -Path $FilePath -Value "<!-- sentinela:end -->"
            Write-Host "Adicionado em $FilePath"
        }
    }

    if ($InstallClaude) {
        $target = if ($Scope -eq "global") { Join-Path $HOME ".claude\skills\sentinela" } else { ".\.claude\skills\sentinela" }
        New-Item -ItemType Directory -Path $target -Force | Out-Null
        Copy-Item -Path (Join-Path $Src "SKILL.md") -Destination (Join-Path $target "SKILL.md") -Force
        Copy-Item -Path (Join-Path $Src "references") -Destination (Join-Path $target "references") -Recurse -Force
        Write-Host "Claude Code: instalado em $target"
    }

    if ($InstallCodex) {
        $targetFile = if ($Scope -eq "global") { Join-Path $HOME ".codex\AGENTS.md" } else { ".\AGENTS.md" }
        $sharedDir = if ($Scope -eq "global") { Join-Path $HOME ".codex\.sentinela-shared" } else { ".\.sentinela-shared" }
        New-Item -ItemType Directory -Path $sharedDir -Force | Out-Null
        Copy-Item -Path (Join-Path $Src ".sentinela-shared\ferramentas-por-stack.md") -Destination (Join-Path $sharedDir "ferramentas-por-stack.md") -Force
        $content = Get-Content -Path (Join-Path $Src "AGENTS.md") -Raw
        Add-SentinelaBlock -FilePath $targetFile -Content $content
        Write-Host "Codex CLI: instalado em $targetFile (referencias em $sharedDir)"
    }

    if ($InstallGemini) {
        $targetFile = if ($Scope -eq "global") { Join-Path $HOME ".gemini\GEMINI.md" } else { ".\GEMINI.md" }
        $sharedDir = if ($Scope -eq "global") { Join-Path $HOME ".gemini\.sentinela-shared" } else { ".\.sentinela-shared" }
        New-Item -ItemType Directory -Path $sharedDir -Force | Out-Null
        Copy-Item -Path (Join-Path $Src ".sentinela-shared\ferramentas-por-stack.md") -Destination (Join-Path $sharedDir "ferramentas-por-stack.md") -Force
        $content = Get-Content -Path (Join-Path $Src "GEMINI.md") -Raw
        Add-SentinelaBlock -FilePath $targetFile -Content $content
        Write-Host "Gemini CLI: instalado em $targetFile (referencias em $sharedDir)"
    }

    if ($InstallCursor) {
        # O Cursor nao tem instalacao global por arquivo (regras globais ficam na
        # interface do Cursor), entao isso e sempre por projeto.
        $target = ".\.cursor\rules\sentinela.mdc"
        $sharedDir = ".\.sentinela-shared"
        New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
        New-Item -ItemType Directory -Path $sharedDir -Force | Out-Null
        Copy-Item -Path (Join-Path $Src ".cursor\rules\sentinela.mdc") -Destination $target -Force
        Copy-Item -Path (Join-Path $Src ".sentinela-shared\ferramentas-por-stack.md") -Destination (Join-Path $sharedDir "ferramentas-por-stack.md") -Force
        Write-Host "Cursor: instalado em $target (regra 'agent requested', so entra quando fizer sentido pro pedido)"
    }

    Write-Host ""
    Write-Host "Pronto. Peca 'roda o sentinela nesse projeto' (ou equivalente) na ferramenta instalada pra testar."
}
finally {
    Remove-Item -Path $WorkDir -Recurse -Force -ErrorAction SilentlyContinue
}

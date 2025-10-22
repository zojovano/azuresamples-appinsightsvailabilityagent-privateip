#Requires -Version 7.0

<#
.SYNOPSIS
    Local Docker build and run script for Azure Availability Agent

.DESCRIPTION
    This script helps build and run the Azure Availability Agent container locally.
    It supports building, running, stopping, and cleaning up Docker containers.

.PARAMETER Action
    The action to perform: Build, Run, BuildAndRun, Stop, Clean, Logs, or Shell

.PARAMETER Tag
    Docker image tag (default: latest)

.PARAMETER Port
    Local port to expose (default: 8080)

.PARAMETER ProbeUrls
    JSON array of URLs to probe (default: sample URLs)

.PARAMETER ProbeFrequency
    Cron expression for probe frequency (default: every 5 minutes)

.PARAMETER AppInsightsKey
    Application Insights connection string (optional for local testing)

.EXAMPLE
    .\build-and-run.ps1 -Action Build
    Build the Docker image

.EXAMPLE
    .\build-and-run.ps1 -Action Run
    Run the Docker container

.EXAMPLE
    .\build-and-run.ps1 -Action BuildAndRun
    Build and run the container

.EXAMPLE
    .\build-and-run.ps1 -Action Run -ProbeUrls '["https://www.microsoft.com"]'
    Run with custom probe URLs

#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('Build', 'Run', 'BuildAndRun', 'Stop', 'Clean', 'Logs', 'Shell', 'Status')]
    [string]$Action = 'BuildAndRun',

    [Parameter(Mandatory = $false)]
    [string]$Tag = 'latest',

    [Parameter(Mandatory = $false)]
    [int]$Port = 8080,

    [Parameter(Mandatory = $false)]
    [string]$ProbeUrls = '["https://www.microsoft.com", "https://www.azure.com", "https://github.com"]',

    [Parameter(Mandatory = $false)]
    [string]$ProbeFrequency = '0 */5 * * * *',

    [Parameter(Mandatory = $false)]
    [string]$AppInsightsKey = '',

    [Parameter(Mandatory = $false)]
    [int]$ProbeTimeout = 30,

    [Parameter(Mandatory = $false)]
    [string]$TestNamePrefix = 'Local-Test',

    [Parameter(Mandatory = $false)]
    [string]$TestLocation = 'Local-Docker'
)

# Configuration
$ImageName = "availabilityagent"
$ContainerName = "availabilityagent-local"
$AppPath = Join-Path $PSScriptRoot "app"
$DockerfilePath = Join-Path $AppPath "Dockerfile"

# Colors for output
$Colors = @{
    Success = 'Green'
    Error   = 'Red'
    Warning = 'Yellow'
    Info    = 'Cyan'
    Header  = 'Magenta'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [switch]$NoNewline
    )
    
    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $Color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color $Colors.Header
    Write-ColorOutput " $Message" -Color $Colors.Header
    Write-ColorOutput "═══════════════════════════════════════════════════════════════" -Color $Colors.Header
    Write-Host ""
}

function Test-DockerInstalled {
    try {
        $null = docker --version
        return $true
    }
    catch {
        Write-ColorOutput "ERROR: Docker is not installed or not in PATH" -Color $Colors.Error
        Write-ColorOutput "Please install Docker Desktop: https://www.docker.com/products/docker-desktop" -Color $Colors.Info
        return $false
    }
}

function Test-DockerRunning {
    try {
        $null = docker ps 2>&1
        return $true
    }
    catch {
        Write-ColorOutput "ERROR: Docker daemon is not running" -Color $Colors.Error
        Write-ColorOutput "Please start Docker Desktop" -Color $Colors.Info
        return $false
    }
}

function Build-DockerImage {
    Write-Header "Building Docker Image"
    
    Write-ColorOutput "Image: " -Color $Colors.Info -NoNewline
    Write-ColorOutput "$ImageName:$Tag" -Color $Colors.Success
    Write-ColorOutput "Dockerfile: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $DockerfilePath -Color $Colors.Success
    Write-Host ""

    if (-not (Test-Path $DockerfilePath)) {
        Write-ColorOutput "ERROR: Dockerfile not found at $DockerfilePath" -Color $Colors.Error
        return $false
    }

    Write-ColorOutput "Building image (this may take a few minutes)..." -Color $Colors.Info
    
    $buildArgs = @(
        "build",
        "-t", "$ImageName:$Tag",
        "-f", $DockerfilePath,
        $AppPath
    )

    $process = Start-Process -FilePath "docker" -ArgumentList $buildArgs -NoNewWindow -Wait -PassThru
    
    if ($process.ExitCode -eq 0) {
        Write-Host ""
        Write-ColorOutput "✓ Docker image built successfully!" -Color $Colors.Success
        return $true
    }
    else {
        Write-Host ""
        Write-ColorOutput "✗ Docker build failed with exit code: $($process.ExitCode)" -Color $Colors.Error
        return $false
    }
}

function Stop-ExistingContainer {
    $existing = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($existing -eq $ContainerName) {
        Write-ColorOutput "Stopping existing container..." -Color $Colors.Warning
        docker stop $ContainerName 2>&1 | Out-Null
        docker rm $ContainerName 2>&1 | Out-Null
        Write-ColorOutput "✓ Existing container removed" -Color $Colors.Success
    }
}

function Start-DockerContainer {
    Write-Header "Starting Docker Container"
    
    Stop-ExistingContainer
    
    Write-ColorOutput "Container: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $ContainerName -Color $Colors.Success
    Write-ColorOutput "Image: " -Color $Colors.Info -NoNewline
    Write-ColorOutput "$ImageName:$Tag" -Color $Colors.Success
    Write-ColorOutput "Port: " -Color $Colors.Info -NoNewline
    Write-ColorOutput "$Port -> 80" -Color $Colors.Success
    Write-Host ""
    
    Write-ColorOutput "Configuration:" -Color $Colors.Info
    Write-ColorOutput "  Probe URLs: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $ProbeUrls -Color $Colors.Success
    Write-ColorOutput "  Frequency: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $ProbeFrequency -Color $Colors.Success
    Write-ColorOutput "  Timeout: " -Color $Colors.Info -NoNewline
    Write-ColorOutput "${ProbeTimeout}s" -Color $Colors.Success
    Write-ColorOutput "  Test Name: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $TestNamePrefix -Color $Colors.Success
    Write-ColorOutput "  Location: " -Color $Colors.Info -NoNewline
    Write-ColorOutput $TestLocation -Color $Colors.Success
    Write-Host ""

    $dockerArgs = @(
        "run",
        "-d",
        "--name", $ContainerName,
        "-p", "${Port}:80",
        "-e", "PROBE_URLS=$ProbeUrls",
        "-e", "PROBE_FREQUENCY=$ProbeFrequency",
        "-e", "PROBE_TIMEOUT_SECONDS=$ProbeTimeout",
        "-e", "TEST_NAME_PREFIX=$TestNamePrefix",
        "-e", "TEST_LOCATION=$TestLocation",
        "-e", "AzureWebJobsStorage=UseDevelopmentStorage=true",
        "-e", "FUNCTIONS_WORKER_RUNTIME=dotnet-isolated"
    )

    if ($AppInsightsKey) {
        $dockerArgs += "-e"
        $dockerArgs += "APPLICATIONINSIGHTS_CONNECTION_STRING=$AppInsightsKey"
        Write-ColorOutput "  App Insights: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "Configured" -Color $Colors.Success
    }
    else {
        $dockerArgs += "-e"
        $dockerArgs += "APPLICATIONINSIGHTS_CONNECTION_STRING=InstrumentationKey=00000000-0000-0000-0000-000000000000"
        Write-ColorOutput "  App Insights: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "Mock (local testing)" -Color $Colors.Warning
    }

    $dockerArgs += "$ImageName:$Tag"

    Write-Host ""
    Write-ColorOutput "Starting container..." -Color $Colors.Info
    
    $containerId = docker @dockerArgs 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-ColorOutput "✓ Container started successfully!" -Color $Colors.Success
        Write-ColorOutput "  Container ID: " -Color $Colors.Info -NoNewline
        Write-ColorOutput $containerId.Substring(0, 12) -Color $Colors.Success
        Write-ColorOutput "  Access URL: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "http://localhost:$Port" -Color $Colors.Success
        Write-Host ""
        Write-ColorOutput "Use the following commands:" -Color $Colors.Info
        Write-ColorOutput "  View logs:    " -Color $Colors.Info -NoNewline
        Write-ColorOutput ".\build-and-run.ps1 -Action Logs" -Color $Colors.Success
        Write-ColorOutput "  Stop:         " -Color $Colors.Info -NoNewline
        Write-ColorOutput ".\build-and-run.ps1 -Action Stop" -Color $Colors.Success
        Write-ColorOutput "  Shell access: " -Color $Colors.Info -NoNewline
        Write-ColorOutput ".\build-and-run.ps1 -Action Shell" -Color $Colors.Success
        
        return $true
    }
    else {
        Write-Host ""
        Write-ColorOutput "✗ Failed to start container" -Color $Colors.Error
        Write-ColorOutput $containerId -Color $Colors.Error
        return $false
    }
}

function Stop-DockerContainer {
    Write-Header "Stopping Container"
    
    $running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($running -eq $ContainerName) {
        Write-ColorOutput "Stopping container: $ContainerName..." -Color $Colors.Info
        docker stop $ContainerName 2>&1 | Out-Null
        Write-ColorOutput "✓ Container stopped" -Color $Colors.Success
    }
    else {
        Write-ColorOutput "Container is not running" -Color $Colors.Warning
    }
}

function Remove-DockerContainer {
    Write-Header "Cleaning Up"
    
    Stop-DockerContainer
    
    $exists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($exists -eq $ContainerName) {
        Write-ColorOutput "Removing container..." -Color $Colors.Info
        docker rm $ContainerName 2>&1 | Out-Null
        Write-ColorOutput "✓ Container removed" -Color $Colors.Success
    }
    
    Write-Host ""
    $response = Read-Host "Remove Docker image '$ImageName:$Tag'? (y/N)"
    if ($response -eq 'y' -or $response -eq 'Y') {
        docker rmi "$ImageName:$Tag" 2>&1 | Out-Null
        Write-ColorOutput "✓ Image removed" -Color $Colors.Success
    }
}

function Show-ContainerLogs {
    Write-Header "Container Logs"
    
    $running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($running -eq $ContainerName) {
        Write-ColorOutput "Showing logs for: $ContainerName" -Color $Colors.Info
        Write-ColorOutput "Press Ctrl+C to stop following logs" -Color $Colors.Warning
        Write-Host ""
        docker logs -f $ContainerName
    }
    else {
        Write-ColorOutput "Container is not running" -Color $Colors.Error
        Write-ColorOutput "Start the container first with: .\build-and-run.ps1 -Action Run" -Color $Colors.Info
    }
}

function Enter-ContainerShell {
    Write-Header "Container Shell"
    
    $running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($running -eq $ContainerName) {
        Write-ColorOutput "Opening shell in container: $ContainerName" -Color $Colors.Info
        Write-ColorOutput "Type 'exit' to leave the shell" -Color $Colors.Warning
        Write-Host ""
        docker exec -it $ContainerName /bin/bash
    }
    else {
        Write-ColorOutput "Container is not running" -Color $Colors.Error
        Write-ColorOutput "Start the container first with: .\build-and-run.ps1 -Action Run" -Color $Colors.Info
    }
}

function Show-ContainerStatus {
    Write-Header "Container Status"
    
    $running = docker ps --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    $exists = docker ps -a --filter "name=$ContainerName" --format "{{.Names}}" 2>$null
    
    if ($running -eq $ContainerName) {
        Write-ColorOutput "Status: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "Running ✓" -Color $Colors.Success
        
        $stats = docker inspect $ContainerName --format "{{.State.Status}}" 2>$null
        $created = docker inspect $ContainerName --format "{{.Created}}" 2>$null
        
        Write-Host ""
        docker ps --filter "name=$ContainerName" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        
        Write-Host ""
        Write-ColorOutput "Container Details:" -Color $Colors.Info
        docker inspect $ContainerName --format "  ID: {{.Id}}" 2>$null
        docker inspect $ContainerName --format "  Image: {{.Config.Image}}" 2>$null
        docker inspect $ContainerName --format "  Created: {{.Created}}" 2>$null
        docker inspect $ContainerName --format "  Started: {{.State.StartedAt}}" 2>$null
    }
    elseif ($exists -eq $ContainerName) {
        Write-ColorOutput "Status: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "Stopped" -Color $Colors.Warning
    }
    else {
        Write-ColorOutput "Status: " -Color $Colors.Info -NoNewline
        Write-ColorOutput "Not found" -Color $Colors.Error
    }
    
    Write-Host ""
    Write-ColorOutput "Available Images:" -Color $Colors.Info
    docker images $ImageName --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# Main execution
Write-Host ""
Write-ColorOutput "╔════════════════════════════════════════════════════════════════╗" -Color $Colors.Header
Write-ColorOutput "║   Azure Availability Agent - Local Docker Build & Run         ║" -Color $Colors.Header
Write-ColorOutput "╚════════════════════════════════════════════════════════════════╝" -Color $Colors.Header
Write-Host ""

# Check prerequisites
if (-not (Test-DockerInstalled)) {
    exit 1
}

if (-not (Test-DockerRunning)) {
    exit 1
}

# Execute action
$success = $false

switch ($Action) {
    'Build' {
        $success = Build-DockerImage
    }
    'Run' {
        # Check if image exists
        $imageExists = docker images -q "$ImageName:$Tag" 2>$null
        if (-not $imageExists) {
            Write-ColorOutput "Image '$ImageName:$Tag' not found. Building first..." -Color $Colors.Warning
            $success = Build-DockerImage
            if ($success) {
                $success = Start-DockerContainer
            }
        }
        else {
            $success = Start-DockerContainer
        }
    }
    'BuildAndRun' {
        $success = Build-DockerImage
        if ($success) {
            $success = Start-DockerContainer
        }
    }
    'Stop' {
        Stop-DockerContainer
        $success = $true
    }
    'Clean' {
        Remove-DockerContainer
        $success = $true
    }
    'Logs' {
        Show-ContainerLogs
        $success = $true
    }
    'Shell' {
        Enter-ContainerShell
        $success = $true
    }
    'Status' {
        Show-ContainerStatus
        $success = $true
    }
}

Write-Host ""
if ($success) {
    Write-ColorOutput "════════════════════════════════════════════════════════════════" -Color $Colors.Success
    Write-ColorOutput " Operation completed successfully!" -Color $Colors.Success
    Write-ColorOutput "════════════════════════════════════════════════════════════════" -Color $Colors.Success
}
else {
    Write-ColorOutput "════════════════════════════════════════════════════════════════" -Color $Colors.Error
    Write-ColorOutput " Operation failed!" -Color $Colors.Error
    Write-ColorOutput "════════════════════════════════════════════════════════════════" -Color $Colors.Error
    exit 1
}

Write-Host ""

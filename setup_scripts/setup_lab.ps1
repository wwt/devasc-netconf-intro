# Script to configure Programmability FOundations lab for DEVASC NETCONF lab

# Constants
$FRAME = "-" * 49
$S3_BUCKET_URI = "https://devnet-netconf.s3.us-east-2.amazonaws.com/"
$DOCKER_SETTINGS_FILE = "settings.json"
$DOCKER_SETTINGS_URI = $S3_BUCKET_URI + $DOCKER_SETTINGS_FILE
$DOCKER_SETTINGS_FILE_PATH = "c:\Users\admin\AppData\Roaming\Docker\"
$REPO_FILE = ".repo"
$REPO_FILE_URI = $S3_BUCKET_URI + $REPO_FILE
$JUPYTER_SCRIPT = "jupyter_launcher.ps1"
$JUPYTER_SCRIPT_URI = $S3_BUCKET_URI + $JUPYTER_SCRIPT
$ROOT_PATH = "C:\Users\admin"
$ANX_URL = "http://localhost:9269"


# Handle errors
function handle_error($error_message=$False) {
    Write-Host ""
    if($error_message){
        Write-Warning $error_message
    }
    else {
        Write-Warning "An unknown error occurred - please try again."
    }
    Write-Host ""
    exit
}


# Display script intro
function display_intro() {
    Write-Host ""
    write-Host $FRAME
    Write-Host "** Setting up the NETCONF Lab **" -ForegroundColor Green
    Write-Host "** This will take 5-10 minutes, please wait **" -ForegroundColor Green
    write-Host $FRAME
    Write-Host ""

    Start-Sleep -Seconds 1
}

function docker_status() {
    Write-Host "Checking Docker service & process status..." -NoNewline -ForegroundColor Green
    $docker_service_status = Get-Service -DisplayName "Docker*" | Where-Object {$_.Status -eq "Running"}
    $docker_process_status = docker info | Select-String -Pattern 'error' | ForEach-Object {$_.Matches.Success}
    Write-Host "done." -ForegroundColor Green
    Write-Host ""

    if (-not ($docker_service_status)) {
        handle_error("Docker Desktop Windows service not running. `nPlease wait for the service to start and try again.")
    }

    if ($docker_process_status) {
        handle_error("Docker Desktop process not running. `nPlease make sure Docker Desktop is running.")
    }
}

# Windows preparation
function setup_windows() {
    # Disable Windows Updates & delete temporary update files
    if (-not (Test-Path .winupdate -PathType leaf)) {
        Write-Host "Disabling Windows Update..." -NoNewline -ForegroundColor Green
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "Stop-Service wuauserv; Set-Service -Name wuauserv -StartupType Disabled; Get-ChildItem -Path C:\WINDOWS\SoftwareDistribution\Download -Verbose | Remove-Item -Force -Confirm:`$false -Recurse -ErrorAction SilentlyContinue"
        Out-File -FilePath .winupdate
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
}


# Docker Desktop preparation
function setup_docker() {
    if (!(Test-Path .dockerclean -PathType leaf)) {
        # Disable Docker Desktop updates
        Write-Host "Disabling Docker Desktop updates..." -NoNewline -ForegroundColor Green
        $settings_file = $DOCKER_SETTINGS_FILE_PATH + $DOCKER_SETTINGS_FILE
        Rename-Item -Path $settings_file -NewName "${settings_file}.old" -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DOCKER_SETTINGS_URI -OutFile $settings_file
        Write-Host "done." -ForegroundColor Green
        Write-Host ""

        # Remove existing Docker images
        Write-Host "Removing existing Docker Images..." -ForegroundColor Green
        docker rmi -f $(docker image ls -aq); docker system prune -af --volumes
        Out-File -FilePath .dockerclean
        Write-Host ""
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
}


# Run Jupyter Launcher
function run_jupyter_launcher() {
    Write-Host ""
    Write-Host "Downloading scripts..." -NoNewline -ForegroundColor Green
    # Download .repo file
    Invoke-WebRequest -Uri $REPO_FILE_URI -OutFile $REPO_FILE

    # Download Jupyter Launcher Script
    Invoke-WebRequest -Uri $JUPYTER_SCRIPT_URI -OutFile $JUPYTER_SCRIPT

    # Run Jupyter Launcher Script
    Invoke-Expression .\$JUPYTER_SCRIPT
    Write-Host "done." -ForegroundColor Green
    Write-Host ""
}


# Setup ANX
function setup_anx() {
    Write-Host "Cloning ANX repository..." -ForegroundColor Green
    Write-Host ""
    $anx_dir = Test-Path "${ROOT_PATH}\anx" -PathType Container

    if (-not ($anx_dir)) {
        # Clone ANX repo
        docker exec -it jupyter1 git clone https://github.com/cisco-ie/anx.git

        # Build & start ANX
        Set-Location "${ROOT_PATH}\anx"
        docker-compose up -d
        Start-Sleep -Seconds 5
    }
    Write-Host "done." -ForegroundColor Green
    Write-Host ""

    # Launch ANX in Chrome
    Write-Host "Opening ANX..." -NoNewline -ForegroundColor Green
    try {
        Start-Process "chrome.exe" "${ANX_URL}"
        Write-Host "done." -ForegroundColor Green
    }
    catch {
        handle_error("Unable to launch Chrome, you may manually navigate to the URL: `n${ANX_URL}.")
    }
}


# Create link file object
function create_link_obj($link_name, $link_target, $command=$False){
    if ($command) {
        $script_arguments = "-command $ROOT_PATH\$command"
    }
    $shortcut_path = "$ROOT_PATH\Desktop\$link_name"
    $w_script_shell = New-Object -ComObject WScript.Shell
    $shortcut = $w_script_shell.CreateShortcut($shortcut_path)

    if ($script_arguments) {
        $shortcut.Arguments = $script_arguments
        $shortcut.WorkingDirectory = $ROOT_PATH
    }
    $shortcut.TargetPath = $link_target
    $shortcut.save()
}


# Create links to relaunch lab & launch ANX
function create_shortcuts(){
    # Relaunch lab link
    Write-Host ""
    Write-Host "Creating desktop shortcut to restart the lab..." -NoNewline -ForegroundColor Green
    create_link_obj("Restart Lab.lnk")("powershell.exe")($JUPYTER_SCRIPT)
    Write-Host "done" -ForegroundColor Green

    # ANX Explorer link
    Write-Host ""
    Write-Host "Creating desktop shortcut to launch ANX..." -NoNewline -ForegroundColor Green
    create_link_obj("ANX.url")($ANX_URL)
    Write-Host "done" -ForegroundColor Green
}


# Display exit
function display_exit() {
    Write-Host ""
    Write-Host $FRAME
    Write-Host "** Setup complete **" -ForegroundColor Green
    Write-Host $FRAME
    Write-Host ""
}


# Main execution
function main() {
    display_intro
    docker_status
    setup_windows
    setup_docker
    run_jupyter_launcher
    setup_anx
    create_shortcuts
    display_exit
}


# Initiate main execution
main

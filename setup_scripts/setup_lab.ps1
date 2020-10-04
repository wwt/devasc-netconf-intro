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
    Write-Host "** This will take about 5 minutes, please wait **" -ForegroundColor Green
    write-Host $FRAME
    Write-Host ""

    Start-Sleep -Seconds 1
}


# Windows preparation
function setup_windows() {
    # Disable Windows Updates
    if (!(Test-Path .winupdate -PathType leaf)) {
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList "Stop-Service wuauserv; Set-Service -Name wuauserv -StartupType Disabled"
        Out-File -FilePath .winupdate
    }
}


# Docker Desktop preparation
function setup_docker() {
    if (!(Test-Path .dockerclean -PathType leaf)) {
        # Disable Docker Desktop updates
        $settings_file = $DOCKER_SETTINGS_FILE_PATH + $DOCKER_SETTINGS_FILE
        Rename-Item -Path $settings_file -NewName "${settings_file}.old" -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DOCKER_SETTINGS_URI -OutFile $settings_file

        # Remove existing Docker images
        docker rmi -f $(docker image ls -aq); docker system prune -af --volumes
        Out-File -FilePath .winupdate
    }
}


# Run Jupyter Launcher
function run_jupyter_launcher() {
    # Download .repo file
    Invoke-WebRequest -Uri $REPO_FILE_URI -OutFile $REPO_FILE

    # Download Jupyter Launcher Script
    Invoke-WebRequest -Uri $JUPYTER_SCRIPT_URI -OutFile $JUPYTER_SCRIPT

    # Run Jupyter Launcher Script
    Invoke-Expression .\$JUPYTER_SCRIPT
}


# Setup ANX
function setup_anx() {
    $anx_dir = Test-Path "${ROOT_PATH}\anx" -PathType Container

    if (!($anx_dir)) {
        # Clone ANX repo
        docker exec -it jupyter1 git clone https://github.com/cisco-ie/anx.git

        # Build & start ANX
        Set-Location "${ROOT_PATH}\anx"
        docker-compose up -d
        Start-Sleep -Seconds 5
    }

    # Launch ANX in Chrome
    Write-Host "Opening ANX..." -NoNewline
    try {
        Start-Process "chrome.exe" "${ANX_URL}"
        Write-Host "done."
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
    setup_windows
    setup_docker
    run_jupyter_launcher
    setup_anx
    create_shortcuts
    display_exit
}


# Initiate main execution
main

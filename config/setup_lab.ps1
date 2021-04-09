# Script to configure Programmability FOundations lab for DEVASC NETCONF lab

# Constants
$FRAME = "-" * 49
$S3_BUCKET_URI = "https://devasc-netconf.s3-us-west-2.amazonaws.com/"
$DOCKER_COMPOSE_FILE = "docker-compose.yml"
$DOCKER_COMPOSE_URI = $S3_BUCKET_URI + $DOCKER_COMPOSE_FILE
$DOCKER_REGISTRY_PATH = "lab-docker.wwtatc.com/devnet/"
$DOCKER_SETTINGS_FILE = "settings.json"
$DOCKER_SETTINGS_URI = $S3_BUCKET_URI + $DOCKER_SETTINGS_FILE
$DOCKER_SETTINGS_FILE_PATH = "c:\Users\admin\AppData\Roaming\Docker\"
$REPO_FILE = ".repo"
$REPO_FILE_URI = $S3_BUCKET_URI + $REPO_FILE
$REPO_NAME = "devasc-netconf-intro"
$JUPYTER_S3_BUCKET_URI = "https://jupyter-launcher.s3-us-west-2.amazonaws.com/"
$JUPYTER_SCRIPT = "jupyter_launcher.ps1"
$JUPYTER_SCRIPT_URI = $JUPYTER_S3_BUCKET_URI + $JUPYTER_SCRIPT
$ROOT_PATH = "C:\Users\admin"
$YANG_SUITE_IMAGES = @(
    "${DOCKER_REGISTRY_PATH}yang-suite-backup-1",
    "${DOCKER_REGISTRY_PATH}yang-suite-nginx-1",
    "${DOCKER_REGISTRY_PATH}yang-suite-yangsuite-1"
)
$YANG_SUITE_REPO = "https://github.com/CiscoDevNet/yangsuite"
$YANG_SUITE_URL = "http://localhost"


# Handle errors
function handle_error($error_message=$False) {
    Write-Host ""
    if($error_message){
        Write-Warning $error_message
    }
    else {
        Write-Warning "An unknown error occurred - please try again."
    }
    Start-Sleep -Seconds 5
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


# Verify the Docker service and Windows process are running
function docker_status() {
    try {
        Write-Host "Checking Docker service & process statuses..." -NoNewline -ForegroundColor Green
        Write-Host ""
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
    catch {
        handle_error("Unable to determine the Docker service and process statuses , please try again.")
    }
}


# Windows preparation
function setup_windows() {
    # Disable Windows Updates & delete temporary update files
    try {
        if (-not (Test-Path .winupdate -PathType leaf)) {
            Write-Host "Disabling Windows Update..." -NoNewline -ForegroundColor Green
            Write-Host ""
            Start-Process PowerShell -WindowStyle Minimized -Verb Runas -ArgumentList "Stop-Service wuauserv; Set-Service -Name wuauserv -StartupType Disabled; Get-ChildItem -Path C:\WINDOWS\SoftwareDistribution\Download -Verbose | Remove-Item -Force -Confirm:`$false -Recurse -ErrorAction SilentlyContinue"
            Out-File -FilePath .winupdate
            Write-Host "done." -ForegroundColor Green
            Write-Host ""
        }
    }
    catch {
        handle_error("An error occurred disabling Windows Update, please try again.")
    }
}


# Docker Desktop preparation
function setup_docker() {
    try {
        if (!(Test-Path .dockerclean -PathType leaf)) {
            # Disable Docker Desktop updates
            Write-Host "Disabling Docker Desktop updates..." -NoNewline -ForegroundColor Green
            Write-Host ""
            $settings_file = $DOCKER_SETTINGS_FILE_PATH + $DOCKER_SETTINGS_FILE
            Rename-Item -Path $settings_file -NewName "${settings_file}.old" -ErrorAction SilentlyContinue
            Invoke-WebRequest -Uri $DOCKER_SETTINGS_URI -OutFile $settings_file
            Write-Host "done." -ForegroundColor Green
            Write-Host ""

            # Remove existing Docker images
            Write-Host "Removing existing Docker Images..." -ForegroundColor Green
            Write-Host ""
            docker rmi -f $(docker image ls -aq); docker system prune -af --volumes
            Out-File -FilePath .dockerclean
            Write-Host ""
            Write-Host "done." -ForegroundColor Green
            Write-Host ""
        }
    }
    catch {
        handle_error("A Docker setup error occurred, please try again.")
    }
}


# Run Jupyter Launcher
function run_jupyter_launcher() {
    # Download and execute Jupyter Launcher
    Write-Host "Downloading scripts..." -NoNewline -ForegroundColor Green
    Write-Host ""
    try {
        # Download .repo file
        Invoke-WebRequest -Uri $REPO_FILE_URI -OutFile $REPO_FILE

        # Download Jupyter Launcher Script
        Invoke-WebRequest -Uri $JUPYTER_SCRIPT_URI -OutFile $JUPYTER_SCRIPT

        # Run Jupyter Launcher Script
        Invoke-Expression .\$JUPYTER_SCRIPT
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        handle_error("Unable to download scripts, please try again.")
    }
}


# Validate the Git clone operation of the lab repo
function validate_git_repo() {
    Set-Location $ROOT_PATH
    if (-not (Test-Path $REPO_NAME -PathType Container)) {
        handle_error("Aborting due to failed Git Clone.")
    }
}


# Setup YANG Suite
function setup_yang_suite() {
    # Clone Yang Suite repo
    Write-Host "Cloning YANG Suite repository..." -ForegroundColor Green
    Write-Host ""
    try {
        $yang_suite_dir = Test-Path "${ROOT_PATH}\yangsuite" -PathType Container

        if (-not ($yang_suite_dir)) {
            docker exec -it jupyter1 git clone $YANG_SUITE_REPO
        }
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        handle_error("Unable to clone YANG Suite repository, please try again.")
    }

    # Pull YANG Suite Images
    Write-Host "Loading ${YANG_SUITE_IMAGES.length} YANG Suite Docker Images..." -NoNewline -ForegroundColor Green
    Write-Host ""
    try {
        $loop_count = 1
        foreach ($image in $YANG_SUITE_IMAGES) {
            Write-Host ""
            Write-Host "Pulling Image ${loop_count} of ${YANG_SUITE_IMAGES.length}"
                docker pull $image
            Write-Host ""
            $loop_count += 1
        }
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        handle_error("Unable to pull YANG Suite Images, please try again.")
    }

    # Import custom Docker Compose file
    Write-Host "Importing Docker Compose file..." -NoNewline -ForegroundColor Green
    Write-Host ""
    try {
        $docker_compose_file = "${yang_suite_dir}\docker" + $DOCKER_COMPOSE_FILE
        Rename-Item -Path $docker_compose_file -NewName "${docker_compose_file}.old" -ErrorAction SilentlyContinue
        Invoke-WebRequest -Uri $DOCKER_COMPOSE_URI -OutFile $docker_compose_file
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        handle_error("Unable to load Docker Compose file, please try again.")
    }

    # Start YANG Suite Containers
    Write-Host "Starting YANG Suite Containers..." -NoNewline -ForegroundColor Green
    Write-Host ""
    try {
        Set-Location "${yang_suite_dir}\docker"
        docker-compose up -d
        Start-Sleep -Seconds 10
        Write-Host "done." -ForegroundColor Green
        Write-Host ""
    }
    catch {
        handle_error("Unable to start YANG Suite Containers, please try again.")
    }
    
    # Launch YANG Suite in Chrome
    Write-Host "Opening YANG Suite..." -NoNewline -ForegroundColor Green
    Write-Host ""
    try {
        Start-Process "chrome.exe" "${YANG_SUITE_URL}"
        Write-Host "done." -ForegroundColor Green
    }
    catch {
        handle_error("Unable to launch Chrome, you may manually navigate to the URL: `n${YANG_SUITE_URL}.")
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


# Create links to relaunch lab & launch YANG Suite
function create_shortcuts(){
    # Relaunch lab link
    Write-Host ""
    Write-Host "Creating desktop shortcut to restart the lab..." -NoNewline -ForegroundColor Green
    create_link_obj("Restart Lab.lnk")("powershell.exe")("setup_lab.ps1")
    Write-Host "done" -ForegroundColor Green

    # YANG Suite Explorer link
    Write-Host ""
    Write-Host "Creating desktop shortcut to launch YANG Suite..." -NoNewline -ForegroundColor Green
    create_link_obj("YANG Suite.url")($YANG_SUITE_URL)
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
    validate_git_repo
    setup_yang_suite
    create_shortcuts
    display_exit
}


# Initiate main execution
main

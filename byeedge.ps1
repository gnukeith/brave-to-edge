# Function to execute a command and provide feedback
function Execute-Command {
    param (
        [scriptblock]$command,
        [string]$description
    )
    try {
        Invoke-Command -ScriptBlock $command
        Write-Output "$description - This command worked. Going to the next one."
    } catch {
        Write-Output "$description - Something went wrong."
        exit
    }
}

# Open Microsoft Edge to download Brave
Execute-Command {
    Start-Process "msedge" -ArgumentList "https://laptop-updates.brave.com/download/bitness=64"
} "Opening Microsoft Edge to download Brave"

# Wait for the user to confirm the download is complete
Read-Host "Press Enter when the download is completed..."

# Kill Microsoft Edge process
Execute-Command {
    Stop-Process -Name "msedge" -Force -ErrorAction SilentlyContinue
} "Killing Microsoft Edge process"

# Navigate to the user's Desktop directory
Execute-Command {
    Set-Location "$HOME\Desktop"
    Write-Output (Get-Location)
} "Navigating to the user's Desktop directory"

# Function to remove directories
function Remove-Directory {
    param (
        [string]$path
    )
    Execute-Command {
        if (Test-Path $path) {
            takeown /a /r /d Y /f $path | Out-Null
            icacls $path /grant administrators:f /t | Out-Null
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
            if (Test-Path $path) {
                throw "Failed to delete $path"
            }
        } else {
            Write-Output "$path not found"
        }
    } "Removing directory $path"
}

# Function to edit the registry to remove Edge-related settings
function Edit-Registry {
    Execute-Command {
        $regContent = @"
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge]
"AllowPrelaunch"=dword:00000001
"DoNotUpdateToEdgeWithChromium"=dword:00000001

[-HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Active Setup\Installed Components\{9459C573-B17A-45AE-9F64-1857B5D58CEE}]
"@
        $regFile = "RemoveEdge.reg"
        $regContent | Set-Content -Path $regFile
        Start-Process regedit.exe -ArgumentList "/s $regFile" -Wait
        Remove-Item -Path $regFile
    } "Editing registry"
}

# Function to delete shortcuts
function Remove-Shortcut {
    param (
        [string]$path
    )
    Execute-Command {
        if (Test-Path -Path $path) {
            Remove-Item -Path $path -Force
        } else {
            Write-Output "Shortcut $path not found"
        }
    } "Removing shortcut $path"
}

# Remove Microsoft Edge directories
Remove-Directory "C:\Windows\SystemApps\Microsoft.MicrosoftEdge*"
Remove-Directory "C:\Program Files (x86)\Microsoft\Edge"
Remove-Directory "C:\Program Files (x86)\Microsoft\EdgeUpdate"
Remove-Directory "C:\Program Files (x86)\Microsoft\EdgeCore"
Remove-Directory "C:\Program Files (x86)\Microsoft\EdgeWebView"

# Edit the registry
Edit-Registry

# Remove Microsoft Edge shortcuts
Remove-Shortcut "C:\Users\Public\Desktop\Microsoft Edge.lnk"
Remove-Shortcut "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
Remove-Shortcut "$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk"
Write-Output "done"
Pause

# Delete Microsoft Edge Folders
Remove-Directory "C:\Program Files (x86)\Microsoft\Edge"
Remove-Directory "C:\Program Files (x86)\Microsoft\EdgeCore"
Remove-Directory "C:\Program Files (x86)\Microsoft\EdgeWebView"

# Delete Edge Icons from all users
Execute-Command {
    Get-ChildItem -Path "C:\Users" | ForEach-Object {
        Remove-Item -Path "C:\Users\$($_.Name)\Desktop\edge.lnk" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\Users\$($_.Name)\Desktop\Microsoft Edge.lnk" -Force -ErrorAction SilentlyContinue
    }
} "Deleting Edge icons from all users"

# Delete extra files
Execute-Command {
    if (Test-Path -Path "C:\Windows\System32\MicrosoftEdgeCP.exe") {
        Get-ChildItem -Path "C:\Windows\System32" -Filter "MicrosoftEdge*" | ForEach-Object {
            takeown /f $_.FullName | Out-Null
            icacls $_.FullName /inheritance:e /grant "UserName":(OI)(CI)F | Out-Null
            Remove-Item -Path $_.FullName -Force
        }
    }
} "Deleting extra files"

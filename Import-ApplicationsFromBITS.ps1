<#
    Author:    Graham Foral
    Date:      2/4/2023

    Purpose:   Download fresh installers from the internet and install them based on the configuration in a JSON file.
#>

param(
    $JSONConfig,
    $TempDir
)

# Global Variables 
$ApplicationList = Get-Content -Raw -Path $JSONConfig | ConvertFrom-Json

# Error Handling
If(!(Test-Path $TempDir)) {
    New-Item -Path $TempDir -ItemType Directory 
}

# Function Declaration: Test Internet Connectivity 
Function Test-Internet {
    If(Test-NetConnection -ComputerName "www.google.com") {
        return 1;
    } Else {
        return 0;
    }

}

Function Clean-TempDir {
    If(Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Force -Recurse
    }
}


# Function Declaration: Download and install apps
Function DownloadandInstall-Applications {
    ForEach($Application in $ApplicationList) {
        $DownloadedInstaller = ($Application.URI -split "/")[-1]

        Write-Host "Information: " -NoNewline -ForegroundColor Green
        Write-Host "Starting download of: $DownloadedInstaller" 

        ## Download the file
        Start-BitsTransfer -Source $Application.URI -Destination $TempDir

    
        If(Test-Path (Join-Path -Path $TempDir -ChildPath $DownloadedInstaller)) {

            Write-Host "Information: " -NoNewline -ForegroundColor Green
            Write-Host "Starting installation of: $DownloadedInstaller`n"  
        
            $InstallerFullPath = Get-ChildItem (Join-Path -Path $TempDir -ChildPath $DownloadedInstaller)

            ## Switch depending on installation type
            Switch ($Application.Type) {
                "MSI" { Start-Process -FilePath "C:\Windows\System32\msiexec.exe" -ArgumentList "`/i `"$InstallerFullPath`" $($Application.Arguments)" -Wait }
                "EXE" { Start-Process -FilePath `"$InstallerFullPath`" -ArgumentList $($Application.Arguments) -Wait }
            }    
    
        } Else {
            Write-Host "Error: " -NoNewline -ForegroundColor Red
            Write-Host "Could not find file: $DownloadedInstaller" 
        }

    }
}

## Script Logic starts here :)

If((Test-Internet) -eq 1) {
    Write-Host "Information: " -NoNewline -ForegroundColor Green
    Write-Host "You are connected to the internet. Continuing..." 

    DownloadandInstall-Applications

    Write-Host "Information: " -NoNewline -ForegroundColor Green
    Write-Host "Cleaning up..." 

    Clean-TempDir
    
} Else {
    Write-Host "Error: " -NoNewline -ForegroundColor Red
    Write-Host "You are not connected to the internet. Exiting..."     

}
#
# Update the addon installed in addon folder path
#

$addonpath = [System.Environment]::GetEnvironmentVariable( 'VantageAddonFolderPath' )
if ( $addonpath -eq $null )
{
    $AddonFolder = Read-Host -Prompt 'Input your addons file path'
    Set-Item -Path Env:VantageAddonFolderPath -Value ( $Env:VantageAddonFolderPath + $AddonFolder )
    $addonpath = [System.Environment]::GetEnvironmentVariable( 'VantageAddonFolderPath' )
}
elseif ( $args[0] -eq "-c" )
{
    Write-Output "Clearing Env variable..."
    [System.Environment]::SetEnvironmentVariable(
        " ",
        $env:VantageAddonFolderPath
    )
    Write-Output [Environment]::GetEnvironmentVariable( 'VantageAddonFolderPath' )
}

$current_dir = Get-Location
Copy-Item -Path $current_dir -Recurse -Destination $addonpath

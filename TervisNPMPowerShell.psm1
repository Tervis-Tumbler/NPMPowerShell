function Invoke-TervisNPMLinkDependencies {
    param (
        $PathToPackage,
        $DirectoryPathsAlreadyLinked
    )
    if (-not $DirectoryPathsAlreadyLinked) {
        $CommandResults = npm ls -g --depth=0 --link=true
        $DirectoryPathsAlreadyLinked = $CommandResults -match "@tervis" | foreach-object { $_ | Split-String -SplitParameter " -> "  | Select-Object -skip 1 }    
    }

    Push-Location -Path $PathToPackage
    Get-Content -Path "$PathToPackage\package.json" |
    ConvertFrom-Json |
    Select-Object -ExpandProperty dependencies -ErrorAction SilentlyContinue |
    ForEach-Object {$_.psobject.Properties.name} |
    Where-Object {$_ -match '@tervis'} |
    ForEach-Object { 
        Push-Location -Path "..\$(($_ -split "/")[1])"
        Invoke-TervisNPMLinkDependencies -PathToPackage "." -DirectoryPathsAlreadyLinked $DirectoryPathsAlreadyLinked
        $PathToLink = Get-Location | Select-Object -ExpandProperty Path
        if ($PathToLink -notin $DirectoryPathsAlreadyLinked) {
            npm link
        }
        Pop-Location
        npm link $_
    }
    Pop-Location
}

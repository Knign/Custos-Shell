Function Calculate-File-Hash($filepath) {
    $filehash = Get-FileHash -Path $filepath -Algorithm SHA512
    return $filehash
}

Function Erase-Baseline-If-Already-Exists($baselineFileName) {
    $baselinePath = ".\" + $baselineFileName
    $baselineExists = Test-Path -Path $baselinePath

    if ($baselineExists) {
        # Delete it
        Remove-Item -Path $baselinePath
    }
}

Write-Host ""
Write-Host "What would you like to do?"
Write-Host ""
Write-Host "    A) Collect new Baseline?"
Write-Host "    B) Begin monitoring files with saved Baseline?"
Write-Host ""

$response = $null
while ($response -notin @('A', 'B')) {
    Write-Host "Invalid Input"
    $response = Read-Host -Prompt "Please enter 'A' or 'B'"
}

Write-Host ""

if ($response -eq "A".ToUpper()) {
    # Get the baseline file name from user input
    $baselineFileName = $null
    while (-not $baselineFileName -or -not ($baselineFileName -like "*.txt")) {
        Write-Host "Invalid File Extension"
        $baselineFileName = Read-Host -Prompt "Enter the baseline file name (e.g., baseline.txt):"
    }

    # Delete baseline file if it already exists
    Erase-Baseline-If-Already-Exists -baselineFileName $baselineFileName

    # Calculate hash from the target files and store in baseline file
    # Collect all files in the target folder
    $files = Get-ChildItem -Path .\Files

    # For each file, calculate the hash and write to baseline file
    foreach ($f in $files) {
        $hash = Calculate-File-Hash $f.FullName
        "$($hash.Path)|$($hash.Hash)" | Out-File -FilePath $baselineFileName -Append
    }
}
elseif ($response -eq "B".ToUpper()) {
    # Get the baseline file name from user input
    $baselineFileName = $null
    while (-not $baselineFileName) {
        $baselineFileName = Read-Host -Prompt "Enter the baseline file name (e.g., baseline.txt):"
    }

    $fileHashDictionary = @{}

    # Load file|hash from baseline file and store them in a dictionary
    $filePathsAndHashes = Get-Content -Path $baselineFileName

    foreach ($f in $filePathsAndHashes) {
         $fileHashDictionary.add($f.Split("|")[0], $f.Split("|")[1])
    }

    # Begin (continuously) monitoring files with saved Baseline
    while ($true) {
        Start-Sleep -Seconds 1
        
        $files = Get-ChildItem -Path .\Files

        # For each file, calculate the hash, and compare with baseline
        foreach ($f in $files) {
            $hash = Calculate-File-Hash $f.FullName

            # Notify if a new file has been created
            if ($fileHashDictionary[$hash.Path] -eq $null) {
                Write-Host "$($hash.Path) has been created!" -ForegroundColor Green
            }
            else {
                # Notify if a file has been changed
                if ($fileHashDictionary[$hash.Path] -eq $hash.Hash) {
                    # The file has not changed
                }
                else {
                    Write-Host "$($hash.Path) has changed!!!" -ForegroundColor Yellow
                }
            }
        }

        # Check if any baseline files have been deleted
        foreach ($key in $fileHashDictionary.Keys) {
            $baselineFileStillExists = Test-Path -Path $key
            if (-Not $baselineFileStillExists) {
                Write-Host "$($key) has been deleted!" -ForegroundColor DarkRed -BackgroundColor Gray
            }
        }
    }
}

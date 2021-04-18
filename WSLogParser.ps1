function Get-IniContent {
    param (
        $Path
    )
    $ini = [hashtable]@{}
    $CurrentSection = ""
    Get-Content -Path $Path | ForEach-Object {
        if (!($_ -match "#.+")) {
            if($_ -match "^\[(.+)\]$"){
                $SectionName = $Matches.1
                $CurrentSection = $SectionName
                $ini.Add($CurrentSection, [hashtable]@{})
            }
            elseif ($_ -match "^(.+)=(.*)$") {
                $key = $Matches.1
                $value = $Matches.2
                $ini[$CurrentSection].Add($key, $value)
            }
            else{
                Write-Host "Cannot parse line: $($_)"
            }
        }
        else{
            Write-Host "Comment line: $($_)"
        }
    }
    return $ini
}

function Get-MatchCnt {
    param (
        $Pattern,
        $Path,
        $StartLine
    )
    $Log = Get-Content -Path $Path | Measure-Object
    $Match = Get-Content -Path $Path -Tail ($Log.Count - $StartLine) | Select-String -Pattern $Pattern
    # $Match = Select-String -Path $Path -Pattern $Pattern | Where-Object {$_.LineNumber -gt $StartLine}
    return $Match.Length
}
function Get-LastParsingEnd {
    if (!(Test-Path .\LineRecord.txt)) {
        New-Item -Path .\ -Name LineRecord.txt -type "file" -value "0"
        return 0
    }
    else {
        [int]$lineNum = Get-Content .\LineRecord.txt -Raw
        return $lineNum
    }
}
function Update-ParsingEnd {
    param(
        $Path
    )
    $Log = Get-Content -Path $Path | Measure-Object
    $Log.Count | Out-File ./LineRecord.txt
}

function Test-ServiceAlive {
    param(
        $Url = 'http://127.0.0.1:8080/health'
    )
    $Respond = Invoke-RestMethod -Uri $Url
    return $Respond.status
}

function Get-UnUpdateMaxTime {
    
}

function Update-Par {
    param(
        $Path,
        [hashtable]$KpiValueDict,
        $Value
    )
    if (!(Test-Path $Path)) {
        New-Item -Path $Path -type "file"
    }
    Clear-Content -Path $Path
    $KpiValueDict.GetEnumerator() | ForEach-Object{
        Out-File -InputObject "$($System)_WS:$($_.Key)=$($_.Value)" -FilePath $Path -Append
    }
}
#Default is http://127.0.0.1:8080/health
# Test-ServiceAlive -Url "http://140.115.53.158:9527"
# Update-ParsingEnd
Set-Location -Path D:\LogMonitor
$ini = Get-IniContent -Path .\LogParser.ini
$System = $ini.System.System
$LogPath = $ini.FileLocation.LogPath
$ParPath = $ini.FileLocation.ParPath
$Patterns = $ini.Pattern
$KpiValueDict = @{}
$ParsingEnd = Get-LastParsingEnd
$Patterns.GetEnumerator() | ForEach-Object{
    $Count = Get-MatchCnt -Pattern $_.value -Path $LogPath -StartLine $ParsingEnd
    $KpiValueDict.Add($_.key, $Count)
}
Update-ParsingEnd -Path $LogPath
$ServiceAlive = Test-ServiceAlive -Url "http://140.115.53.158:9527"
$KpiValueDict.Add("ServiceAlive", $ServiceAlive)
Update-Par -Path $ParPath -System $System -KpiValueDict $KpiValueDict

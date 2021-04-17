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
    $Match = Select-String -Path $Path -Pattern $Pattern | Where-Object {$_.LineNumber -gt $StartLine}
    return $Match.Length
}
function Get-ParsingEnd {
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
    
}
#Default is http://127.0.0.1:8080/health
# Test-ServiceAlive -Url "http://140.115.53.158:9527"
# Update-ParsingEnd
Set-Location -Path D:\LogMonitor
$ini = Get-IniContent -Path .\LogParser.ini
$LogPath = Join-Path $ini.FileLocation.LogDirectory -ChildPath "AFTS_20210402.log"
$Patterns = $ini.Pattern
$ParsingEnd = Get-ParsingEnd
$Patterns.GetEnumerator() | ForEach-Object{
    $count = Get-MatchCnt -Pattern $_.value -Path $LogPath -StartLine 0
    $message = '{0} appear {1} times' -f $_.key, $count
    Write-Output $message
}
# Get-MatchCnt -Pattern "loaded" -Path $LogPath -StartLine $ParsingEnd
# Update-ParsingEnd -Path $LogPath

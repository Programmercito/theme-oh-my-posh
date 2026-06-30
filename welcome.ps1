[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$pc = $env:COMPUTERNAME
$user = $env:USERNAME

# Icons
$i_user   = [char]0xf007
$i_ram    = [char]0xf2db
$i_node   = [char]0xe718
$i_java   = [char]0xe738
$i_php    = [char]0xe73d
$i_go     = [char]0xe626
$i_news   = [char]0xf1ea
$i_link   = [char]0xf0c1 # 

# Box & Special characters
$c_hz  = [char]0x2500 # ─
$c_vr  = [char]0x2502 # │
$c_fb  = [char]0x2588 # █
$c_ls  = [char]0x2591 # ░
$c_dot = [char]0x2022 # •
$c_ul  = [char]0x250c # ┌
$c_ll  = [char]0x2514 # └

# Cache System
$cacheFile = "$env:TEMP\devcito_cache.json"
$cache = $null
$needsUpdate = $true

if (Test-Path $cacheFile) {
    try {
        $cache = Get-Content $cacheFile -Raw -ErrorAction SilentlyContinue | ConvertFrom-Json
        if ($cache -and $cache.timestamp -and (New-TimeSpan -Start (Get-Date $cache.timestamp) -End (Get-Date)).TotalHours -lt 1) {
            $needsUpdate = $false
        }
    } catch {}
}

if ($cache -and $cache.articles -and $cache.articles.Count -gt 0) {
    $v_node = $cache.node
    $v_java = $cache.java
    $v_php  = $cache.php
    $v_go   = $cache.go
    # Select a random article from the cached list on the fly!
    $article = $cache.articles | Get-Random
    $newsTitle = $article.title
    $newsUrl = $article.url
} else {
    # Synchronous first-time fetch to populate cache
    function Get-Ver-Sync ($cmd, $arg) {
        try {
            if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                $out = & $cmd $arg 2>&1 | Out-String
                if ($out -match '"([^"]+)"\s+(.*LTS.*)') { return "$($matches[1]) $($matches[2])".Trim() }
                elseif ($out -match '(\d+\.\d+\.\d+)') { return $matches[0] }
                elseif ($out -match '(\d+\.\d+)') { return $matches[0] }
                elseif ($out -match '(\d+)') { return $matches[0] }
            }
        } catch {}
        return "N/A"
    }

    $v_node = Get-Ver-Sync "node" "-v"
    $v_java = Get-Ver-Sync "java" "-version"
    $v_php  = Get-Ver-Sync "php" "-v"
    $v_go   = Get-Ver-Sync "go" "version"

    $newsTitle = "Offline mode"
    $newsUrl = ""
    $articlesList = @()
    try {
        $response = Invoke-RestMethod -Uri "https://api.hnpwa.com/v0/news/1.json" -TimeoutSec 3
        # Cache up to 20 articles
        foreach ($item in ($response | Select-Object -First 20)) {
            $url = $item.url
            if ($url -and $url -like "item?id=*") {
                $url = "https://news.ycombinator.com/" + $url
            }
            $articlesList += @{ title = $item.title; url = $url }
        }
        if ($articlesList.Count -gt 0) {
            $article = $articlesList | Get-Random
            $newsTitle = $article.title
            $newsUrl = $article.url
        }
    } catch {}

    $cacheObj = @{
        timestamp = (Get-Date).ToString("o")
        node = $v_node
        java = $v_java
        php = $v_php
        go = $v_go
        articles = $articlesList
    }
    $cacheObj | ConvertTo-Json | Out-File -FilePath $cacheFile -Encoding utf8 -Force
    $needsUpdate = $false
}

if ($needsUpdate) {
    $bgScript = {
        param($path)
        function Get-Ver ($cmd, $arg) {
            try {
                if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                    $out = & $cmd $arg 2>&1 | Out-String
                    if ($out -match '"([^"]+)"\s+(.*LTS.*)') { return "$($matches[1]) $($matches[2])".Trim() }
                    elseif ($out -match '(\d+\.\d+\.\d+)') { return $matches[0] }
                    elseif ($out -match '(\d+\.\d+)') { return $matches[0] }
                    elseif ($out -match '(\d+)') { return $matches[0] }
                }
            } catch {}
            return "N/A"
        }
        $v_n = Get-Ver "node" "-v"
        $v_j = Get-Ver "java" "-version"
        $v_p = Get-Ver "php" "-v"
        $v_g = Get-Ver "go" "version"

        $articlesList = @()
        try {
            $response = Invoke-RestMethod -Uri "https://api.hnpwa.com/v0/news/1.json" -TimeoutSec 5
            foreach ($item in ($response | Select-Object -First 20)) {
                $url = $item.url
                if ($url -and $url -like "item?id=*") {
                    $url = "https://news.ycombinator.com/" + $url
                }
                $articlesList += @{ title = $item.title; url = $url }
            }
        } catch {}

        $cacheObj = @{
            timestamp = (Get-Date).ToString("o")
            node = $v_n
            java = $v_j
            php = $v_p
            go = $v_g
            articles = $articlesList
        }
        $cacheObj | ConvertTo-Json | Out-File -FilePath $path -Encoding utf8 -Force
    }

    if (Get-Command Start-Job -ErrorAction SilentlyContinue) {
        Start-Job -ScriptBlock $bgScript -ArgumentList $cacheFile | Out-Null
    } elseif (Get-Command Start-ThreadJob -ErrorAction SilentlyContinue) {
        Start-ThreadJob -ScriptBlock $bgScript -ArgumentList $cacheFile | Out-Null
    } else {
        & $bgScript $cacheFile
    }
}

# --- Dynamic System Stats ---
$hour = (Get-Date).Hour
$greeting = if ($hour -lt 6) { "Night owl mode" } elseif ($hour -lt 12) { "Morning session" } elseif ($hour -lt 18) { "Afternoon session" } else { "Night mode" }
$timeNow = Get-Date -Format "HH:mm:ss"

$memQuery = Get-CimInstance Win32_OperatingSystem -Property TotalVisibleMemorySize, FreePhysicalMemory
$totalRAM = [math]::Round($memQuery.TotalVisibleMemorySize / 1MB, 2)
$freeRAM  = [math]::Round($memQuery.FreePhysicalMemory / 1MB, 2)
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 2)
$ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 0)

# RAM Bar
$barLen = 12
$filled = [math]::Round(($ramPercent / 100) * $barLen)
$empty = $barLen - $filled

# Extract News Host
$newsHost = ""
if ($newsUrl) {
    try {
        $uri = [System.Uri]$newsUrl
        $newsHost = " ($($uri.Host))"
    } catch {}
}

# Truncate news title
$maxNewsLen = 45
$newsDisp = $newsTitle
if ($newsDisp.Length -gt $maxNewsLen) {
    $newsDisp = $newsDisp.Substring(0, $maxNewsLen - 3) + "..."
}

# Output UI using native Write-Host colors
Write-Host ""

# Large 3D Shadow DEV MODE ASCII Banner (Green & Cyan alternate)
Write-Host "  ██████╗ ███████╗██╗   ██╗    ███╗   ███╗ ██████╗ ██████╗ ███████╗" -ForegroundColor Green
Write-Host "  ██╔══██╗██╔════╝██║   ██║    ████╗ ████║██╔═══██╗██╔══██╗██╔════╝" -ForegroundColor Cyan
Write-Host "  ██║  ██║█████╗  ██║   ██║    ██╔████╔██║██║   ██║██║  ██║█████╗  " -ForegroundColor Green
Write-Host "  ██║  ██║██╔══╝  ╚██╗ ██╔╝    ██║╚██╔╝██║██║   ██║██║  ██║██╔══╝  " -ForegroundColor Cyan
Write-Host "  ██████╔╝███████╗ ╚████╔╝     ██║ ╚═╝ ██║╚██████╔╝██████╔╝███████╗" -ForegroundColor Green
Write-Host "  ╚═════╝ ╚══════╝  ╚═══╝      ╚═╝     ╚═╝ ╚══════╝ ╚═════╝ ╚══════╝" -ForegroundColor Cyan
Write-Host ""

# Line 1: Header Border
Write-Host "  $c_ul$c_hz$c_hz  " -ForegroundColor Green -NoNewline
Write-Host "$greeting  " -ForegroundColor Green -NoNewline
Write-Host "[" -ForegroundColor DarkGray -NoNewline
Write-Host $timeNow -ForegroundColor Cyan -NoNewline
Write-Host "]  " -ForegroundColor DarkGray -NoNewline
Write-Host ([string]$c_hz * 38) -ForegroundColor Green

# Line 2: Empty card space for breathing room
Write-Host "  $c_vr" -ForegroundColor Green

# Line 3: User & RAM
Write-Host "  $c_vr  " -ForegroundColor Green -NoNewline
Write-Host $i_user -ForegroundColor Cyan -NoNewline
Write-Host " $user" -ForegroundColor Cyan -NoNewline
Write-Host "@" -ForegroundColor DarkGray -NoNewline
Write-Host $pc -ForegroundColor Cyan -NoNewline
Write-Host "   " -NoNewline
Write-Host $c_vr -ForegroundColor DarkGray -NoNewline
Write-Host "  " -NoNewline
Write-Host $i_ram -ForegroundColor Green -NoNewline
Write-Host " RAM " -ForegroundColor Green -NoNewline
Write-Host ([string]$c_fb * $filled) -ForegroundColor Green -NoNewline
Write-Host ([string]$c_ls * $empty) -ForegroundColor DarkGray -NoNewline
Write-Host " ${usedRAM}" -ForegroundColor Green -NoNewline
Write-Host "/" -ForegroundColor DarkGray -NoNewline
Write-Host "${totalRAM}GB " -ForegroundColor Cyan -NoNewline
Write-Host "${ramPercent}%" -ForegroundColor Green

# Line 4: Versions
Write-Host "  $c_vr  " -ForegroundColor Green -NoNewline
Write-Host $i_node -ForegroundColor DarkGray -NoNewline
Write-Host " Node: " -ForegroundColor Cyan -NoNewline
Write-Host $v_node -ForegroundColor White -NoNewline
Write-Host "  " -NoNewline
Write-Host $c_dot -ForegroundColor DarkGray -NoNewline
Write-Host "  " -NoNewline
Write-Host $i_java -ForegroundColor DarkGray -NoNewline
Write-Host " Java: " -ForegroundColor Cyan -NoNewline
Write-Host $v_java -ForegroundColor White -NoNewline
Write-Host "  " -NoNewline
Write-Host $c_dot -ForegroundColor DarkGray -NoNewline
Write-Host "  " -NoNewline
Write-Host $i_php -ForegroundColor DarkGray -NoNewline
Write-Host " PHP: " -ForegroundColor Cyan -NoNewline
Write-Host $v_php -ForegroundColor White -NoNewline
Write-Host "  " -NoNewline
Write-Host $c_dot -ForegroundColor DarkGray -NoNewline
Write-Host "  " -NoNewline
Write-Host $i_go -ForegroundColor DarkGray -NoNewline
Write-Host " Go: " -ForegroundColor Cyan -NoNewline
Write-Host $v_go -ForegroundColor White

# Line 5: News
Write-Host "  $c_vr  " -ForegroundColor Green -NoNewline
Write-Host $i_news -ForegroundColor DarkGray -NoNewline
Write-Host " News: " -ForegroundColor Green -NoNewline
Write-Host $newsDisp -ForegroundColor White -NoNewline
Write-Host $newsHost -ForegroundColor DarkGray

# Line 6: Link
if ($newsUrl) {
    Write-Host "  $c_vr  " -ForegroundColor Green -NoNewline
    Write-Host $i_link -ForegroundColor DarkGray -NoNewline
    Write-Host " Link: " -ForegroundColor DarkGray -NoNewline
    Write-Host $newsUrl -ForegroundColor Cyan
}

# Line 7: Empty card space for breathing room
Write-Host "  $c_vr" -ForegroundColor Green

# Line 8: Bottom Border (Matching top line width)
Write-Host ("  " + $c_ll + ([string]$c_hz * 72)) -ForegroundColor Green
Write-Host ""



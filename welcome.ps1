$e = [char]27
$esc = "$e["

# Matrix Colors
$m1 = "$esc;38;2;0;255;65m"    # Bright Matrix green
$m2 = "$esc;38;2;57;255;20m"   # Neon green
$m3 = "$esc;38;2;0;204;51m"    # Mid green
$m4 = "$esc;38;2;0;143;17m"    # Dark green
$reset = "$esc;0m"

Clear-Host

# --- Version Helper ---
function Get-Ver ($cmd, $arg) {
    try {
        if (Get-Command $cmd -ErrorAction SilentlyContinue) {
            $out = (Invoke-Expression "$cmd $arg 2>&1" | Out-String)
            # Specific check for Java/Quoted versions with context (LTS/Dates)
            if ($out -match '"([^"]+)"\s+(.*LTS.*)') { return "$($matches[1]) $($matches[2])".Trim() }
            elseif ($out -match '(\d+\.\d+\.\d+)') { return $matches[0] }
            elseif ($out -match '(\d+\.\d+)') { return $matches[0] }
            elseif ($out -match '(\d+)') { return $matches[0] }
        }
    } catch {}
    return "N/A"
}

# --- System Stats ---
$pc = $env:COMPUTERNAME
$user = $env:USERNAME
$memQuery = Get-CimInstance Win32_OperatingSystem
$totalRAM = [math]::Round($memQuery.TotalVisibleMemorySize / 1MB, 2)
$freeRAM  = [math]::Round($memQuery.FreePhysicalMemory / 1MB, 2)
$usedRAM  = [math]::Round($totalRAM - $freeRAM, 2)
$ramPercent = [math]::Round(($usedRAM / $totalRAM) * 100, 0)

# Icons
$i_user = [char]0xf007
$i_pc   = [char]0xf108
$i_ram  = [char]0xf2db
$i_node = [char]0xe718
$i_java = [char]0xe738
$i_php  = [char]0xe73d
$i_go   = [char]0xe626
$i_news = [char]0xf1ea
$i_link = [char]0xf0c1

# --- Fetch Versions ---
$v_node = Get-Ver "node" "-v"
$v_java = Get-Ver "java" "-version"
$v_php  = Get-Ver "php" "-v"
$v_go   = Get-Ver "go" "version"

# --- Fetch Tech News ---
$newsTitle = "Fetching latest headlines..."
$newsUrl = ""
try {
    # Using HNPWA API (Hacker News) for fresher content
    $response = Invoke-RestMethod -Uri "https://api.hnpwa.com/v0/news/1.json" -TimeoutSec 2 -ErrorAction Stop
    $article = $response | Select-Object -First 10 | Get-Random
    $newsTitle = $article.title
    $newsUrl = $article.url
} catch {
    $newsTitle = "Offline mode"
    $newsUrl = ""
}

# --- Time Greeting ---
$hour = (Get-Date).Hour
$greeting = if ($hour -lt 6) { "Night owl mode" } elseif ($hour -lt 12) { "Morning init" } elseif ($hour -lt 18) { "Afternoon session" } else { "Night mode" }
$timeNow = Get-Date -Format "HH:mm:ss"

# --- RAM Bar ---
$barLen = 20
$filled = [math]::Round(($ramPercent / 100) * $barLen)
$empty = $barLen - $filled
$ramBar = "$m1$("█" * $filled)$m4$("░" * $empty)$reset"

# --- Visual Dashboard ---
Write-Host ""
Write-Host "  $m4░▒▓$m1╔╦╗$m2╔═╗$m1╦  ╦  $m3╔╦╗$m2╔═╗$m3╔╦╗$m4╔═╗$m4▓▒░$reset"
Write-Host "  $m4   $m1 ║║$m2║╣ $m1╚╗╔╝  $m3║║║$m2║ ║$m3 ║║$m4║╣$reset"
Write-Host "  $m4░▒▓$m1═╩╝$m2╚═╝$m1 ╚╝   $m3╩ ╩$m2╚═╝$m3═╩╝$m4╚═╝$m4▓▒░$reset"
Write-Host ""
Write-Host "  $m1$i_user $user $m4@ $m2$i_pc $pc      $m3$greeting $m4[$m2$timeNow$m4]$reset"
Write-Host "  $m4$('─' * 55)$reset"
Write-Host "  $m1$i_ram RAM  $reset$ramBar  $m2${usedRAM}$m4/$m3${totalRAM}GB $m1${ramPercent}%$reset"
Write-Host ""
Write-Host "  $m1$i_node Node $m2$v_node    $m3$i_java Java $m2$v_java    $m1$i_php PHP $m2$v_php    $m3$i_go Go $m2$v_go$reset"
Write-Host "  $m4$('─' * 55)$reset"
Write-Host "  $m1$i_news $m3TECH NEWS$reset"
if ($newsTitle.Length -gt 75) { $newsTitle = $newsTitle.Substring(0, 72) + "..." }
Write-Host "  $m2$newsTitle$reset"
if ($newsUrl) {
    Write-Host "  $m4$i_link $newsUrl$reset"
}
Write-Host ""
Write-Host "  $m4░ $m3System ready $m4░ $m1> $m2Wake up, $user...$reset"
Write-Host ""

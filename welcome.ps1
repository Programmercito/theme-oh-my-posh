$e = [char]27
$esc = "$e["

# Theme Colors (Tokyo Night inspired)
$c_blue   = "$esc;38;2;122;162;247m"
$c_purple = "$esc;38;2;187;154;247m"
$c_green  = "$esc;38;2;158;206;106m"
$c_yellow = "$esc;38;2;224;175;104m"
$c_orange = "$esc;38;2;255;158;100m"
$c_cyan   = "$esc;38;2;125;207;255m"
$c_red    = "$esc;38;2;247;118;142m"
$c_text   = "$esc;38;2;192;202;245m"
$c_grey   = "$esc;38;2;86;95;137m"
$c_dark   = "$esc;38;2;26;27;38m"
$reset    = "$esc;0m"

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
$i_dot  = [char]0xf111

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

# --- Render Function (3-Column Layout) ---
function Print-Row ($icon1, $color1, $text1, $icon2, $color2, $text2, $icon3, $color3, $text3) {
    Write-Host "  $color1$icon1 $text1  $color2$icon2 $text2  $color3$icon3 $text3$reset"
}

# --- Matrix-style green shades ---
$m1 = "$esc;38;2;0;255;65m"    # Bright Matrix green
$m2 = "$esc;38;2;57;255;20m"   # Neon green
$m3 = "$esc;38;2;0;204;51m"    # Mid green
$m4 = "$esc;38;2;0;143;17m"    # Dark green

# --- Visual Dashboard ---
Write-Host ""
Write-Host "  $m1╔╦╗$m2╔═╗$m1╦  ╦  $m3╔╦╗$m2╔═╗$m3╔╦╗$m4╔═╗$reset"
Write-Host "  $m1 ║║$m2║╣ $m1╚╗╔╝  $m3║║║$m2║ ║$m3 ║║$m4║╣$reset"
Write-Host "  $m1═╩╝$m2╚═╝$m1 ╚╝   $m3╩ ╩$m2╚═╝$m3═╩╝$m4╚═╝$reset"
Write-Host ""
Write-Host "  $c_purple$i_user $user $c_grey@ $c_blue$i_pc $pc $reset"
Write-Host "  $c_grey$('-'*50)$reset"

# Stats & Versions Row
Write-Host "  $c_cyan$i_ram  RAM  $reset$c_text${usedRAM}GB / ${totalRAM}GB ($ramPercent%)$reset"
Write-Host ""
Write-Host "  $c_green$i_node Node $reset$c_text$v_node$reset    $c_orange$i_java Java $reset$c_text$v_java$reset    $c_blue$i_php PHP  $reset$c_text$v_php$reset    $c_cyan$i_go Go $reset$c_text$v_go$reset"
Write-Host "  $c_grey$('-'*50)$reset"

# News Section with "Card" styling
Write-Host "  $c_yellow$i_news TODAY'S TECH NEWS:$reset"
# Wrap title if too long (basic truncation)
if ($newsTitle.Length -gt 75) { $newsTitle = $newsTitle.Substring(0, 72) + "..." }
Write-Host "  $c_text$newsTitle$reset"
if ($newsUrl) {
    Write-Host "  $c_grey$i_link $newsUrl$reset"
}
Write-Host ""

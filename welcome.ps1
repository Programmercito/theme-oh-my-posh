$e = [char]27
$esc = "$e["

# Theme Colors (Approximate matches)
$blue = "$esc;38;2;122;162;247m"
$purple = "$esc;38;2;187;154;247m"
$green = "$esc;38;2;158;206;106m"
$text = "$esc;38;2;192;202;245m"
$reset = "$esc;0m"

# Clear screen for a fresh start
Clear-Host

# Get Date
$date = Get-Date -Format "dddd, MMMM dd"
$time = Get-Date -Format "HH:mm"

# Greeting based on time
$hour = (Get-Date).Hour
if ($hour -lt 12) { $greeting = "Good Morning" }
elseif ($hour -lt 19) { $greeting = "Good Afternoon" }
else { $greeting = "Good Evening" }

# System Info (Fast)
$os = (Get-CimInstance Win32_OperatingSystem).Caption.Trim().Replace("Microsoft ", "")
$mem = Get-CimInstance Win32_OperatingSystem
$totalMem = [math]::Round($mem.TotalVisibleMemorySize / 1MB, 1)
$freeMem = [math]::Round($mem.FreePhysicalMemory / 1MB, 1)
$usedMem = [math]::Round($totalMem - $freeMem, 1)

# Random minimal quote
$quotes = @(
    "Code is like humor. When you have to explain it, it's bad.",
    "First, solve the problem. Then, write the code.",
    "Simplicity is the soul of efficiency.",
    "Make it work, make it right, make it fast.",
    "Talk is cheap. Show me the code."
)
$quote = $quotes | Get-Random

# Render
Write-Host ""
Write-Host "  $blue$greeting, $env:USERNAME$reset"
Write-Host "  $text$date $purple$time$reset"
Write-Host ""
Write-Host "  $green$quote$reset"
Write-Host ""
Write-Host "  $text$os $reset| $purple RAM: ${usedMem}GB / ${totalMem}GB$reset"
Write-Host ""

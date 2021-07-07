[int]$LookBack    = 90                  # How long back should we look for failed logins
[int]$FailedCount = 10                  # How many fails in the look bacvk period should trigger a ban
$FirewallRuleName = "RDP_Ban"
$BlockListPath    = "C:\blocklist.txt"

# Collect Event 4625
$logs = Get-WinEvent -FilterHashtable @{
    ID = 4625
    logname = "security"
    starttime = (Get-Date).AddMinutes(-$lookBack)
}

# Convert events into PSObjects
$parsed = $logs | ForEach-Object {
    $hash  = @{}
    ([xml]$_.ToXml()).event.eventdata.data | ForEach-Object {
        $current = $_
        try {$hash[$_.name.trim()] = $_."#text".trim()} catch {$hash[$current.name.trim()] = $null} #TryCatch block because trim throws error on Null values.
    }
    $hash["Time"] = $_.TimeCreated
    [pscustomobject]$hash
}

$attempts = $parsed | Group-Object IpAddress | Sort-Object count

# Import existing blocklist if exsist
$blocklist = [System.Collections.ArrayList]::new()
try {
    import-csv $BlockListPath | ForEach-Object {[void]$blocklist.Add($_)}
} catch {}

$attempts | Where-Object {$_.count -ge $FailedCount} | ForEach-Object {
    if ($blocklist.IP -notcontains $_.name) {
        [void]$blocklist.add(
            [pscustomobject]@{
                IP = $_.name
                Time = get-date
            }
        )
    }
}

# Make sure blocklist has atleast 1 record otherwise firewall rule fails
if ($blocklist.count -eq 0) {
    $blocklist.add(
        [pscustomobject]@{
            IP = "8.8.8.8"
            Time = get-date
        }
    )
}

# Update or create firewall rule with this name.
try {
    Set-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Action Block -RemoteAddress $blocklist.ip -Protocol TCP -LocalPort 3389 -Profile Any 
}
catch {
    New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Action Block -RemoteAddress $blocklist.ip -Protocol TCP -LocalPort 3389 -Profile Any 
}

# Update BlockList with new IPs.
$blocklist | Export-Csv $BlockListPath -NoTypeInformation

$FirewallRuleName = "RDP_Ban"
$BlockListPath    = "C:\blocklist.txt"

$csv = Import-Csv $BlockListPath 

$Eight = $csv | group {([version]$_.ip).major}

$Sixteen = $Eight | foreach {
    $_.group | group {([version]$_.ip).minor}
}

# $TwentyFour = $Sixteen | foreach {
#     $_.group | group {([version]$_.ip).Build}
# }

# Get list of subnets that need to be blocked
$ranges = [System.Collections.ArrayList]@()
$Sixteen | where count -gt 5 | foreach {$_.group[0].ip} | foreach {
    $Subnet = "$(($_ -split "\.")[0..1] -join ".").0.0/16"
    [void]$ranges.add($Subnet)
}

# Get list of IPs in the current list that are part of these subnets
$Overlap = $ranges | foreach {[version]($_ -split "/")[0]} | foreach {
    $current = $_
    $csv | where {
        ([version]($_.ip -split "/")[0]).major -eq $current.major -and ([version]($_.ip -split "/")[0]).minor -eq $current.minor
    }
}

# Get list of IPs that are not part of the subnets
$Nonoverlap = $csv | where {$Overlap.ip -notcontains $_.ip}

# Append subnets to list for export
$ranges | foreach {
    $Nonoverlap += [pscustomobject]@{
        IP = $_
        Time = get-date
    }
}

# Update firewall rule
try {
    Set-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Action Block -RemoteAddress $Nonoverlap.ip -Protocol TCP -LocalPort 3389 -Profile Any 
}
catch {
    New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Action Block -RemoteAddress $Nonoverlap.ip -Protocol TCP -LocalPort 3389 -Profile Any 
}

# Update BlockList with new IPs.
$Nonoverlap | Export-Csv $BlockListPath -NoTypeInformation

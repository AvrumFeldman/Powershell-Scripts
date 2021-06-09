$DCs = (Get-ADDomainController -Filter *).hostname

$Computers = $DCs | ForEach-object {
	$Current_DC = $_
	get-adcomputer -filter * -Properties lastlogon,DNSHostName,name,objectSid,enabled,lastlogontimestamp  -Server $Current_DC | select-object @{n="server";e={$Current_DC}},*
} | Group-Object objectSid


# get greatest time stamp between lastlogon and lastlogontimestamp
$computers | foreach-object {
	$_.group | ForEach-Object {
        if ($_.lastlogon -ge $_.lastlogontimestamp) {
            $ll = $_.lastlogon
        } else {
            $ll = $_.lastlogontimestamp
        }
        Add-Member -InputObject $_ -NotePropertyMembers @{"ll" = [int64]$ll} -force
    }
}


$computers | foreach-object {
    $Current_Grouped_PCs = $_.Group
    try {

        # Get greatest date from all servers.
        $Maximum = [System.Linq.Enumerable]::Max([bigint[]]$Current_Grouped_PCs.ll)

        # Get object that matches the greatest date. (Can technically be skipped if no need for source server).
        # -ge comparison operator is needed as measure-object messes up with the real int value off ll (reduces the value).
	    $Last_logged_in_pc = ($Current_Grouped_PCs | where-object {
		    [bigint]$_.ll -ge $Maximum
	    })[0]

        # Add human readable date time to returned object
	    Add-Member -InputObject $Last_logged_in_pc -NotePropertyMembers @{
		    "DateTime" = [datetime]::FromFileTime($Last_logged_in_pc.ll)
	    } -force

	    $Last_logged_in_pc

    } catch {
        # Try catch block is just used to avoid getting errors when trying to cast empty values into [biging].
    }
}

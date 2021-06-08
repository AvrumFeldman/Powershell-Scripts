$DCs = (Get-ADDomainController -Filter *).hostname

$Computers = $DCs | ForEach-object {
$Current_DC = $_
  get-adcomputer -Filter * -Properties lastlogon,DNSHostName,name,objectSid,enabled -Server $Current_DC| select-object @{n="server";e={$Current_DC}},*
} | Group-Object objectSid

$computers | foreach-object {
  $Current_Grouped_PCs = $_.group
  try {
    $Last_logged_in_pc = ($Current_Grouped_PCs | where-object {
      # Finds greatest lastlogon time stamp between all records for this object `
      # Then finds whichever objects are atleast the same lastlogon time stamp and selectes the first result (in case there is more then one value returned).
      [bigint]$_.lastlogon -ge [bigint]($Current_Grouped_PCs.lastlogon | measure-object -Maximum).Maximum
    })[0]
  } catch {}
  # Add readable time stamp to returned object.
  Add-Member -InputObject $Last_logged_in_pc -NotePropertyMembers @{
    "DateTime" = [datetime]::FromFileTime($Last_logged_in_pc.lastlogon)
  } -force
  $Last_logged_in_pc
} | Sort-Object lastlogon | select-object datetime,name,objectsid,lastlogon,dnshostname

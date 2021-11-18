$sessions = & qwinsta.exe
function index_Id {
    param(
        $data,
        $start
    )
    if ($data[($start -1)] -ne " ") {
        index_Id -data $data -start ($start -1)
    }
    else {
        $start
    }

}

$indx_ID  = [System.Linq.Enumerable]::Min([int[]]($sessions | foreach {(index_Id -data $_ -start $sessions[0].indexof("ID"))}))
$indx_Session   = $sessions[0].indexof("SESSIONNAME")
$indx_username  = $sessions[0].indexof("USERNAME")
$indx_State     = $sessions[0].indexof("STATE")
$indx_Type    = $sessions[0].indexof("TYPE")
$indx_Device    = $sessions[0].indexof("DEVICE")

$sessions[1..($sessions.Count)] | foreach {
    [PSCustomObject]@{
        session   = ($_[$indx_Session..($indx_username-1)] -join "").trim()
        Username  = ($_[$indx_username..($indx_ID-1)] -join "").trim()
        ID        = ($_[$indx_ID..($indx_State-1)] -join "").trim()
        State     = ($_[$indx_state..($indx_Type-1)] -join "").trim()
        Type      = ($_[$indx_Type..($indx_Device-1)] -join "").trim()
    }
}

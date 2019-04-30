function prompt { Write-Error "Typo"; "$pwd> " }

function prompt { Write-Error "Typo"; "$pwd> "; throw "grenade" }

$Error[0..2]
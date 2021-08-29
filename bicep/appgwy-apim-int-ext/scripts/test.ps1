1..1000 | Foreach-Object {
    $result = Invoke-WebRequest https://api-pointsbet-uat.azure-api.net/api/v2/events/nextup?limit=10 | Select-Object -expandproperty statuscode
    Write-Host "$result : https://api-pointsbet-uat.azure-api.net/api/v2/events/nextup?limit=10 : $(Get-Date -DisplayHint Time)"
    $result = Invoke-WebRequest https://api-uat.pointsbet.com/api/v2/events/nextup?limit=10 | Select-Object -expandproperty statuscode
    Write-Host "$result : https://api-uat.pointsbet.com/api/v2/events/nextup?limit=10 : $(Get-Date -DisplayHint Time)"

    start-sleep 5
}

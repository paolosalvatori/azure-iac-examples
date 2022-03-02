$rg = new-azresourcegroup -name quicktest-rg -location australiaeast
$lens = get-content ./portal-update.json | Convertfrom-json -AsHashtable

New-AzPortalDashboard -Name "Test-Dashboard-0" -ResourceGroupName $rg.ResourceGroupName -Lens $lens -location australiaeast -debug
Update-AzPortalDashboard -Name "Test-Dashboard-1" -ResourceGroupName $rg.ResourceGroupName -Lens $lens -debug

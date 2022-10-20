
$storageAccount = "changeme"
$rg = "changeme"

$ctx = New-AzStorageContext -StorageAccountName $storageAccount -UseConnectedAccount
$shares = Get-AzStorageShare -Context $ctx
$pvcs = @() #kubectl get pvc -A -o json | jq .items[].spec.volumeName # on jumpbox
$common = Compare-Object -ReferenceObject $pvcs -DifferenceObject $shares.name -ExcludeDifferent | Select-Object inputobject -ExpandProperty inputobject
$orphanedShares = get-azStorageShare -Context $ctx -Prefix pvc | Where-Object { $_.Name -notin $common }
$orphanedShares | Remove-AzStorageShare -Context $ctx


#Get-AzDisk -ResourceGroupName $rg | Where-Object DiskState -eq "Unattached" | Remove-AzDisk -Force
#$deleted = Get-AzRmStorageShare -StorageAccountName $ctx.StorageAccountName -ResourceGroupName $rg -IncludeDeleted | where Deleted -EQ true
#$deleted | Remove-AzRmStorageShare -Confirm
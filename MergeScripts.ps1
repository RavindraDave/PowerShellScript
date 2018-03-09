param(
 [string]$DatabaseName,
 [string]$inpath
)

$DFSFolders = Get-ChildItem -path $inpath | where-object {$_.Psiscontainer -eq "True"} |select-object name
foreach ($DFSfolder in $DFSfolders)
{
	Get-ChildItem -path "$inpath\$($DFSfolder.name)" -recurse |?{ ! $_.PSIsContainer } |?{($_.name).contains(".sql")} | %{ Out-File -filepath "$inpath\$DatabaseName.$($DFSfolder.name).sql" -inputobject (get-content $_.fullname) -Append}
}


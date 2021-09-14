$ServerName='TestServer'# the server it is on
$Database='MyDatabase' # the name of the database you want to script as objects
$DirectoryToSaveTo='F:\DatabaseCompare\TestServerDatabase' # the directory where you want to store them

# Load SMO assembly, and if we're running SQL 2008 DLLs load the SMOExtended and SQLWMIManagement libraries
$v = [System.Reflection.Assembly]::LoadWithPartialName( 'Microsoft.SqlServer.SMO')
if ((($v.FullName.Split(','))[1].Split('='))[1].Split('.')[0] -ne '9') {
   [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended') | out-null
}
[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SmoEnum') | out-null
 
set-psdebug -strict # catch a few extra bugs
$ErrorActionPreference = "stop"
$My='Microsoft.SqlServer.Management.Smo'
$srv = new-object ("$My.Server") $ServerName # attach to the server
if ($srv.ServerType-eq $null) # if it managed to find a server
   {
   Write-Error "Sorry, but I couldn't find Server '$ServerName' "
   return
}
$scripter = new-object ("$My.Scripter") $srv # create the scripter
$scripter.Options.ToFileOnly = $true
$scripter.Options.ExtendedProperties= $true # yes, we want these
$scripter.Options.DRIAll= $true # and all the constraints
$scripter.Options.Indexes= $true # Yup, these would be nice
$scripter.Options.Triggers= $true # This should be includede
$scripter.Options.AppendToFile= $true # This should be includede
$scripter.Options.IncludeIfNotExists= $true # This should be includede
$scripter.Options.AllowSystemObjects=$false
$scripter.Options.NoCollation =$true
$scripter.Options.Encoding= New-Object ("System.Text.ASCIIEncoding")

# first we get the bitmap of all the object types we want
$objectsToDo =[long] [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Table, [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::View, [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::StoredProcedure, [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::UserDefinedFunction, [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::UserDefinedTableTypes
#$objectsToDo =[long] [Microsoft.SqlServer.Management.Smo.DatabaseObjectTypes]::Table
# and we store them in a datatable
$d = new-object System.Data.Datatable
# get just the tables
$d=$srv.databases[$Database].EnumObjects($objectsToDo) 
# and write out each scriptable object as a file in the directory you specify


foreach ($object in $d) {
    Try
    {
         if(($object.Schema -ne "sys") -and ($object.Schema -ne "INFORMATION_SCHEMA"))
        {
            Write-Host $object.Urn
                $SavePath="$($DirectoryToSaveTo)\$($Database)\$($object.DatabaseObjectTypes)"

            $urn=[Microsoft.SqlServer.Management.Sdk.Sfc.Urn] $object.URN
            #write-verbose -Message "scripting $urn.name $urn.type" -verbose

            # create the directory if necessary (SMO doesn't).
            if (!( Test-Path -path $SavePath )) # create it if not existing
                   {Try { New-Item $SavePath -type directory | out-null }
                Catch [system.exception]{
                     Write-Error "error while creating '$SavePath' $object"
                     return
                     }
                }
            # tell the scripter object where to write it
            $scripter.Options.Filename = "$SavePath\$($object.Schema).$($object.Name).sql";
            # Create a single element URN array
            $URNCollection = new-object ("$My.urnCollection")
            $URNCollection.add($object.urn)
            # and write out the object to the specified file

            $scripter.script($URNCollection)
        }
    }
    Catch
    {
        Write-Host $object.Urn
        $object.Urn >> "$($DirectoryToSaveTo)\$($Database)\Errors.txt"
        Continue
    }
}
"Completed"

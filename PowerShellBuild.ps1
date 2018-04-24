<#
  Name		:   BulkBuild-VisualStudioSolution 
  Author	: 	Ravindra Dave
  Date		:	24-Apr-2018
#>

param(
 [string]$SourceCodeRepository,  #Source Code Directory
 [string]$OutputDirectory #Out Put Directory to build project output
)

$SolutionFiles = Get-ChildItem -Path $SourceCodeRepository -Recurse -Include *.csproj,*.vbproj
$MSBuild = $env:systemroot + "\Microsoft.NET\Framework64\v4.0.30319\MSBuild.exe"
$LogFilePath = $SourceCodeRepository + "\PowerShellBuildLog\"
$MasterLogFilePath = $LogFilePath + "PowerShellBuildLog.log"
If(!(test-path $LogFilePath))
{
      New-Item -ItemType Directory -Force -Path $LogFilePath
}

foreach ($Solution in $SolutionFiles) 
{
	$ProjectName = $Solution.FullName.Split("\");            
	$LogFileName = $ProjectName[$ProjectName.Length - 2]
	$ProjectBuildLog = $LogFilePath + $LogFileName + ".log"
	
	Write-Output ("Building solution file : " + $Solution.Name + ".....")	 
	Invoke-Expression "$MSBuild $Solution /p:Configuration=Release /p:Platform=AnyCPU /p:OutDir=$OutputDirectory /t:rebuild /v:quiet /nologo /fl /flp:logfile=$ProjectBuildLog /p:DebugSymbols=false /p:DebugType=None"
		
	If(!($LastExitCode -eq 0))
	{
		$Message = $Solution.FullName + " build unsuccessful."
		Add-content $MasterLogFilePath -value $Message
	}	
	
	Write-Output ("Build process complete for solution file" + $Solution.Name + ".")	 
}
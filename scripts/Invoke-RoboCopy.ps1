function Invoke-RoboCopy
{
	<#
	.DESCRIPTION
		PowerShell wrapper for robocopy, with logging and 
	.SYNOPSIS
		Short description
	.EXAMPLE
		Run-Function -Parameter $Value
			Runs function with Parameter
	.PARAMETER Parameter
		Description of Parameter
	#>
	
	[CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact="Medium", DefaultParameterSetName = "Default")]
	param (
		# Source folder
		[Parameter(Mandatory = $true, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $true, ParameterSetName = "Secfix")]
		[string]$Source,
		# Destination folder

		[Parameter(Mandatory = $true, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $true, ParameterSetName = "Secfix")]
		[string]$Destination,
		# Mirror Switch

		[Parameter(Mandatory = $true, ParameterSetName = "Mirror")]
		[switch]$Mirror,
		# Secfix Switch

		[Parameter(Mandatory = $true, ParameterSetName = "Secfix")]
		[switch]$Secfix,
		# Robocopy threads

		[Parameter(Mandatory = $false, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $false, ParameterSetName = "Secfix")]
		[string]$Retry = "0",
		# Robocopy threads

		[Parameter(Mandatory = $false, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $false, ParameterSetName = "Secfix")]
		[string]$Wait = "0",
		# Robocopy threads

		[Parameter(Mandatory = $false, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $false, ParameterSetName = "Secfix")]
		[string]$Threads = "64",
		# Execute switch, if not specified, will not actually perform action

		[Parameter(Mandatory = $false, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $false, ParameterSetName = "Secfix")]
		[switch]$Execute,
		# Robocopy executable path

		[Parameter(Mandatory = $false, ParameterSetName = "Mirror")]
		[Parameter(Mandatory = $false, ParameterSetName = "Secfix")]
		[string]$RoboCopyExe = "$env:SystemRoot\System32\Robocopy.exe"
	) # param
	
	begin
	{		
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		
		Write-Verbose -Message "Function called: $($MyInvocation.MyCommand)"
		
	} # begin
	
	process
	{
		
		# Set root path based on DestinationFolder
		$RootPath = $Destination.Split('\')[0] + '\'
		# Set Log folder
		$LogPath = $RootPath + "Logs\"
		# Get Destination Folder Name
		$DestinationFolderName = ($Destination.TrimEnd('\')).Split('\')[-1]
		
		
		# Verify Source folder is accessible
		Write-Verbose -Message "Testing Source folder ($Source)"
		if (-not (Test-Path -LiteralPath $Source))
		{
			Write-Verbose -Message "Unable to access $Source folder, aborting"
			break
		}
		
		# Verify Destination root path is accessible
		Write-Verbose -Message "Testing Destination root path ($RootPath)"
		if (-not (Test-Path -LiteralPath $RootPath))
		{
			Write-Verbose -Message "Unable to access $RootPath folder, aborting"
			break
		}
		
		# Verify test folder path, create folder if not present
		if (-not (Test-Path -LiteralPath $LogPath))
		{
			try
			{
				Write-Verbose -Message "Creating logfolder ($LogPath)"
				New-Item -Path $LogPath -ItemType Directory -ErrorAction Stop
			}
			catch
			{
				Write-Verbose -Message "Failed to create logfolder ($LogPath), aborting"
				Write-Error -Message $_.Exception.Message
				break
			}
		}
		
		
		# Timestamp to use in logfile
		$TimeStamp = Get-Date -Format yyyyMMdd.HH.mm
		
		# Build robocopy command based on switches
		if ($MyInvocation.BoundParameters["Mirror"].isPresent)
		{
			# Mirror switch
			$LogFile = $RootPath + "Logs\robocopy.$DestinationFolderName.mirror.$TimeStamp.log"
			$RoboCommand = "$Source $Destination /MIR /MT:$Threads /R:$Retry /W:$Wait /NS /NC /NFL /NDL /V /NP /UNILOG:$LogFile"
			Write-Verbose -Message "MIRROR switch was detected, building robocopy parameters ($RoboCommand)"
		}
		elseif ($MyInvocation.BoundParameters["Secfix"].isPresent)
		{
			# Secfix switch
			$LogFile = $RootPath + "Logs\robocopy.$DestinationFolderName.secfix.$TimeStamp.log"
			$RoboCommand = "$Source $Destination /MIR /SEC /SECFIX /MT:$Threads /R:$Retry /W:$Wait /NS /NC /NFL /NDL /V /NP /UNILOG:$LogFile"
			Write-Verbose -Message "SECFIX switch was detected, building robocopy parameters ($RoboCommand)"
		}
		else
		{
			# Missing Mirror or Secfix
			Write-Verbose -Message "Expected parameters missing, expected -Mirror or -Secfix, aborting script"
			break
		}
		
		
		# Execute, or not based on passed switches
		if ($MyInvocation.BoundParameters["Execute"].isPresent)
		{
			# Executing specified command
			Write-Debug -Message "Executing robocopy (robocopy.exe $RoboCommand)"
			Write-Verbose -Message "Executing robocopy (robocopy.exe $RoboCommand)"
			Start-Process -FilePath $RoboCopyExe -ArgumentList $RoboCommand -NoNewWindow -Wait
		}
		else
		{
			# Not executing command
			Write-Verbose -Message "Not executing command (robocopy.exe $RoboCommand)"
			
		}
	} # process
	
	end
	{
		
	} # end
	
} # Function
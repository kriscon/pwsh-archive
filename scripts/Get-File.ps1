function Get-File
{
	<#
	.DESCRIPTION
		Get-File simplifies the most common Where-Object queries on get-childitem.
		The function will return objects in the same manner as Get-ChildItem, and can be used for further pipelining.
	.SYNOPSIS
		Get files based on parameters, specify timeranges or newest, oldest etc.
	.EXAMPLE
		Get-File -Path C:\temp -Period -2h -DateProperty CreationTime
			Lists all files in C:\temp created the last 2 hours
	
		Get-File -Path C:\temp -Period 30d -Recurse
			Lists files in C:\temp and all subfolders that has not been modified the last 30 days
	
		Get-File -Path C:\temp -StartDate "2018-09-01" -EndDate "2018-09-29"
			Lists files in C:\temp modified between 01. september and 29. september
	
		Get-File -Path C:\temp -Newest 10
			List the 10 recently modified files in C:\temp
	.PARAMETER Filter
		Specify a file filter.
	.PARAMETER Recurse
		Include subfolders
	.PARAMETER DateProperty
		Specify the DateProperty Get-Files will sort by (e.g. LastWriteTime or CreationTime)
	.PARAMETER Oldest
		Lists the oldest files
	.PARAMETER Newest
		Lists the newest files
	.PARAMETER SkipOldest
		Skips the oldest files
	.PARAMETER SkipNewest
		Skips the specified amount of newest files.
	.PARAMETER Period
		Specify a timeperiod. The parameter can look for older or newer files based on input.
		E.g. '-2h' will list files modified the last 2 hours
		E.g. '30d' will list all files not modified the last 30 days
	.PARAMETER StartDate
		Used in conjunction with EndDate, e.g. -StartDate "2018-10-01" -EndDate "2018-10-03"
		Lists files modified between october 1st and october 3rd
	.PARAMETER EndDate
		Used in conjunction with StartDate, e.g. -StartDate "2018-10-01" -EndDate "2018-10-03"
		Lists files modified between october 1st and october 3rd
	#>
	
	[CmdletBinding(DefaultParameterSetName)]
	param (
		[Parameter(Mandatory = $true,
				   ValueFromPipeline = $true,
				   Position = 0)]
		[System.IO.DirectoryInfo[]]$Path,
		
		[Parameter(Mandatory = $false)]
		[string[]]$Filter = "*",
		
		[Parameter(Mandatory = $false)]
		[switch]$Recurse,
		
		[Parameter(Mandatory = $false)]
		[ValidateSet("LastWriteTime", "CreationTime", "LastAccessTime")]
		[string]$DateProperty = "LastWriteTime",
		
		[Parameter(ParameterSetName = 'Oldest', Mandatory = $false)]
		[int]$Oldest,
		
		[Parameter(ParameterSetName = 'Newest', Mandatory = $false)]
		[int]$Newest,
		
		[Parameter(ParameterSetName = 'SkipOldest', Mandatory = $false)]
		[int]$SkipOldest,
		
		[Parameter(ParameterSetName = 'SkipNewest', Mandatory = $false)]
		[int]$SkipNewest,
		
		[Parameter(ParameterSetName = 'Period',
				   HelpMessage = "RegEx validated string (e.g. 2h or -20d)",
				   Position = 1)]
		[ValidatePattern("^(-|)([1-9]){1}(\d{0,5})([hH|mM|sS|dD]{1})$")]
		[string]$Period,
		
		[Parameter(ParameterSetName = 'DateBetween',
				   Mandatory = $true,
				   HelpMessage = "StartDate needs to be in a valid Get-Date format")]
		[ValidateScript({ Get-Date $_ })]
		[string]$StartDate,
		
		[Parameter(ParameterSetName = 'DateBetween',
				   Mandatory = $true,
				   HelpMessage = "EndDate needs to be in a valid Get-Date format")]
		[ValidateScript({ Get-Date $_ })]
		[string]$EndDate
	)
	
	begin
	{
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		
		Write-Verbose -Message "Function called: $($MyInvocation.MyCommand)"
		
		# Variables used in Switch
		$Date = Get-Date
		if ($StartDate)
		{
			Write-Verbose -Message 'Converting `$StartDate and `$EndDate to Get-Date'
			$StartDateGD = Get-Date $StartDate -ErrorAction Stop
			$EndDateGD = Get-Date $EndDate -ErrorAction Stop
		}
		
	} # begin
	
	process
	{
		foreach ($Folder in $Path)
		{		
			foreach ($FilterItem in $Filter)
			{		
				$GetChildItemSplat = @{
					Path	    = $Folder.FullName
					Filter	    = $FilterItem
					Recurse	    = $Recurse
					File	    = $true
					Force	    = $true
					ErrorAction = 'Stop'
				}
				
				Write-Verbose -Message "Getting files from $($Folder.FullName)"
				# Added 'Where-Object -FilterScript { $_.Name -like $FilterItem }' as extra security when filtering for files using file extensions with 3 characters.
				# Probably because of Glob
				$GciResult = Get-ChildItem @GetChildItemSplat | Where-Object -FilterScript { $_.Name -like $FilterItem } | Sort-Object -Property $DateProperty
				
				Write-Verbose -Message "Switching ParameterSets"
				switch ($psCmdlet.ParameterSetName)
				{
					"Oldest" {
						Write-Verbose -Message "Switch 'Oldest'"
						Write-Verbose -Message "Getting the $Oldest oldest files in `$GciResult"
						$Result = $GciResult | Select-Object -First $Oldest
					} # Oldest
					
					"Newest" {
						Write-Verbose -Message "Switch 'Newest'"
						Write-Verbose -Message "Getting the $Newest newest files in `$GciResult"
						$Result = $GciResult | Select-Object -Last $Newest
					} # Newest		
					
					"SkipOldest" {
						Write-Verbose -Message "Switch 'SkipOldest'"
						Write-Verbose -Message "Skipping the $SkipOldest oldest files in `$GciResult"
						$Result = $GciResult | Select-Object -Skip $SkipOldest
					} # SkipOldest
					
					"SkipNewest" {
						Write-Verbose -Message "Switch 'SkipNewest'"
						Write-Verbose -Message "Skipping the $SkipNewest newest files in `$GciResult"
						$Result = $GciResult | Select-Object -SkipLast $SkipNewest
					} # SkipNewest
					
					'Period' {
						Write-Verbose -Message "Switch 'Period'"
						$PeriodNumber = $Period -replace "[-]|([hH|mM|sS|dD]{1})"
						switch -Wildcard ($Period)
						{
							# Seconds
							"*s" {
								if ($Period -like "-*")
								{
									$DateFilter = '($_.$DateProperty -gt $Date.AddSeconds(- $PeriodNumber))'
								}
								else
								{
									$DateFilter = '($_.$DateProperty -lt $Date.AddSeconds(- $PeriodNumber))'
								}
							} # Seconds
							
							# Minutes
							"*m" {
								if ($Period -like "-*")
								{
									$DateFilter = '($_.$DateProperty -gt $Date.AddMinutes(- $PeriodNumber))'
								}
								else
								{
									$DateFilter = '($_.$DateProperty -lt $Date.AddMinutes(- $PeriodNumber))'
								}
							} # Minutes
							
							# Hours
							"*h" {
								if ($Period -like "-*")
								{
									$DateFilter = '($_.$DateProperty -gt $Date.AddHours(- $PeriodNumber))'
								}
								else
								{
									$DateFilter = '($_.$DateProperty -lt $Date.AddHours(- $PeriodNumber))'
								}
							} # Hours
							
							# Days
							"*d" {
								if ($Period -like "-*")
								{
									$DateFilter = '($_.$DateProperty -gt $Date.AddDays(- $PeriodNumber))'
								}
								else
								{
									$DateFilter = '($_.$DateProperty -lt $Date.AddDays(- $PeriodNumber))'
								}
							} # Days
							
						} # switch $Period
						
						$ResultScript = [scriptblock]::Create($DateFilter)
						$Result = $GciResult | Where-Object -FilterScript @ResultScript
						
					} # Period
					
					'DateBetween' {
						Write-Verbose -Message "Switch 'DateBetween'"
						Write-Verbose -Message " Getting file older than $EndDateGD and newer than $StartDateGD"
						$DateBetweenFilter = '($_.$DateProperty -lt $EndDateGD) -and ($_.$DateProperty -gt $StartDateGD)'
						[scriptblock]$ResultScript = [scriptblock]::Create($DateBetweenFilter)
						$Result = $GciResult | Where-Object -FilterScript @ResultScript
						Write-Debug -Message "WTF"
					} # DateBetween
					
					Default
					{
						Write-Verbose -Message "Switch 'Default'"
						$Result = $GciResult
					} # Default
					
				} # switch $psCmdlet.ParameterSetName

				Write-Output -InputObject $Result
			} # foreach FilterItem
		} # foreach $Folder
	} # process

	end
	{
		Write-Verbose -Message "Function ended: $($MyInvocation.MyCommand)"
	} # end
	
} # Function
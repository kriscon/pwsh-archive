function Start-NewTranscript
{
<#
	.SYNOPSIS
		Check if logfolder exists then start transcript.
	.DESCRIPTION
		Function to create local log folder, and start transcript.
		Run without parameters to start a transcript in programdata with the name of the script.
	.EXAMPLE
		Start-BasicTranscript -Path C:\Log
			Starts a transcript to C:\Log\scriptname.log
		Start-BasicTranscript
			Starts a transcript to $env:programdata\Log\scriptname.log
#>
	[CmdletBinding()]
	param (
		[Parameter (Mandatory = $false)]
		[string]$Path,

		[Parameter (Mandatory = $false)]
		[string]$Name = $(Split-Path -Path $MyInvocation.PSCommandPath -Leaf),

		[Parameter(Mandatory = $false)]
		[ValidateRange(1,1000)]
		[int]$NumberOf = 50,

		[Parameter(Mandatory = $false)]
		[ValidateSet("Files","Days")]
		[string]$NumberType = "Files"
	)

	begin
	{
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

		Write-Verbose -Message "Function called: $($MyInvocation.MyCommand)"

		if(-not ($PSBoundParameters.Keys -contains "Path"))
		{

			$Path = "$env:ProgramData\Log\$Name"
			Write-Verbose -Message "Setting default log path $Path"

		}

	} # begin


	process
	{
		$Guid = ([guid]::NewGuid()).guid
		$Log = "$Path\$Name.$Guid.log"

		Write-Verbose -Message "`$Source is: $Name"

		# Abort script if $Source is not provided (e.g. command executed from a console instead of from a script).
		if ($Name.Length -lt 1)
		{
			Write-Verbose -Message "Aborting function, `$Source variable not valid."
			exit
		}

		if ($PSBoundParameters.Keys -contains "Path")
		{
			$Path = ($PSBoundParameters | Where-Object { $_.Keys -eq "Path" }).Values
		}

		# Check if log folder exists, create it if not.
		if (-not (Test-Path -Path $Path))
		{
			try
			{
				Write-Verbose -Message "Creating folder $Path"
				Write-Debug -Message "Creating folder $Path"

				# Create log folder
				New-Item -Path $Path -Type Directory -ErrorAction Stop
				Write-Verbose -Message "Folder created."

			}
			catch
			{
				Write-Verbose -Message "Failed to create folder."
				Write-Verbose -Message $_.Exception.Message
			}
		}

		# Start transcript
		try
		{
			Write-Verbose -Message "Starting transcript in $Log"
			Write-Debug -Message "Starting transcript in $Log"
			$Output = Start-Transcript -Path $Log -ErrorAction Stop

			Write-Output -InputObject $Output

		}
		catch
		{

			Write-Verbose -Message "Failed to start transcript."
			Write-Verbose -Message $_.Exception.Message

		}




	} # process

	end
	{

		# Cleanup log files
		$GetFileParams = @{
			"Path" = $Path
		}
		switch($NumberType)
		{
			"Files"
			{
				$GetFileParams.Add("SkipNewest",$NumberOf)
			}
			"Days"
			{
				$GetFileParams.Add("Period","$($NumberOf)d")
			}
		}
		
		$Files = Get-File @GetFileParams
		if ($Files)
		{
			Write-Verbose -Message "Removing files"
			Remove-Item -Path $Files.FullName
		}
		else
		{
			Write-Verbose -Message "No old logfiles to remove"
		}
	} # end

}
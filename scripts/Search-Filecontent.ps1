function Search-Filecontent
{
	<#
	.DESCRIPTION
		Searches for pattern matches in files located in specified folders.
	.SYNOPSIS
		Can search for multiple patterns, in multiple paths.
	.EXAMPLE
		Search-Filecontent -Path C:\temp -Pattern "Pattern1","Pattern2" -Recurse -Filter "*.txt"
			Search for 'Pattern1' and 'Pattern2' in 'C:\temp' in .txt files. Includes all subfolders
	.PARAMETER Path
		Description of Parameter
	.PARAMETER Pattern
		The pattern to search for, can be multiple strings
	.PARAMETER CaseSensitive
		Specify if the pattern search should be casesensitive or not
	.PARAMETER Filter
		Filter for filetypes
	.PARAMETER Recurse
		Include subfolders 
	#>
	
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[Parameter (Mandatory = $true)]
		[string[]]$Path,
		
		[Parameter(Mandatory = $true)]
		[string[]]$Pattern,

		[Parameter(Mandatory = $false)]
		[switch]$CaseSensitive,
		
		[Parameter(Mandatory = $false)]
		[string]$Filter,
		
		[Parameter(Mandatory = $false)]
		[switch]$Recurse
	)
	
	begin
	{		
		Get-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
		Write-Verbose -Message "Function called: $($MyInvocation.MyCommand)"
		
	} # begin
	
	process
	{
		$FileResult = foreach ($Item in $Path)
		{
			Write-Verbose -Message "Processing files in $($Item)"
			$Files = Get-ChildItem -Path $Path -Recurse:$Recurse -File -Filter $Filter
			
			foreach ($File in $Files)
			{
				Write-Verbose -Message " Searching in $($File.FullName)"
				$SelectStringSplat = @{
					Path = $File.FullName
					Pattern = $Pattern
					CaseSensitive = $CaseSensitive
				}
				$Temp = Select-String @SelectStringSplat
				
				if ($Temp)
				{
					Write-Verbose -Message "  Match found in $($File.FullName)"
					$Temp
					
				} # if $Temp
				Clear-Variable -Name Temp -ErrorAction SilentlyContinue
			} # foreach $File
			Clear-Variable -Name Files -ErrorAction SilentlyContinue
		} # foreach Path

		$Result = $FileResult -replace ":", ";" -replace ";\\", ":\" | ConvertFrom-Csv -Delimiter ";" -Header "File", "Line", "Text"
		return $Result
		
	} # process
	
	end
	{
		Write-Verbose -Message "Function ended: $($MyInvocation.MyCommand)"
	} # end
	
} # Function
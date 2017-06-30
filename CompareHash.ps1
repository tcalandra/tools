#Description Function to check file hash after transfer
#Based on two file shares, searches reccursively and returns any issues
#in verbose mode it will display all files checked
#Author Thomas Calandra
#Date 6/26/2017



[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
   [string]$drive1,
	
   [Parameter(Mandatory=$True)]
   [string]$drive2
)

function remove-drives(){
    if (Test-Path drive1:\){
        Remove-PSDrive drive1
        }
    if (Test-Path drive2:\){
        Remove-PSDrive drive2
        }
}
remove-drives
New-PSDrive -Name drive1 -PSProvider FileSystem $drive1
New-PSDrive -Name drive2 -PSProvider FileSystem $drive2

$drive1Hash = Get-ChildItem drive1:\ -Recurse | Get-FileHash -Algorithm MD5
$drive2Hash = Get-ChildItem drive2:\ -Recurse | Get-FileHash -Algorithm MD5

Compare-Object -ReferenceObject $drive1Hash -DifferenceObject $drive2Hash -Property Hash -PassThru
remove-drives
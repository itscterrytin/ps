<#
 .NOTES
  Version:1.0.0 20180613 initial build
  
 .EXAMPLE
  PS> .\robocopy-housekeep.ps1 -isLogged $false
  
  This example is to robocopy housekeep without logging
#>

Param
(
 [Parameter(Position=1,Mandatory=$false)] [Alias('log')][bool]$isLogged=$True
)

##common variables
$curDate = (Get-Date).ToString("yyyyMMdd_HHmmss")
$SCRIPT_DIR=$([System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition))
$SCRIPT_NAME=$([io.fileinfo]$MyInvocation.MyCommand.Definition).BaseName

$LOGFILE_DIR = ($SCRIPT_DIR+"\logs\")
$LOGFILE_PREFIX=($SCRIPT_NAME+"-")
$LOGFILE_SUFFIX=".log"
$LOGFILE_HOUSEKEEP_FILTER=$LOGFILE_PREFIX+"*"+$LOGFILE_SUFFIX
$transcriptFile=($LOGFILE_DIR+$LOGFILE_PREFIX+$curDate+$LOGFILE_SUFFIX)


#start logging
if ($isLogged) {
 start-transcript -path $transcriptFile
# Set-PSDebug -Trace 1
}

##self-defined variables
$srcHost=""
$srcHostname=""
$srcFolder="C:\source\"
$copyList=@("GoogleDrive\", "OneDrive\")
$dstHost=""
$dstHostname=""
$dstFolder="E:\backup\"
$LOGFILE_HOUSEKEEP_DAYS="-35"
$modLogFile=($LOGFILE_DIR+$LOGFILE_PREFIX+$curDate+".mod"+$LOGFILE_SUFFIX)

$7zExe="C:\PathTo\7z.exe"
$ARCHIVE_PREFIX=("arc-")
$ARCHIVE_SUFFIX=".zip"
$ARCHIVE_PATH=
$ARCHIVE_HOUSEKEEP_FILTER=$ARCHIVE_PREFIX+"*"+$ARCHIVE_SUFFIX
$ARCHIVE_HOUSEKEEP_DAYS="-3"


if ($srcHostname -eq "") {
 $srcPath=$srcFolder
} else {
 $srcPath=($srcHostname+"\"+$srcFolder)
}
if ($dstHostname -eq "") {
 $dstPath=$dstFolder
} else {
 $dstPath=($dstHostname+"\"+$dstFolder)
}

$retCode=0 # $retCode initialize

#archive
foreach ($copyItem in $copyList) {
 $TrimCopyItem=$copyItem.TrimEnd('\')
 $cmd = '& "'+$7zExe+'" a -mmt2 -tzip "'+$dstPath+$ARCHIVE_PREFIX+$TrimCopyItem+'.'+$curDate+$ARCHIVE_SUFFIX+'" "'+$dstPath+$copyItem+'" | out-default'
 iex $cmd
# $retCode=$lastexitcode
# if ($retCode -ne 0){ exit $retCode }
}

Get-ChildItem $dstPath -filter "$ARCHIVE_HOUSEKEEP_FILTER" | 
 Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays($ARCHIVE_HOUSEKEEP_DAYS)} | 
  Remove-Item -force
#$retCode=$lastexitcode
#if ($retCode -ne 0){ exit $retCode }



#backup
foreach ($copyItem in $copyList) {
 $cmd = 'robocopy "'+$srcPath+$copyItem+'" "'+$dstPath+$copyItem+'" /MIR /XA:SH /MT:2 /NP /NJH /NJS /R:0 /W:0 /XD ".tmp.drivedownload" "OneDriveTemp" /XF "pagefile.sys" "desktop.ini" | out-default'
 iex $cmd
# $retCode=$lastexitcode
# if ($retCode -ne 0){ exit $retCode }

# $cmd = 'ATTRIB -S -H '+$dstPath+$copyItem+' | out-default'
# iex $cmd | out-default
# $retCode=$lastexitcode
# if ($retCode -ne 0){ exit $retCode }
}

#housekeep
Get-ChildItem $LOGFILE_DIR -filter "$LOGFILE_HOUSEKEEP_FILTER" | 
 Where-Object {$_.LastWriteTime -lt (Get-Date).AddDays($LOGFILE_HOUSEKEEP_DAYS)} | 
  Remove-Item -force
#$retCode=$lastexitcode
#if ($retCode -ne 0){ exit $retCode }

#stop logging
if ($isLogged) {
# Set-PSDebug -Trace 0
 Stop-Transcript
}

#write mod log
$cmd = 'gc '+$transcriptFile+' | findstr "New" >> '+$modLogFile
iex $cmd
$cmd = 'gc '+$transcriptFile+' | findstr "EXTRA" >> '+$modLogFile
iex $cmd

#return error code
exit $retCode

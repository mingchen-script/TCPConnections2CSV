#
#   TCP connections Snapshot script. v0.3 10/26/2020
#
#   Goal of this Script is to get more detail on Perfmon's "TCPIP Performance Diagnostics (Per-CPU)" \ "TCP Current Connections" using NetStat over the same capture period.
#
#   This script will:
#     1. Run Netstat -n every ($g_Seconds) seconds for ($g_Snaps) snaps.
#     2. Add machine name and TimeStamp to parsed IP address and port information from NetStat output.
#     3. Save output to CSV: "<$g_Prefix>-YYYY-MM-dd-hh-mm-ss-MachineName.csv" for later analysis. 
#
#   Feel free to edit to fit your need.
#
# ToDO:
#
# Script variables block, modify to fit your need.
$g_Second = 1     #snapshot interval in seconds
$g_Snaps = 100      #snapshot counts
$g_Prefix ='TcpConnections' #Prefix for output filename, such as NorthEastDC
#
$mScriptPath = Split-Path ((Get-Variable MyInvocation -Scope 0).Value).MyCommand.Path
$mToday=Get-Date
$mOutFile=$mScriptPath+'\'+$g_Prefix+' '+[string]$mToday.Year+'-'+([string]$mToday.Month).PadLeft(2,'0')+'-'+([string]$mToday.Day).PadLeft(2,'0')+'-'+([string]$mToday.Hour).PadLeft(2,'0')+'-'+([string]$mToday.Minute).PadLeft(2,'0')+'-'+([string]$mToday.Second).PadLeft(2,'0')+'-'+$env:computername+'.csv'
#looping Netstat
$mCount = 1
$mHeader = 0 
$mNetStatCSV = @()
while ($mCount -le $g_Snaps) {
  $mTimeStamp = Get-Date -Format "yyyy/MM/dd hh:mm:ss tt"
  $mNetItems = netstat -no | Where-Object {$_ -match ':'} | ForEach{($_ -replace '\s+'," ").Trim(" ")} 
  ForEach($mNetItem in $mNetItems) {
    $tmp = $mNetItem.Split(" ")
      $lclColon = $tmp[1].LastIndexOf(':')
      $rmtColon = $tmp[2].LastIndexOf(':')
      [int]$tmpPID = $tmp[4]
    $process = Get-Process -PID $tmpPID -EA SilentlyContinue
      if ($process) { 
          $processName = $process.Name 
      } else {
          $processName = "PID not found"
      }
      $mObject = New-Object System.Object
        $mObject | Add-Member -MemberType NoteProperty -Name Sourece -Force -Value $env:computername
        $mObject | Add-Member -MemberType NoteProperty -Name TimeStamp -Force -Value $mTimeStamp
        $mObject | Add-Member -MemberType NoteProperty -Name Protocol -Force -Value $tmp[0]
        $mObject | Add-Member -MemberType NoteProperty -Name LocalIP  -Force -Value $tmp[1].SubString(0,$lclColon)
        $mObject | Add-Member -MemberType NoteProperty -Name LocalPort  -Force -Value $tmp[1].SubString($lclColon + 1)
        $mObject | Add-Member -MemberType NoteProperty -Name RemoteIP  -Force -Value  $tmp[2].SubString(0,$rmtColon)
        $mObject | Add-Member -MemberType NoteProperty -Name RemotePort  -Force -Value $tmp[2].SubString($rmtColon + 1)
        $mObject | Add-Member -MemberType NoteProperty -Name State  -Force -Value $tmp[3]
        $mObject | Add-Member -MemberType NoteProperty -Name ProcessName  -Force -Value $processName
      $mNetStatCSV += $mObject
    }
  if ($mHeader -eq 0) { # Header for CSV to allow append mode, instead of storing all results in memory to reduce memory footprint.
    $mNetStatCSV | ConvertTo-Csv -NoTypeInformation | Out-File $mOutFile
    $mHeader= 1
  } else { # no Header
    $mTmp = ($mNetStatCSV | ConvertTo-Csv -NoTypeInformation) 
    Write-Output $mTmp[1..$mNetStatCSV.count] | Out-File $mOutFile -Append
  } 
  Write-Progress -Activity "Saving TCP Connections info" -PercentComplete (($mCount/$g_Snaps)*100) 
  $mCount++
  $mNetStatCSV = @()
  Start-Sleep -Seconds $g_Second
}
Write-Host 'TCP Connections info saved to '$mOutFile

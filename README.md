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

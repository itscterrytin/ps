function Test-NetConnectionPort {
 Param ($TargetHost, $Port, $ThresholdSecond)
 $testMeaure = measure-command {
#  $testResult = Test-NetConnection $TargetHost -Port $Port
  $testResult = New-Object System.Net.Sockets.TCPClient -ArgumentList $TargetHost, $Port
 }
# $testResult

# if ( $($testResult).TcpTestSucceeded ) {
 if ( $($testResult).Connected ) {
  return 0 # port allowed
 } elseif ( $($testMeaure).TotalMilliseconds -ge $ThresholdSecond*1000 ) {
  return 1 # port timeout
 } else {
  return 2 # port refused
 }
}

Test-NetConnectionPort -TargetHost 'localhost' -Port 445 -ThresholdSecond 5
Test-NetConnectionPort -TargetHost 'localhost' -Port 22 -ThresholdSecond 5
Test-NetConnectionPort -TargetHost '111.111.111.111' -Port 22 -ThresholdSecond 5

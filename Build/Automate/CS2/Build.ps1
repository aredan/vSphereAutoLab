if (Test-Path C:\PSFunctions.ps1) {
	. "C:\PSFunctions.ps1"
} else {
	Write-Host "PSFunctions.ps1 not found. Please copy all PowerShell files from B:\Automate to C:\ and rerun Build.ps1"
	Read-Host "Press <Enter> to exit"
	exit
}

if (Test-Path "B:\Automate\automate.ini") {
	Write-BuildLog "Determining automate.ini settings."
	$viewinstall = ((Select-String -SimpleMatch "ViewInstall=" -Path "B:\Automate\automate.ini").line).substring(12)
	Write-BuildLog "  VMware View install set to $viewinstall."
	$timezone = ((Select-String -SimpleMatch "TZ=" -Path "B:\Automate\automate.ini").line).substring(3)
	Write-BuildLog "  Timezone set to $timezone."
	tzutil /s "$timezone"
	$AdminPWD = ((Select-String -SimpleMatch "Adminpwd=" -Path "B:\Automate\automate.ini").line).substring(9)
}
If (([System.Environment]::OSVersion.Version.Major -eq 6) -and ([System.Environment]::OSVersion.Version.Minor -ge 2)) {
	Write-BuildLog "Disabling autorun of ServerManager at logon."
	Start-Process schtasks -ArgumentList ' /Change /TN "\Microsoft\Windows\Server Manager\ServerManager" /DISABLE'  -Wait -Verb RunAs
	Write-BuildLog "Disabling screen saver"
	set-ItemProperty -path 'HKCU:\Control Panel\Desktop' -name ScreenSaveActive -value 0
}
if (Test-Path "C:\VMware-view*") {
	$Files = get-childitem "C:\"
	for ($i=0; $i -lt $files.Count; $i++) {
		If ($Files[$i].Name -like "VMware-view*") {$Installer = $Files[$i].FullName}
	}
	switch ($viewinstall) {
		60 {
			Write-BuildLog "Install View 6.0 Connection Server"
			Start-Process $Installer -wait -ArgumentList '/s /v"/qn VDM_SERVER_INSTANCE_TYPE=2 ADAM_PRIMARY_NAME=cs1.lab.local"'
			C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe "C:\Program Files\VMware\VMware View\Server\bin\PowershellServiceCmdlets.dll" >> c:\buildLog.txt
		}
		53{
			Write-BuildLog "Install View 5.3 Connection Server"
			Start-Process $Installer -wait -ArgumentList '/s /v"/qn VDM_SERVER_INSTANCE_TYPE=2 ADAM_PRIMARY_NAME=cs1.lab.local"'
			C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe "C:\Program Files\VMware\VMware View\Server\bin\PowershellServiceCmdlets.dll" >> c:\buildLog.txt
		}
		52 {
			Write-BuildLog "Install View 5.2 Connection Server"
			Start-Process $Installer -wait -ArgumentList '/s /v"/qn VDM_SERVER_INSTANCE_TYPE=2 ADAM_PRIMARY_NAME=cs1.lab.local"'
			C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe "C:\Program Files\VMware\VMware View\Server\bin\PowershellServiceCmdlets.dll" >> c:\buildLog.txt
		}
		51 {
			Write-BuildLog "Install View 5.1 Connection Server"
			Start-Process $Installer -wait -ArgumentList '/s /v"/qn VDM_SERVER_INSTANCE_TYPE=2 ADAM_PRIMARY_NAME=cs1.lab.local"'
			C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe "C:\Program Files\VMware\VMware View\Server\bin\PowershellServiceCmdlets.dll" >> c:\buildLog.txt
		}
		50 {
			Write-BuildLog "Install View 5.0 Connection Server"
			Start-Process $Installer -wait -ArgumentList '/s /v"/qn VDM_SERVER_INSTANCE_TYPE=2 ADAM_PRIMARY_NAME=cs1.lab.local"'
			C:\Windows\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe "C:\Program Files\VMware\VMware View\Server\bin\PowershellServiceCmdlets.dll" >> c:\buildLog.txt
		}	
	}
	reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Build /f
	Exit
}
Write-BuildLog "Install Flash Player"
Start-Process msiexec -wait -ArgumentList " /i b:\Automate\_Common\install_flash_player_11_active_x.msi /qn"
Write-BuildLog "Setup Firewall"
netsh advfirewall firewall add rule name="All ICMP V4" dir=in action=allow protocol=icmpv4
netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=Yes
Write-BuildLog "Setup persistet route to other subnet for SRM and View"
route add 192.168.201.0 mask 255.255.255.0 192.168.199.254 -p
Write-BuildLog "Cleanup"
regedit /s b:\Automate\_Common\ExecuPol.reg
regedit -s b:\Automate\_Common\NoSCRNSave.reg
Write-BuildLog "Change default local administrator password"
net user administrator $AdminPWD
B:\automate\_Common\Autologon administrator CS2 $AdminPWD
Write-BuildLog "Copy Connection server install and setup recall"
$Files = get-childitem "b:\view$viewinstall"
for ($i=0; $i -lt $files.Count; $i++) {
	If ($Files[$i].Name -like "VMware-viewconnectionserver*") {$Installer = $Files[$i].FullName}
}
copy $Installer C:\
reg add HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v Build /t REG_SZ /d "cmd /c c:\Build.cmd" /f  >> c:\buildlog.txt
Write-BuildLog "Install VMware Tools"
b:\VMTools\Setup64.exe /s /v "/qn"
Read-Host "Reboot?"



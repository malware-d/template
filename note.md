# Table of Contents
1. [Finding Files in Kali Linux](#Finding-Files-in-Kali-Linux)
2. [The Bash Environment](#The-Bash-Environment)
3. [Piping and Redirection](#Piping-and-Redirection)
## Finding Files in Kali Linux
### which 
The **which** command searches through the directories that are defined in the **$PATH** environment variable for a given file name. **which** returns the full path to the file.
### locate
The **locate** command is the quickest way to find the locations of files and directories. **locate** searches a built-in database named **locate.db** rather than the entire hard disk itself. To manually update the **locate.db** database, use the **updatedb** command
```console
kali@kali:~$ sudo updatedb
kali@kali:~$ locate sbd.exe
/usr/share/windows-resources/sbd/sbd.exe
```
### find
The **find** command is the most complex and flexible search tool. A recursive search starting from the root file system directory and look for any file that starts with the letters *sbd*.
```console
kali@kali:~$ sudo find / -name sbd*
/usr/bin/sbd
/usr/share/doc/sbd
/usr/share/windows-resources/sbd
```
The main advantage of **find** over **locate** is that it can search for files and directories by more than just the name. With **find**, we can search by file age, size, owner, file type, timestamp permissions, and more.
## The Bash Environment
Bash is an sh-compatible shell that allows us to run complex commands and perform different tasks from a terminal window. It incorporates useful features from both the **KornShell (ksh)** and **C shell (csh)**.
### Environment Variables
When opening a terminal window, a new Bash process, which has its own **environment variables**, is initialized. These variables are a form of global storage for various settings inherited by any applications that are run during that terminal session.
Let's take a look at the contents of the **PATH** (a colon-separated list of directory paths that Bash will search through whenever a command is run without a full path) environment variable:
```console
kali@kali:~$ echo $PATH
/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
```
An environment variable can be defined with the **export** command. It makes the variable accessible to any subprocesses we might spawn from our current Bash instance. Use the **$$** variable to display the process ID of the current shell
```console
kali@kali:~$ export b=10.11.1.220
kali@kali:~$ ping -c 2 $b
PING 10.11.1.220 (10.11.1.220) 56(84) bytes of data.
64 bytes from 10.11.1.220: icmp_seq=1 ttl=62 time=2.23 ms
64 bytes from 10.11.1.220: icmp_seq=2 ttl=62 time=1.56 ms
kali@kali:~$ echo "$$"
1827
```
Running **env** to see environment variables defined by default in Kali Linux.
```console
kali@kali:~$ env
SHELL=/bin/bash
...
PWD=/home/kali
XDG_SESSION_DESKTOP=lightdm-xsession
LOGNAME=kali
XDG_SESSION_TYPE=x11
```
### Bash History Tricks
It's important to keep a record of commands that have been entered into the shell.
```console
kali@kali:~$ history
1 cat /etc/lsb-release
2 clear
3 history
kali@kali:~$ !1
cat /etc/lsb-release
```
By default, the command history is saved to the **.bash_history** file in the user home directory. Two environment variables control the history size: *HISTSIZE* and *HISTFILESIZE*. *HISTSIZE* controls the number of commands stored in memory for the current session and *HISTFILESIZE* configures how many commands are kept in the history file. These variables can be edited according to our needs and saved to the Bash configuration file (**.bashrc**)
## Piping and Redirection
Every program run from the command line has three data streams connected to it that serve as communication channels with the external environment.

| Stream Name              | Description                                   |
|--------------------------|-----------------------------------------------|
| Standard Input (STDIN)   | Data fed into the program                     |
| Standard Output (STDOUT) | Output from the program (default to terminal) |
| Standard Error (STDERR)  | Error messages (default to terminal)          |
### Redirecting to a File
```console
#to a New File. If we redirect the output to a non-existent file, the file will be created automatically. However, if we save the output to a file that already exists, that file's content will be replaced. There is no undo function!
kali@kali:~$ echo "Kali Linux is an open source project" > redirection_test.txt

#to an Existing File. To append additional data to an existing file use the >> operator:
kali@kali:~$ echo "that is maintained and funded by Offensive Security" >> redirection_test.txt
kali@kali:~$ cat redirection_test.txt
Kali Linux is an open source project
that is maintained and funded by Offensive Security
```
### Redirecting from a File
For example, we redirect the wc command's STDIN with data originating directly from the file we generated.
```console
kali@kali:~$ wc -m < redirection_test.txt
89
```
### Redirecting STDERR
According to the POSIX specification, the file descriptors for the STDIN, STDOUT, and STDERR are defined as 0, 1, and 2 respectively.
Redirecting the standard error (STDERR):
```console
kali@kali:~$ ls .
Desktop Documents Downloads Music Pictures Public redirection_test.txt Template
kali@kali:~$ ls ./test
ls: cannot access '/test': No such file or directory
kali@kali:~$ ls ./test 2>error.txt
kali@kali:~$ cat error.txt
ls: cannot access '/test': No such file or directory
```
Note that **error.txt** only contains the error message (generated on STDERR). We did this by prepending the stream number to the **>** operator (2=STDERR).

File descriptor
`/dev/null` - usually used to store garbage data from input streams when we don't want to process or display it.
- `>/dev/null`: redirect all standard output to `/dev/null` . Equivalent of writing `1>/dev/null`
- `2>&1`: redirect all standard errors to standard output
```console
#Do not display the error on the screen
kali@kali:~$ find / -name '*duycvp.net*' 2>/dev/null
#Move error message to file
kali@kali:~$ cat khongtontai.txt 2> error.txt
kali@kali:~$ cat error.txt
cat: khongtontai.txt: No such file or directory
#Error message not handled by grep
kali@kali:~$ find / -name '*duy*' | grep 'kim'
#Grep handle the whole
kali@kali:~$ find / -name '*duy*' 2>&1 | grep 'kim'
```
### Piping
How to redirect the output from one command into the input of another.
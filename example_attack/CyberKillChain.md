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

Tóm lại, càng thu thập được nhiều thông tin về mục tiêu thì việc đánh giá mức độ an toàn của hệ thống càng chính xác, từ đó tỉ lệ thành công của một cuộc tấn công sẽ càng cao.

#### 1. Kiểm tra các tệp tin Spiders, Robots và Crawlers
Việc thu thập dữ liệu từ các tệp tin **Spiders, Robots và Crawler** nhằm mục đích kiếm tra thông tin về website đang chạy trên máy chủ mục tiêu **(ví dụ như trang chủ của doanh nghiệp)***
```console
#Sử dụng công cụ Wget tải file robots.txt
C:\>wget.exe <tên website>/robots.txt
User-agent: *
Disallow: /admin/
Disallow: /content/
Disallow: /cache/
```
Trong đó:
- **User-agent** đại diện cho một máy tìm kiếm, đặt “*” có nghĩa là cho phép mọi máy tìm kiếm duyệt qua các liên kết của trang.
- **Allow**: Cho phép máy tìm kiếm truy cập vào thư mục được liệt kê
- **Disallow**: Không cho phép máy tìm kiếm truy cập vào thư mục được liệt kê

#### 2. Sử dụng toán tử tìm kiếm trên Google
Sử dụng những toán tử tìm kiếm để điều tra những thông tin nhạy cảm, ảnh hưởng đến an ninh của ứng dụng web
| **Toán tử**       | **Ý nghĩa**                                                                                     |
|-------------------|-------------------------------------------------------------------------------------------------|
| **Filetype:**     | Tìm kiếm thông tin theo định dạng tập tin cụ thể như: ***.txt, .html, .pdf, .doc, .flash, .swf,...*** |
| **Intitle:**      | Tìm kiếm thông tin dựa theo tiêu đề của trang web                                               |
| **Inurl:URL**     | Tìm kiếm các trang web có địa chỉ URL bắt buộc chứa các từ khóa chỉ định                        |
| **Link:URL**      | Tìm kiếm các trang thông tin có liên kết tới trang được chỉ định                                |
| **Related: URL**  | Tìm kiếm các trang web có thông tin tương tự trang web được chỉ định                            |
| **Site:tên miền** | Hạn chế kết quả tìm kiếm trong các tên miền được chỉ định                                       |
| **Cache:**        | Xem thông tin trang web chứa trong bộ nhớ đệm Cache của google                                  |

#### 3. Xác định các điểm nhập dữ liệu đầu vào
Điểm nhập dữ liệu đầu vào là nơi đưa dữ liệu vào ứng dụng và cung cấp thông tin cho ứng dụng. Các điểm đầu vào này rất dễ bị tấn công, do lập trình viên không đảm bảo lập trình an toàn 
- Biến HTTP: Trình duyệt hoặc người sử dụng gửi thông tin đến ứng dụng sẽ thiết lập các yêu cầu được thể hiện trong chuỗi truy vấn dữ liệu, cookie, các biến của máy chủ,...
- SOAP: Các ứng dụng có thể truy cập bởi các dịch vụ trên bản tin SOAP
- XML: Các ứng dụng có thể chiếm file XML từ các thành viên trên Internet
- Hệ thống mail: Các ứng dụng có thể lấy/gửi mail từ hệ thống mail thông qua các giao
thức như POP, SMTP, IMAP.

**Phương thức kiểm tra:** Thực hiện Request/Response và thu thập liệt kê thông tin thu được:
Kiểm tra các yêu cầu HTTP, thu thập các thông tin về các phương thức GET, POST, các tham số, các form field, phương thức mã hóa SSL có được dùng không, chú ý những thông tin nhạy cảm được chuyển qua ứng dụng.
- Xác định ở đâu thì GET được dùng, ở đâu thì POST được dùng.
- Xác định các tham số liên quan đến yêu cầu GET và POST trong quá trình
request/response
- Chú ý đến cookies: chứa thông tin nhạy cảm không, có gán cờ secure chưa,...

**Công cụ kiểm tra:** Webscarab, Paros Proxy, Zed Attack Proxy,...

#### 4. Kiểm tra Web Application Fingerprint
Thu thập thông tin về ứng dụng mục tiêu, bao gồm các thông tin như phần mềm ứng dụng web, công nghệ dịch vụ web, phiên bản cơ sở dữ liệu, cấu hình và có thể là kiến trúc mạng
của nó.

**Phương thức kiểm tra:** Cần xác định các thành phần sau:
- Xác định phiên bản webserver
- Xác định phần mềm ứng dụng web
- Xác định phiên bản cơ sở dữ liệu
- Xác định công nghệ dịch vụ web

**Công cụ kiểm tra:** Netcat, httprecon, webscarab

#### 5. Application Discovery
- Kiểm tra các cổng đang mở trên máy chủ. Mục đích kiếm các port được mở, các dịch vụ đang khởi chạy.

**Công cụ kiểm tra:** Nmap, Nessus
- Kiểm tra các tên miền đặt chung trên máy chủ

**Công cụ kiểm tra:** whois.webhosting.info
- Kiểm tra những tên DNS khác
**Công cụ kiểm tra:** dnsstuff.com
#### 6. Phân tích Error Codes
Các mã lỗi này rất hữu ích để kiểm tra thâm nhập trong các hoạt động của ứng dụng web, bởi vì các thông báo lỗi tiết lộ rất nhiều thông tin về cơ sở dữ liệu, lỗi và các thành phần công nghệ khác liên quan trực tiếp đến ứng dụng web.

Các mã lỗi này có thể phân chia theo máy chủ và hệ điều hành máy chủ theo trạng thái phương
thức kết nối.

Một số mã lỗi: 
- Mã lỗi máy khách (4xx): Xảy ra lỗi là lỗi của máy khách. Ví dụ: Máy khách có thể yêu cầu một trang không tồn tại hoặc máy khách không thể cung cấp thông tin xác thực hợp lệ.
- Mã lỗi máy chủ (5xx): Máy chủ không thể hoàn thành yêu cầu vì gặp phải lỗi.

#### 7. Kiểm tra cấu hình Website
##### 7.1. Kiểm tra SSL/TLS
Với việc sử dụng SSL, các website có thể cung cấp khả năng bảo mật thông tin, xác thực và toàn vẹn dữ liệu đến người dùng. SSL được tích hợp sẵn vào các browser và webserver cho phép người sử dụng làm việc với các trang web ở chế độ an toàn. Khi web browser sử dụng kết nối SSL và dòng “http” trong hộp nhập địa chỉ URL sẽ đổi thành “https”. Một phiên giao dịch HTTPS sử dụng cổng 443 thay vì sử dụng cổng 80 như dùng HTTP.

Các thuật toán mã hóa được dùng: DES, 3-DES (Triple-DES), DSA, KEA, RSA, RSA key exchange,... và hàm băm: SHA-1, MD5,... 

Phương thức kiếm tra:
- Kiểm tra nếu CA được biết đến (được coi là đáng tin cậy)
- Kiểm tra giấy chứng nhận là hợp lệ
- Kiểm tra tên web và tên trong báo cáo của chứng chỉ. Điều quan trọng là các trang web cần yêu cầu thuật toán mã hóa mạnh với độ dài lớn hơn 40-56 bit.

Kiểm tra chi tiết:
- Mỗi trình duyệt đi kèm với một danh sách cài đặt sẵn các CA tin cậy. Dựa vào đó chứng chỉ CA được so sánh. Trong các trao đổi ban đầu với một máy chủ https, nếu chứng chỉ
máy chủ liên quan đến một CA không rõ nguồn gốc cho trình duyệt, một lời cảnh báo
được hiện ra.
- CA có một khoảng thời gian hiệu lực, do đó chúng có thể hết hạn. Một dịch vụ công cộng cần một chứng chỉ về thời gian hợp lệ, nếu không điều đó có nghĩa là chúng ta đang giao
tiếp với một máy chủ có chứng chỉ đã được phát hành bởi một người nào đó được tin tưởng, nhưng đã hết hạn mà không được gia hạn thêm.
- Nếu tên của website và tên báo cáo trong chứng chỉ không trùng khớp thường sẽ có cảnh
báo từ trình duyệt.

**Công cụ kiểm tra:** SSLscan, OpenSSL hoặc các công cụ trên website online: ssllabs.com




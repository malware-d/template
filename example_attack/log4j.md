# REPORT log4j (CVE-2021-44228)
- Mức độ nghiêm trọng: đạt 10/10 *(trong hệ thống đánh giá CVSS)*
- Khai thác lỗ hổng không yêu cầu xác thực, cho phép thực thi mã từ xa (RCE) trên bất kỳ ứng dụng nào sử dụng tiện ích **log4j**
## Table of Content
1. [Log4jShell](#Log4jShell)
2. What is LDAP and JNDI
3. LDAP and JNDI Chemistry
4. Log4j JNDI lookup
5. Normal Log4j scenario
6. Exploit Log4j scenario
7. Pentest Lab Setup
8. Exploiting Log4j (CVE-2021-44228)
9. Mitigation

## Log4jShell
Tính năng JNDI trong Apache Log4j2 phiên bản 2.0-beta9 đến 2.12.1 và 2.13.0 đến 2.15.0 được sử dụng cho việc cấu hình (configuration), log messages (bao gồm cả các tham số liên quan) không chống lại các LDAP và JNDI endpoint liên quan khác mà attacker đang có quyền kiểm soát. Vì thế nên, một khi attacker có thể kiểm soát các log messages hoặc các tham số của log messages thì có thể thực thi được mã code tùy ý được load từ LDAP server. 
- Loại lỗ hổng: Remote Code Execution
- Mức độ: Critical
- Base CVSS Score: 10.0
- Phiên bản bị ảnh hưởng: All versions from 2.0-beta9 to 2.14.1

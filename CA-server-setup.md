# Thiết lập và cấu hình Certificate Authority (CA)
Certificate Authority (CA) là một tổ chức chịu trách nhiệm cấp chứng chỉ kỹ thuật số để xác minh danh tính trên internet. Mặc dù public CA là lựa chọn phổ biến để xác minh danh tính của trang web và các dịch vụ khác được cung cấp cho công chúng, nhưng private CA thường được sử dụng cho các group khép kín và dịch vụ bảo mật.

Xây dựng Private Certificate Authority sẽ cho phép bạn cấu hình, kiểm tra và chạy các chương trình yêu cầu kết nối được mã hóa giữa máy khách và máy chủ. Với Private CA, bạn có thể cấp chứng chỉ cho người dùng, máy chủ hoặc các chương trình và dịch vụ riêng lẻ trong cơ sở hạ tầng của mình. 

Một số chương trình phổ biến trên Linux sử dụng private CA là OpenVPN và Puppet. Bạn cũng có thể cấu hình cho web server sử dụng chứng chỉ được phát hành bởi private CA, từ đó môi trường develop và staging sẽ tương đương với server trong sản xuất (production) sử dụng TLS để mã hóa kết nối.

## Requisites
Cần đảm bảo rằng bạn có quyền truy cập vào server Ubuntu 20.04 qua một user non-root với quyền sudo, đồng thời đã cài sẵn tường lửa trên hệ thống.

Hãy đảm bảo rằng CA server là một hệ thống độc lập (standalone). Ta sẽ dùng server này để import, ký và thu hồi các chứng chỉ. Server này không nên chạy thêm bất kỳ dịch vụ nào khác, đồng thời nên được tắt hoàn toàn khi không hoạt động với CA.
> Lưu ý: Phần cuối cùng của hướng dẫn này là tùy chọn nếu bạn muốn tìm hiểu về cách ký và thu hồi chứng chỉ. Nếu bạn chọn hoàn thành các bước thực hành đó, bạn sẽ cần một máy chủ Ubuntu 20.04 thứ hai hoặc bạn cũng có thể sử dụng máy tính Linux cục bộ của riêng mình chạy Ubuntu hoặc Debian hoặc các bản phân phối có nguồn gốc từ một trong hai máy đó.
### 1. Cài đặt Easy-RSA
Đầu tiên cần cài đặt bộ script ***easy-rsa*** trên server CA. Đây là một công cụ quản lý CA, có thể dùng để tạo private key và public root key. Sau đó bạn sẽ dùng key này để ký các request từ client và server.

Đăng nhập vào CA Server bằng user non-root với quyền sudo
```console
sudo apt update
sudo apt install easy-rsa
```
###  2. Chuẩn bị thư mục Public Key Infrastructure (PKI)
Sau khi cài đặt easy-rsa, bạn cần tạo một PKI trên CA Server để bắt đầu việc xây dựng CA. Lưu ý rằng bạn không được chạy quyền sudo cho bất kỳ lệnh nào dưới đây, vì ta cần sử dụng user thường để quản lý và tương tác với CA
```console
mkdir ~/easy-rsa
```
Lệnh này sẽ tạo một thư mục mới có tên easy-rsa trong home folder. Bạn sẽ dùng thư mục này để tạo các liên kết tượng trưng (symbolic link – symlink) trỏ đến các file package easy-rsa mà bạn đã tạo ở bước trước. Những file này được lưu trữ trong thư mục /usr/share/easy-rsa trên CA server

Chạy lệnh sau để tạo symlink:
```console
ln -s /usr/share/easy-rsa/* ~/easy-rsa/
```
Việc sử dụng symlink sẽ giúp tự động cập nhật mọi thay đổi từ package easy-rsa lên script PKI, tiện lợi hơn rất nhiều.

Tiếp theo cần giới hạn truy cập vào thư mục PKI mới. Hãy dùng lệnh sau để bảo đảm chỉ chủ sở hữu mới có quyền truy cập vào thư mục này
```console
chmod 700 /home/BMC/easy-rsa
```
Khởi tạo PKI bên trong thư mục easy-rsa:
```console
cd ~/easy-rsa
./easyrsa init-pki
```
Output
```console
Output
init-pki complete; you may now create a CA or requests.
Your newly created PKI dir is: /home/sammy/easy-rsa/pki
```
### 3. Tạo Certificate Authority
Đầu tiên ta cần viết một số giá vị mặc định vào file **vars**. Dùng hai lệnh dưới đây để vào thư mục easy-rsa và mở file vars bằng nano
```console
cd ~/easy-rsa
nano vars
```
Sau đó paste các dòng dưới đây, trong đó thay các xâu trong cặp dấu ngoặc kép thành thông tin tổ chức tương ứng của bạn, lưu ý không để bất kỳ giá trị nào trống
```console
~/easy-rsa/vars
set_var EASYRSA_REQ_COUNTRY    "VN"
set_var EASYRSA_REQ_PROVINCE   "HaNoi"
set_var EASYRSA_REQ_CITY            "Ha Noi Capital"
set_var EASYRSA_REQ_ORG            "BMC"
set_var EASYRSA_REQ_EMAIL         "bmc@bmc.com"
set_var EASYRSA_REQ_OU              "Community"
set_var EASYRSA_ALGO                  "ec"
set_var EASYRSA_DIGEST               "sha512"
```
Bây giờ bạn có thể bắt đầu xây dựng CA của mình.

Trước hết bạn cần tạo cặp public và private key cho root. Chạy lệnh ./easy-rsa với option build-ca như sau
```console
./easyrsa build-ca
```
Trong output bạn sẽ thấy một số dòng chứa thông tin phiên bản của OpenSSL, đồng thời được yêu cầu nhập passphrase cho key pair. Lưu ý hãy chọn một passphrase đủ mạnh mà vẫn ghi nhớ được vì bạn cần nhập mật khẩu mỗi khi tương tác với CA.

Tiếp theo, xác nhận Common Name (CN) cho CA. Đây là tên được dùng để chỉ máy đang sử dụng, theo ngữ cảnh của CA. Nhập một tên bất kỳ hoặc nhấn ENTER để tiếp tục với tên mặc định
```console
Output
. . .
Enter New CA Key Passphrase:
Re-Enter New CA Key Passphrase:
. . .
Common Name (eg: your user, host, or server name) [Easy-RSA CA]:

CA creation complete and you may now import and sign cert requests.
Your new CA certificate file for publishing is at:
/home/BMC/easy-rsa/pki/ca.crt
```
Để tránh yêu cầu mật khẩu mỗi khi sử dụng CA thì bạn có thể chạy lệnh build-ca với option nopass
```console
./easyrsa build-ca nopass
```
Sau bước trên thì ta sẽ có hai file quan trọng: **~/easy-rsa/pki/ca.crt** và **~/easy-rsa/pki/private/ca.key**, tạo nên các thành phần public và private tương ứng của CA

- **ca.crt** là file chứng chỉ của CA. Các user, server và client sẽ dùng chứng chỉ này để xác thực xem mình có thuộc cùng một web được tin cậy hay không. Mọi user và server sử dụng CA đều cần có một bản copy của file này. Tất cả các bên sẽ dựa vào chứng chỉ public để xác thực xem có kẻ tấn công nào đang mạo danh hệ thống để thực hiện tấn công Man-in-the-middle hay không.
- **ca.key** là private key mà CA dùng để ký chứng chỉ cho server và client. Nếu một kẻ tấn công có quyền truy cập vào CA hay file ca.key thì bạn cần hủy CA càng sớm càng tốt. Do đó, file ca.key chỉ nên được lưu trữ trên máy CA, đồng thời máy này cũng nên tắt mỗi khi không làm việc với chứng chỉ.
### 4. Phân phối chứng chỉ public của Certificate Authority
Sau khi cấu hình xong, CA có thể bắt đầu hoạt động như một root được tin cậy cho bất kỳ hệ thống nào muốn cấu hình để sử dụng. Bạn có thể thêm chứng chỉ của CA vào server OpenVPN, web server, mail server và nhiều hệ thống khác nữa. Bất kỳ user hay server nào cần xác minh danh tính của một user hay server khác trong mạng đều cần có một bản copy của file ca.crt trên kho lưu trữ chứng chỉ của hệ điều hành.

Để import chứng chỉ public của CA vào một hệ thống Linux thứ hai như server hay máy cục bộ, đầu tiên bạn cần có một bản copy của file ca.crt từ server CA. Bạn có thể dùng lệnh cat để hiển thị nội dung của file này ra terminal, sau đó copy rồi paste vào một file trên máy cần import chứng chỉ. Bên cạnh đó bạn cũng có thể dùng một số công cụ như scp hay rsync để truyền file giữa các hệ thống. Bài viết này sẽ làm theo cách ban đầu.

Trước tiên, mở nội dung của file bằng lệnh sau:
```console
cat ~/easy-rsa/pki/ca.crt
```
Output
```console
Output
-----BEGIN CERTIFICATE-----
MIIDSzCCAjOgAwIBAgIUcR9Crsv3FBEujrPZnZnU4nSb5TMwDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLRWFzeS1SU0EgQ0EwHhcNMjAwMzE4MDMxNjI2WhcNMzAw
. . .
. . .
-----END CERTIFICATE-----
```
Copy tất cả nội dung, bao gồm cả dòng **-----BEGIN CERTIFICATE-----** và **-----END CERTIFICATE-----**

Ở trên máy Linux thứ hai, mở file /tmp/ca.crt bằng một text editor bất kỳ
```console
nano /tmp/ca.crt
```
Sau đó paste nội dung vừa copy ở CA Server vào. Cuối cùng là lưu rồi đóng file lại.

Như vậy là bạn đã có một bản sao của file ca.crt trên máy Linux thứ hai. Bây giờ bạn có thể import chứng chỉ bằng các lệnh dưới đây.

Đối với các hệ thống dựa trên Ubuntu và Debian
```console
sudo cp /tmp/ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```
Để import chứng chỉ của CA Server vào các máy dựa trên CentOS, Fedora hay RedHat thì hãy copy và paste nội dung của file vào file /tmp/ca.crt trên hệ thống. Tiếp theo bạn cần copy chứng chỉ vào /etc/pki/ca-trust/source/anchors rồi chạy lệnh update-ca-trust
```console
sudo cp /tmp/ca.crt /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust
```
Bây giờ máy Linux thứ hai sẽ tin cậy mọi chứng chỉ được ký bởi CA Server
> Lưu ý: Nếu bạn đang sử dụng CA của mình với các máy chủ web và sử dụng Firefox làm trình duyệt, bạn sẽ cần nhập trực tiếp chứng chỉ ca.crt công khai vào Firefox. Firefox không sử dụng kho lưu trữ chứng chỉ của hệ điều hành cục bộ. Để biết chi tiết về cách thêm chứng chỉ CA của bạn vào Firefox, vui lòng xem bài viết hỗ trợ này từ Mozilla về Thiết lập tổ chức phát hành chứng chỉ (CA) trong Firefox.

> Nếu bạn đang sử dụng CA của mình để tích hợp với môi trường Windows hoặc máy tính để bàn, vui lòng xem tài liệu về cách sử dụng certutil.exe để cài đặt chứng chỉ CA.

### (Không bắt buộc) – Thu hồi chứng chỉ và tạo yêu cầu ký xác thực chứng chỉ
Một yêu cầu ký chứng chỉ (Certificate Signing Request – CSR) bao gồm hai phần: một public key xác định thông tin về hệ thống đang request, và một chữ ký được tạo bằng private key của bên request. Private key sẽ được giữ kín, được dùng để mã hóa thông tin và có thể được giải mã bằng public key.

Các bước dưới đây có thể được chạy trên hệ thống Ubuntu hoặc Debian thứ hai. Ngoài ra hệ thống này cũng có thể là một server từ xa hay một máy Linux local. Vì easy-rsa không có sẵn trên mọi hệ thống nên ta sẽ dùng công cụ openssl để tạo một chứng chỉ và private key.

Chạy lệnh dưới đây để cài đặt openssl:
```console
sudo apt update
sudo apt install openssl
```
Bây giờ bạn cần tạo generate một private key để bắt đầu việc tạo CSR. Đối với công cụ openssl, hãy tạo một thư mục practice-csr rồi generate key bên trong đó. Ví dụ này sẽ tạo request cho một server có tên BMC-server
```console
mkdir ~/practice-csr
cd ~/practice-csr
openssl genrsa -out BMC-server.key
```
Output
```console
Output
Generating RSA private key, 2048 bit long modulus (2 primes)
. . .
. . .
e is 65537 (0x010001)
```
Bây giờ bạn đã có một private key để tạo CSR. Sử dụng công cụ openssl, sau đó bạn sẽ được yêu cầu điền một số trường thông tin như Country, State hay City. Bạn có thể nhấn . nếu muốn bỏ qua một trường, tuy nhiên bạn nên nhập đúng thông tin vị trí và tổ chức khi tạo CSR
```console
openssl req -new -key BMC-server.key -out BMC-server.req
```
Output
```console
Output
. . .
-----
Country Name (2 letter code) [XX]:VN
State or Province Name (full name) []:Ho Chi Minh
Locality Name (eg, city) [Default City]:Ho Chi Minh City
Organization Name (eg, company) [Default Company Ltd]:BMCHosting
Organizational Unit Name (eg, section) []:Community
Common Name (eg, your name or your server's hostname) []:BMC-server
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
```
Nếu muốn tự động thêm các giá trị này vào lệnh gọi openssl thì bạn cũng có thể truyền thêm đối số subj vào lệnh như sau:
```console
openssl req -new -key BMC-server.key -out server.req -subj \
/C=VN/ST=Ho\ Chi\ Minh/L=Ho\ Chi \ Minh\ City/O=BMCHosting/OU=Community/CN=BMC-server
```
Để xác thực nội dung của CSR, bạn có thể đọc một file request bằng openssl rồi kiểm tra các trường thông tin bên trong
```console
openssl req -in BMC-server.req -noout -subject

#Output
subject=C = VN, ST = Ho Chi Minh, L = Ho Chi Minh City, O = BMCHosting, OU = Community, CN = BMC-server
```
Sau khi hoàn tất, copy file BMC-server.req vào CA Server bằng lệnh scp:
```console
scp BMC-server.re BMC@your_ca_server_ip:/tmp/BMCBMC-server.req
```
Ở bước này, bạn đã tạo một yêu cầu ký chứng chỉ CSR cho server BMC-server. Trong thực tế, yêu cầu này có thể được thực hiện khi cần một chứng chỉ TLS để kiểm thử trong giai đoạn stage hoặc develop của web server; hay từ một server OpenVPN cần yêu cầu chứng chỉ để user có thể kết nối đến. Trong bước tiếp theo ta sẽ thử ký một CSR bằng private key của CA Server.

REF: https://vietnix.vn/cach-thiet-lap-va-cau-hinh-certificate-authority-tren-ubuntu-20-04/

https://cloudfly.vn/techblog/cach-thiet-lap-va-dinh-cau-hinh-certificate-authority-ca-tren-ubuntu-2004

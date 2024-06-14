# OPENVPN server setup STEP BY STEP
OpenVPN là một giải pháp Transport Layer Security VPN (TLS)

## Requisites
- 01 máy chủ Ubuntu có **sudo non-root user** và **firewall enabled** -> OpenVPN server

- 01 máy chủ Ubuntu riêng biệt được thiết lập làm Certificate Authority (Cơ quan cấp chứng chỉ - CA) riêng -> CA Server
> Lưu ý: Về mặt kỹ thuật có thể sử dụng OpenVPN server hoặc máy local làm CA, NHƯNG không nên vì nó mở ra một số lỗ hổng bảo mật cho VPN. Theo tài liệu chính thức của OpenVPN, CA nên được đặt trên một máy độc lập dành riêng cho việc **import** và **sign** các yêu cầu chứng chỉ.
## Cài đặt OpenVPN và Easy-RSA
Easy-RSA là công cụ quản lý cơ sở hạ tầng khóa công khai (PKI) mà chúng ta sẽ sử dụng trên OpenVPN server để tạo yêu cầu chứng chỉ - thứ mà chúng ta sẽ xác minh trên CA.
```console
$ sudo apt update
$ sudo apt install openvpn easy-rsa
```
Tạo một thư mục mới ***~/easy-rsa*** trên OpenVPN server với tư cách là non-root user:
```console
$ mkdir ~/easy-rsa
```
Tạo symbolic link từ tập lệnh ***easyrsa*** mà gói đã cài đặt vào thư mục ***~/easy-rsa*** vừa tạo -> mọi cập nhật đối với gói ***easy-rsa*** sẽ tự động được phản ánh trong tập lệnh PKI
```console
$ ln -s /usr/share/easy-rsa/* ~/easy-rsa/
```
Đảm bảo chủ sở hữu của thư mục là ***non-root sudo user*** và hạn chế quyền truy cập đối với người dùng đó bằng chmod:
```console
$ sudo chown bmc ~/easy-rsa
$ chmod 700 ~/easy-rsa
```
Bước tiếp theo là tạo Public Key Infrastructure (Cơ sở hạ tầng khóa công khai - PKI) trên máy chủ OpenVPN để có thể yêu cầu và quản lý chứng chỉ TLS cho máy khách và các máy chủ khác sẽ kết nối đến VPN server.
## Tạo PKI cho OpenVPN
Cần tạo một thư mục Public Key Infrastructure cục bộ trên máy chủ OpenVPN -> Sử dụng thư mục này để quản lý các yêu cầu chứng chỉ của máy chủ và máy khách thay vì thực hiện chúng trực tiếp trên máy chủ CA
```console
$ cd ~/easy-rsa

# Để tạo thư mục PKI trên máy chủ OpenVPN, sẽ cần điền vào một tệp có tên là vars với một số giá trị mặc định
$ nano vars
```
Trên server OpenVPN, file ***vars*** này chỉ cần đúng hai dòng sau vì chúng ta không cần sử dụng nó như một CA
```
set_var EASYRSA_ALGO "ec"
set_var EASYRSA_DIGEST "sha512"
```
Các dòng này giúp đảm bảo private key và những yêu cầu chứng chỉ được cấu hình để sử dụng thuật toán Elliptic Curve Cryptography (ECC) để khởi tạo key, giúp bảo mật các chữ ký cho client và server OpenVPN.

Vì cả server OpenVPN và CA đều sử dụng thuật toán ECC nên khi một client và server cố gắng xây dựng một key đối xứng dùng chung, cả hai có thể dùng thuật toán này cho quá trình trao đổi. Thuật toán này giúp việc trao đổi nhanh hơn so với thuật toán RSA với Diffie-Hellman thông thường.

Tạo thư mục PKI:
```console
$ ./easyrsa init-pki
```
> Lưu ý: Không cần phải tạo một CA trên server OpenVPN, vì server CA chỉ có nhiệm vụ xác minh và ký các chứng chỉ. PKI trên server VPN chỉ được dùng như một nơi lưu trữ tập trung, tiện lợi cho các yêu cầu chứng chỉ
## Tạo một yêu cầu chứng chỉ server OpenVPN và private key
Cần tạo một private key và yêu cầu ký chứng chỉ (Certificate Signing Request – CSR) trên server OpenVPN. Ở bước này, chúng ta sẽ chuyển yêu cầu đến CA để ký và tạo chứng chỉ được yêu cầu. Sau đó, chứng chỉ này được chuyển về lại server OpenVPN rồi cài đặt để server sử dụng
```console
$ cd ~/easy-rsa
```
Gọi lệnh ***easyrsa*** với option ***gen-req***, theo sau là một Common Name (CN) cho máy. CN có thể là bất kỳ tên nào, trong ví dụ này là ***server***. Option ***nopasss*** để bỏ qua việc bảo vệ file được yêu cầu bằng mật khẩu, giúp tránh các vấn đề liên quan đến quyền truy cập
```console
$ ./easyrsa gen-req server nopass
```
Như vậy, chúng ta đã tạo được private key và một file yêu cầu chứng chỉ (server.req)
```console
Output
Common Name (eg: your user, host, or server name) [server]:
 
Keypair and certificate request completed. Your files are:
req: /home/BMC/easy-rsa/pki/reqs/server.req
key: /home/BMC/easy-rsa/pki/private/server.key
```
Copy server key vào thư mục ***/etc/openvpn/server***
```console
$ sudo cp /home/BMC/easy-rsa/pki/private/server.key /etc/openvpn/server/
```
Sau bước này, chúng ta đã tạo thành công private key và một CSR cho server OpenVPN. Bây giờ cần sử dụng private key của server CA để ký CSR này
## Ký Certificate Request của server OpenVPN
Server CA cần phải biết thông tin về chứng chỉ của OpenVPN server và xác thực nó. Sau khi xác thực và gửi chứng chỉ về lại server OpenVPN, client tin cậy CA cũng sẽ tin tưởng server OpenVPN.

Mở server OpenVPN, sử dụng SCP (hoặc một phương pháp truyền dữ liệu bất kỳ) để copy yêu cầu ***server.req*** sang server CA:
```console
$ scp /home/BMC/easy-rsa/pki/reqs/server.req CA_bmc@ca_server_ip:/tmp
```
Đăng nhập vào server CA bằng ***user non-root***, vào thư mục ***~/easy-rsa*** rồi import yêu cầu:
```console
$ cd ~/easy-rsa
$ ./easyrsa import-req /tmp/server.req server
```
Output: 
```
Output
. . .
The request has been successfully imported with a short name of: server
You may now use this name to perform signing operations on this request.
```

Ký request bằng script easyrsa theo syntax: option sign-req/ loại request (client or server)/ Common Name
```console
$ ./easyrsa sign-req server server
```
> Lưu ý: Nếu đã mã hóa private key của CA, cần nhập mật khẩu khi được yêu cầu

Như vậy là đã ký thành công request từ server OpenVPN. Kết quả thu được là một file ***server.crt*** chứa public key của server OpenVPN và chữ ký từ server CA. Chữ ký này giúp xác minh với mọi người rằng ai tin cậy server CA đều có thể tin cả server OpenVPN khi kết nối.

Để hoàn tất việc cấu hình chứng chỉ, copy file ***server.crt*** và ***ca.crt*** from server CA vào OpenVPN:
```console
$ scp pki/issued/server.crt BMC@your_vpn_server_ip:/tmp
$ scp pki/ca.crt BMC@your_vpn_server_ip:/tmp
```
Về lại server OpenVPN, copy file từ ***/tmp*** sang ***/etc/openvpn/server***
```console
$ sudo cp /tmp/{server.crt,ca.crt} /etc/openvpn/server
```
Như vậy là việc cấu hình server OpenVPN đã gần như hoàn tất. Bây giờ là các bước thực hiện thêm một số bước bảo mật để đảm bảo an toàn cho server
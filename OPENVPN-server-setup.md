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
## Cấu hình tài liệu mật mã OpenVPN
Để tăng thêm bảo mật cho server, chúng ta sẽ bổ sung một private key dùng chung - được chia sẻ giữa server và mọi client với chỉ thị **tls-crypt** của OpenVPN. Option này được dùng để xáo trộn chứng chỉ TLS được dùng khi một server và client kết nối đến nhau ban đầu (khóa này được sử dụng trong quá trình thiết lập kết nối TLS ban đầu giữa máy chủ và máy khách).

Bên cạnh đó, nó cũng được sử dụng bởi server OpenVPN để thực hiện việc kiểm tra nhanh các packet đến. Nếu một packet được ký bằng key dùng chung trước đó thì server sẽ xử lý nó. Ngược lại, nếu packet chưa được ký thì server có thể hủy bỏ mà không cần thực hiện công đoạn giải mã.

Với lớp bảo mật này, server OpenVPN có thể được bảo vệ khỏi các lưu lượng truy cập không được xác thực hay tấn công DDoS. Đồng thời việc này cũng giúp việc xác định lưu lượng mạng OpenVPN khó khăn hơn.

Chạy lệnh dưới đây trong thư mục ***~easy-rsa*** của server OpenVPN để tạo ***key dùng chung tls-crypt***
```console
$ cd ~/easy-rsa
$ openvpn --genkey --secret ta.key
```
Sao chép nó vào thư mục ***/etc/openvpn/server/***
```console
$ sudo cp ta.key /etc/openvpn/server
```
Bây giờ chúng ta có thể sẵn sàng tạo chứng chỉ client và file key cho user để kết nối đến VPN.

## Tạo một chứng chỉ client và key pair
Cần tạo một client key và một cặp chứng chỉ. Nếu có nhiều hơn một client thì lặp lại quá trình từ đầu cho từng client. Ví dụ cho ***client1***

Tạo thư mục để lưu trữ chứng chỉ client và các tệp chính:
```console
$ mkdir -p ~/client-configs/keys
```
Cần phải lưu trữ an toàn các file cấu hình và chứng chỉ/key pair của client trong thư mục này nên ta cần giới hạn quyền truy cập
```console
$ chmod -R 700 ~/client-configs
```
Chạy script ***easyrsa*** với option gen-req/ nopass/ common name
```console
$ cd ~/easy-rsa
$ ./easyrsa gen-req client1 nopass
```
Enter để xác nhận common name. Tiếp đến, copy file client1.key vào thư mục ***~/client-configs/keys/*** vừa tạo trước đó
```console
$ cp pki/private/client1.key ~/client-configs/keys/
```
Chuyển file ***client1.req*** vào server CA
```console
$ scp pki/reqs/client1.req BMC@_CA_server_ip:/tmp
```
Đăng nhập vào server CA, vào thư mục EasyRSA rồi ***import*** yêu cầu:
```console
$ cd ~/easy-rsa
$ ./easyrsa import-req /tmp/client1.req client1
```
Tiếp theo, ký yêu cầu này bằng quy trình tương tự với các bước trên, trong đó đổi loại request thành ***client***
```console
$ ./easyrsa sign-req client client1
```
Nhập ***yes*** để xác thực khi được yêu cầu, và nhập mật khẩu nếu cần.

Sau đó chúng ta sẽ có được một file chứng chỉ ***client1.crt***. Bây giờ chuyển file này về lại server VPN
```console
$ scp pki/issued/client1.crt BMC@_server_ip:/tmp
```
Trên server OpenVPN, copy chứng chỉ vào thư mục ***~/client-configs/keys/***
```console
$ cp /tmp/client1.crt ~/client-configs/keys/
```
Sao chép các tệp ***ca.crt***; ***ta.key*** vào thư mục ***~/client-configs/keys/*** và đặt các quyền thích hợp cho sudo user
```console
$ cp ~/easy-rsa/ta.key ~/client-configs/keys/
$ sudo cp /etc/openvpn/server/ca.crt ~/client-configs/keys/
$ sudo chown BMC.BMC ~/client-configs/keys/*
```
Như vậy là chúng ta đã hoàn tất việc khởi tạo chứng chỉ và các key cho client và server, được chứa trong thư mục của server OpenVPN. Tiếp theo là thực hiện cấu hình OpenVPN.
## Cấu hình OpenVPN
Cấu hình server OpenVPN dựa trên một ***file config mẫu*** từ tài liệu hướng dẫn của phần mềm

Copy file mẫu ***server.conf***
```console
$ sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/server/
$ sudo gunzip /etc/openvpn/server/server.conf.gz
$ sudo nano /etc/openvpn/server/server.conf
```
Tìm phần ***HMAC*** bằng cách tìm directive tls-auth. Comment dòng này bằng cách thêm dấu ; ở đầu. Sau đó thêm một dòng ở sau chứa giá trị ***tls-crypt ta.key***
```console
;tls-auth ta.key 0 # This file is secret
tls-crypt ta.key
```
Tìm phần mã hóa mật mã bằng cách tìm dòng cipher. Giá trị mặc định đang là ***AES-256-CBC***. Comment dòng này, thêm dấu ; ở trước rồi thêm dòng dưới đây để dùng phương pháp mã hóa ***AES-256-GCM*** – có hiệu năng tốt hơn và hỗ trợ các client OpenVPN đời mới hiệu quả hơn
```console
;cipher AES-256-CBC
cipher AES-256-GCM
```
Thêm một lệnh ***auth*** ngay sau 2 dòng trên để chọn thuật toán HMAC. Đối với điều này, SHA256 là một lựa chọn tốt
```console
auth SHA256
```
Tìm dòng chứa directive ***dh*** (định nghĩa tham số cho Diffie-Hellman). Vì chúng ta đã cấu hình cho chứng chỉ dùng thuật toán ECC ở bước trên nên không cần tệp gốc Diffie-Hellman, comment dòng này. Sau đó thêm dòng ***dh none***
```console
;dh dh2048.pem
dh none
```
Tiếp theo, nếu muốn OpenVPN chạy mà không có đặc quyền nào, cần yêu cầu phần mềm chạy bằng ***user nobody*** và ***group nogroup***. Tìm rồi uncomment và bỏ dấu ; ở các dòng tương ứng sau
```console
user nobody
group nogroup
```
## Thay đổi cấu hình mạng của server OpenVPN

Có một số khía cạnh của cấu hình mạng của server cần được điều chỉnh để OpenVPN có thể định tuyến chính xác lưu lượng truy cập qua VPN. Đầu tiên trong số này là IP forwarding, một phương pháp để xác định nơi lưu lượng IP sẽ được định tuyến. Điều này rất cần thiết cho chức năng VPN mà server sẽ cung cấp.

Để điều chỉnh cài đặt chuyển tiếp IP mặc định của máy chủ OpenVPN, mở file ***/etc/sysctl.conf***
```console
$ sudo nano /etc/sysctl.conf

# thêm dòng sau vào phía dưới file

net.ipv4.ip_forward = 1

# <> lưu file
```
Đọc file và load các giá trị mới cho phiên hiện tại
```console
$ sudo sysctl -p
```
Bây giờ server OpenVPN sẽ có thể chuyển tiếp lưu lượng ***truy cập đến*** từ thiết bị ethernet này sang thiết bị ethernet khác. Cài đặt này đảm bảo server có thể hướng lưu lượng truy cập từ các máy client kết nối trên giao diện VPN ảo qua các thiết bị ethernet vật lý khác của nó. Cấu hình này sẽ định tuyến tất cả lưu lượng truy cập web từ máy client thông qua địa chỉ IP của server và địa chỉ IP public của client sẽ được ẩn.

Trong bước tiếp theo, cần cấu hình một số quy tắc tường lửa để đảm bảo rằng lưu lượng truy cập đến và đi từ server OpenVPN có thể hoạt động bình thường
## Cấu hình Firewall
Đến đây, chúng ta đã thực hiện cài đặt OpenVPN trên server của mình, cấu hình nó cũng như tạo các key và chứng chỉ cần thiết để client truy cập VPN. Tuy nhiên, vẫn chưa cung cấp cho OpenVPN bất kỳ hướng dẫn nào về nơi gửi lưu lượng truy cập web đến từ client.

Bây giờ chúng ta có thể quy định cách server xử lý lưu lượng của client bằng cách thiết lập một số quy tắc tường lửa và cấu hình định tuyến.

Giả sử chúng ta đã cài đặt và chạy ***ufw*** trên máy server, để cho phép OpenVPN đi qua tường lửa thì bạn sẽ cần bật chế độ ***masquerading (giả mạo)***, một khái niệm iptables cung cấp dịch địa chỉ mạng động (NAT) nhanh chóng để định tuyến chính xác các kết nối của client.

Đầu tiên, tìm giao diện mạng public của máy bằng lệnh sau:
```console
$ ip route list default
```
Giao diện này sẽ nằm trong output của lệnh, ở sau từ ***dev***. Như ví dụ output dưới đây thì giao diện sẽ là ***eth0***
```console
Output
default via 159.65.160.1 dev `eth0` proto static
```
Mở file ***/etc/ufw/before.rules*** để thêm cấu hình liên quan
```console
$ sudo nano /etc/ufw/before.rules
```
Các quy tắc UFW thường được thêm bằng lệnh ***ufw***. Các quy tắc có trong file ***before.rules*** được đọc và đặt vào trước khi các quy tắc UFW được load. Ở phía trên file, thêm một số dòng như dưới đây. 

Các dòng này sẽ đặt chính sách mặc định của chuỗi ***POSTROUTING*** trong bảng ***nat*** và giả mạo mọi lưu lượng đến từ VPN. Hãy lưu ý thay eth0 trong dòng ***-A POSTROUTING*** thành giao diện tương ứng có được từ lệnh trên
```console
#
# rules.before
#
# Rules that should be run before the ufw command line added rules. Custom
# rules should be added to one of these chains:
#   ufw-before-input
#   ufw-before-output
#   ufw-before-forward
#

#đoạn thêm

# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to eth0 (change to the interface you discovered!)
-A POSTROUTING -s 10.8.0.0/8 -o eth0 -j MASQUERADE
COMMIT
# END OPENVPN RULES

#hết đoạn thêm

# Don't delete these required lines, otherwise there will be errors
*filter
```
Lưu file. Bây giờ, cần yêu cầu UFW cho phép các packet được chuyển tiếp theo mặc định. Mở file ***/etc/default/ufw***
```console
$ sudo nano /etc/default/ufw
```
Tìm directive ***DEFAULT_FORWARD_POLICY*** rồi đổi giá trị từ DROP thành ACCEPT:
```console
DEFAULT_FORWARD_POLICY="ACCEPT"
```

Tiếp theo, thay đổi firewall để cho phép các lưu lượng đến OpenVPN. Nếu chưa thay đổi port và giao thức trong file ***/etc/openvpn/server.conf*** thì cần mở các lưu lượng UDP cho port 1194. Nếu đã thay đổi port và giao thức ở bước trên thì hãy thay thành giá trị tương ứng
```console
$ sudo ufw allow 1194/udp

#cho SSH port
$ sudo ufw allow OpenSSH
```
Sau đó disable rồi enable lại UFW để restart và load các thay đổi
```console
$ sudo ufw disable
$ sudo ufw enable
```
## Khởi động OpenVPN
OpenVPN hoạt động như một dịch vụ ***systemd*** nên có thể quản lý bằng ***systemctl***. Trước tiên cấu hình OpenVPN để khởi động khi boot hệ thống
```console
$ sudo systemctl -f enable openvpn-server@server.service
$ sudo systemctl start openvpn-server@server.service
$ sudo systemctl status openvpn-server@server.service
```
Output
```console
Output
● openvpn-server@server.service - OpenVPN service for server
     Loaded: loaded (/lib/systemd/system/openvpn-server@.service; enabled; vendor preset: enabled)
     Active: active (running) since Wed 2020-04-29 15:39:59 UTC; 6s ago
       Docs: man:openvpn(8)
             https://community.openvpn.net/openvpn/wiki/Openvpn24ManPage
             https://community.openvpn.net/openvpn/wiki/HOWTO
   Main PID: 16872 (openvpn)
     Status: "Initialization Sequence Completed"
      Tasks: 1 (limit: 1137)
     Memory: 1.0M
     CGroup: /system.slice/system-openvpn\x2dserver.slice/openvpn-server@server.service
             └─16872 /usr/sbin/openvpn --status /run/openvpn-server/status-server.log --status-version 2 --suppress-timestamps --c>
. . .
. . .
Apr 29 15:39:59 ubuntu-20 openvpn[16872]: Initialization Sequence Completed
```
## Tạo cơ sở hạ tầng cấu hình client
Việc tạo các file cấu hình cho client OpenVPN có thể tương đối phức tạp, vì mọi client phải có cấu hình riêng và mỗi máy phải phù hợp với các cài đặt được nêu trong file cấu hình của server. Thay vì viết một file cấu hình duy nhất chỉ có thể được sử dụng trên một client, bước này sẽ trình bày quy trình xây dựng cơ sở hạ tầng cấu hình client mà chúng ta có thể sử dụng để tạo các file cấu hình nhanh chóng.

Trước tiên, tạo một file cấu hình “cơ sở - base”, sau đó xây dựng một script cho phép bạn tạo các file cấu hình client, chứng chỉ và key nếu cần.

Tạo một thư mục mới để lưu trữ các file cấu hình client trong thư mục ***client-configs*** đã tạo trước đó
```console
$ mkdir -p ~/client-configs/files
```
Copy một file cấu hình mẫu vào thư mục ***client-configs*** để dùng làm cấu hình cơ sở
```console
$ cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf

$ nano ~/client-configs/base.conf
```
Tìm directive ***remote***. Directive này trỏ đến **địa chỉ server OpenVPN – địa chỉ IP public của server**. Nếu muốn đổi port mà server nghe thì bạn phải đổi giá trị 1194 thành port tương ứng
```console
. . .
# The hostname/IP and port of the server.
# You can have multiple remote entries
# to load balance between the servers.
remote <your_server_ip> 1194
. . .
```
Đảm bảo rằng giao thức cũng khớp với giao thức dùng trong cấu hình server
```console
proto udp
```
Tiếp theo, uncomment các directive user và group
```console
# Downgrade privileges after initialization (non-Windows only)
user nobody
group nogroup
```
Tìm directive đặt ca, cert và key rồi comment nó
```console
# SSL/TLS parms.
# See the server config file for more
# description. It's best to use
# a separate .crt/.key file pair
# for each client. A single ca
# file can be used for all clients.
;ca ca.crt
;cert client.crt
;key client.key
```
Tương tự, comment cả các directive ***tls-auth*** vì ta sẽ thêm ta.key trực tiếp vào file cấu hình của client
```console
# If a tls-auth key is used on the server
# then every client must also have the key.
;tls-auth ta.key 1
```
Cập nhật các thiết lập cipher và auth đã được thiết lập trong file ***etc/openvpn/server/server.conf***
```console
cipher AES-256-GCM
auth SHA256
```
Tiếp theo, thêm directive ***key-direction*** ở một vị trí bất kỳ trong file, đặt giá trị thành 1 để VPN có thể hoạt động trên máy client
```console
key-direction 1
```
Cuối cùng, comment một số dòng dưới đây để xử lý các phương thức khác nhau mà những client dựa trên Linux có thể sử dụng để phân giải DNS
```console
; script-security 2
; up /etc/openvpn/update-resolv-conf
; down /etc/openvpn/update-resolv-conf
```
Sau đó thêm một số dòng cho những client sử dụng ***systemd-resolved*** để phân giải DNS
```console
; script-security 2
; up /etc/openvpn/update-systemd-resolved
; down /etc/openvpn/update-systemd-resolved
; down-pre
; dhcp-option DOMAIN-ROUTE .
```
Tạo một script để biên dịch cấu hình cơ sở với key, chứng chỉ và file mã hóa tương ứng rồi đặt vào thư mục ***~/client-configs/files***
```console
$ nano ~/client-configs/make_config.sh
```
Thêm các dòng sau
```bash
#!/bin/bash
 
# First argument: Client identifier
 
KEY_DIR=~/client-configs/keys
OUTPUT_DIR=~/client-configs/files
BASE_CONFIG=~/client-configs/base.conf
 
cat ${BASE_CONFIG} \
    <(echo -e '<ca>') \
    ${KEY_DIR}/ca.crt \
    <(echo -e '</ca>\n<cert>') \
    ${KEY_DIR}/${1}.crt \
    <(echo -e '</cert>\n<key>') \
    ${KEY_DIR}/${1}.key \
    <(echo -e '</key>\n<tls-crypt>') \
    ${KEY_DIR}/ta.key \
    <(echo -e '</tls-crypt>') \
    > ${OUTPUT_DIR}/${1}.ovpn
```
Đặt quyền thực thi cho file này
```console
$ chmod 700 ~/client-configs/make_config.sh
```
Script này sẽ tạo một bản sao của file ***base.conf*** mà chúng ta đã tạo, thu thập tất cả các file chứng chỉ và key đã tạo cho client. Sau đó trích xuất nội dung và thêm vào bản sao của file cấu hình cơ sở, sau đó xuất tất cả nội dung này vào một file cấu hình client mới. Khi đó, thay vì phải quản lý riêng các file cấu hình, chứng chỉ và key của client thì tất cả thông tin cần thiết sẽ được lưu trữ ở một vị trí duy nhất.

Nếu sau này cần thêm client mới thì chỉ cần chạy script này để nhanh chóng tạo file cấu hình mới và đảm bảo rằng tất cả thông tin quan trọng được lưu trữ trong một file duy nhất, dễ truy cập
> Lưu ý rằng mỗi khi thêm một client mới, chúng ta cần tạo các khóa và chứng chỉ mới cho client đó, trước khi có thể chạy script này và tạo file cấu hình.
## Tạo cấu hình client
Đến đây, chúng ta có được một chứng chỉ và key client (client1.crt và client1.key). Bây giờ vào thư mục ***~/client-configs*** rồi chạy script dưới đây để tạo một file config cho các thông tin đăng nhập này
```console
$ cd ~/client-configs
$ ./make_config.sh client1
```
Lệnh này sẽ tạo một file mới tên ***client1.ovpn*** trong thư mục ***~client-configs/files***
```console
$ ls ~/client-configs/files
```
Output
```console
Output
client1.ovpn
```
## RUN
### Windows
1. Download ứng dụng client OpenVPN cho Windows tại https://openvpn.net/community-downloads/
2. Copy file ***.opvn*** vào thư mục **C:\Program Files\OpenVPN\config**. 
Khi khởi chạy OpenVPN thì nó sẽ tự động tìm và bật profile
> Lưu ý: phải chạy OpenVPN với tư cách quản trị viên mỗi khi nó được sử dụng, kể cả bằng tài khoản quản trị
### Linux
Cài OpenVPN
```console
$ sudo apt update
$ sudo apt install openvpn
```
#### Cấu hình client sử dụng ***systemd-resolved***

Trước tiên kiểm tra xem hệ thống có đang sử dụng ***systemd-resolved*** để phân giải DNS hay không bằng cách kiểm tra file ***/etc/resolv.conf***
```console
cat /etc/resolv.conf
```
Nếu hệ thống sử dụng ***systemd-reosolved*** để phân giải DNS thì địa chỉ IP sau option nameserver sẽ là ***127.0.0.53***. Để hỗ trợ các client này thì cần cài đặt package ***openvpn-systemd-resolved***

Output
```console

Output
# This file is managed by man:systemd-resolved(8). Do not edit.
. . .

nameserver 127.0.0.53
options edns0
```
```console
$ sudo apt install openvpn-systemd-resolved
```
Cấu hình cho client sử dụng và gửi mọi truy vấn DNS qua giao diện VPN
```console
$ nano client1.ovpn
```
Uncomment các dòng
```console
script-security 2
up /etc/openvpn/update-systemd-resolved
down /etc/openvpn/update-systemd-resolved
down-pre
dhcp-option DOMAIN-ROUTE .
```
#### Cấu hình các client sử dụng update-resolv-conf
Nếu hệ thống không sử dụng ***systemd-resolved*** để quản lý DNS thì hãy kiểm tra phân phối có script ***/etc/openvpn/update-resolv-conf***
```console
$ ls /etc/openvpn

Output
update-resolv-conf
```
Uncomment các dòng
```console
script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf
```
Kết nối
```console
$ sudo openvpn --config client1.ovpn
```

REF: https://cloudfly.vn/techblog/cach-thiet-lap-va-dinh-cau-hinh-may-chu-openvpn-tren-ubuntu-2004-phan-22
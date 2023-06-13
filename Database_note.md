# Database là gì?
> Chương trình độc lập dùng để quản lý dữ liệu (“quản lý” ở đây bao gồm việc  lưu trữ + truy cập) 👉 dữ liệu được tổ chức theo 1 kiến trúc nhất định. 

Mỗi OS lại có kiến trúc quản lý cơ sở dữ liệu riêng:       
+ Window: NTFS, Fat32      
+ Mac: Btrfs      
+ Linux: Ext

Đó là cách hệ điều hành quản lý file trên hệ thống.
## Tại sao lại cần đến Database management system? 
Các cách quản lý file nêu trên chỉ phục vụ mục đích cho một người dùng trên một máy tính cá nhân, nó sẽ không phù hợp với bài toán dữ liệu lớn, khi mà máy tính đó đóng vai trò là Server, phục vụ cho nhiều người dùng 👉 chỉ mỗi hệ thống quản lý file của hệ điều hành là không đủ.
Nên đối với bài toán Big data chúng ta sẽ phải cần đến hệ thống quản lý dữ liệu riêng gọi là **Database management system** *(với các chức năng thêm, xoá , sửa dữ liệu)*
## Phân loại database
+ Relational DB: cơ sở dữ liệu quan hệ

> Các dữ liệu có mqh chặt chẽ với nhau. Hay có thể hiểu là các dữ liệu sẽ được tổ chức thành các hàng, cột (dạng bảng). *Ví dụ: MySQL, PostgreSQL, SQLite* 

+ Non-relational DB: cơ sở dữ liệu phi quan hệ

> Các dữ liệu được tổ chức theo dạng Document, trái ngược với dạng bảng bên trên.  *Ví dụ: MongoDB, Redis* 

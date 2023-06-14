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

## Relational Database
Row ~ Record

Primary key ~ ID: dùng để phân biệt các record với nhau

SQL - Structure Query Language: quy định quy tắc, cú pháp để user viết các lệnh nhằm tương tác, giao tiếp với database. 

> SQL đuọc tính là ngôn ngữ lập trình, thuộc nhóm *Scripting language* 👉 tức là bản thân nó sẽ cần đến trình thông dịch Interpreter 

## Base Command

### Database
+ Tạo mới: CREATE DATABASE _nameDatabase; 
+ Xoá: DROP DATABASE _nameDatabase;
+ Sửa: ALTER DATABASE _nameDatabase;  
```SQL
#list 
postgres=# \l

#describe table  
postgres=# \dt

#change to other DB (c: connect)      
postgres=# \c database2
You are now connected to database "database2" as user "postgres"
database2=#

#change name of DB
postgres=# ALTER DATABASE database2 RENAME TO database3; 

#delete DB
postgres=# DROP DATABASE database3;
```

### Table 
Name of database: DB1
```SQL
#describe table (list of relations)
DB1=# \dt

#structure of table (có cột nào, ràng buộc gì, key ntn?)
DB1=# \d idols
or
DB1=# SELECT * FROM idols;
```
#### Interacting with table (Query tool) 😈 SQL command
```SQL
🔴#thay đổi DATA của Table
#createTable
CREATE TABLE idols(
    id integer NOT NULL PRIMARY KEY,
    name text NOT NULL,
    age integer,
    nb_of_movies integer DEFAULT 1
)

#deleteTale
DROP TABLE idols;

#insertData INSERT INTO _nameTable(_nameColums) VALUES(_values)
INSERT INTO idols(name, id, age) VALUES('QuangHai', 19, 24)

#many record together
INSERT INTO idols(name, id, age) 
VALUES      ('QuangHai', 19, 24),
            ('CongPhung', 10, 26),
            ('Ronalsi', 7, 66)

#readData SELECT _nameColum FROM _nameTable [_clauses]
#thực chất chỉ SELECT mới được coi là dạng lệnh Query (Query trong SQL), còn lại là lệnh bt. SELECT không chỉ được dùng để đọc dữ liệu từ Table mà còn đọc các giá trị đơn lẻ, giống với print, echo.
SELECT * FROM idols         //FROM cũng là mệnh đề
SELECT id, name FROM idols

#đổi tên cột khi hiển thị
SELECT id AS i, name AS n FROM idols

#đọc giá trị đơn 
SELECT 1 + 2 AS tong, name FROM idols

#updateTable (set&delete)
UPDATE idols SET nb_of_movies = 50, age = 29 WHERE id = 3       //WHERE clause thì ❗phải chọn PRIMARY KEY❗

DELETE FROM idols WHERE id = 3

🔴#thay đổi STRUCTURE của Table (tên colume, data type,...)
ALTER TABLE idols
ADD COLUMN birthday DATE NOT NULL DEFAULT '2000-01-01',          // gọi là 1 action
ADD COLUMN gender BOOL

ALTER TABLE idols
RENAME COLUMN gender TO sex     //rename Colums
RENAME TO idol                  //rename Table


ALTER TABLE idols
DROP COLUMN sex
```

## Data Type
> cast the exression: ép kiểu 
+ integer (INT)
+ numeric (DECIMAL)
+ serial - tự động tăng dần giá trị (STT, ID)   //bản chất là kiểu Integer
```SQL
ALTER TABLE idols ADD COLUMN weight DECIMAL
```
+ boolean 
+ character (sử dụng khi muốn giới hạn số lượng ký tự cho data) >< Text (Unlimitted - ví dụ về 1 đoạn văn bản, tiểu sử cá nhân,...)
+ date (Y-M-D) - cách viết phổ biến, tiêu chuẩn quốc tế ISO 8601
+ time with time zone /without time zone
+ date range
+ interval

## Operation + Expression
Toán hạng có thể là 1 trong 3 trường hợp: **giá trị đơn, Column, 1 lệnh SQL khác**
```SQL
SELECT 1 + id FROM idols                //gt đơn + Column
SELECT id + age FROM idols              //Column + Column
SELECT EXISTS (SELECT * FROM idols)     //EXISTS là toán tử dạng Keyword, toán hạng của nó là 1 câu lệnh SQL khác 🆘 Keyword ~ Function 👉 EXISTS dùng để kt xem câu lệnh đó có trả về giá trị gì hay là không?

#toán tử BETWEEN thường được sử dụng để filter
SELECT name FROM idols WHERE age NOT BETWEEN 24 AND 29
```
Phép toán so sánh đặc biệt dành cho những giá trị đặc biệt không thể so sánh được. Vị dụ, cần so sánh gt để biết giá trị có đang **rỗng
** hay không
```SQL
❌SELECT name, age FROM idols WHERE nb_movies != NULL❌

👇

SELECT name, age FROM idols WHERE nb_movies IS NOT NULL
#vậy nên != chỉ được sử dụng để so sánh với các giá trị cụ thể
```
Làm việc với chuỗi ký tự
```SQL
#độ dài chuỗi 🔑 Toán tử dưới dạng Function
SELECT LENGTH('Kim Khuong Duy')

#nối chuỗi
SELECT 'Kim Khuong Duy' || '1997'       //concatenate
SELECT 'Kim Khuong Duy' || 1997         //text + int
SELECT name || age FROM idols           //column + column

#tách chuỗi
SELECT SUBSTRING('Kim Khuong Duy', _startIndex, _sumChar)
#⛔⛔⛔SQL đánh số từ 1 chứ không phải từ 0⛔⛔⛔

#so sánh chuỗi LIKE (LIKE tương đương với toán tử ~~)
LIKE: ~~
NOT LIKE: !~~

#with a Template
SELECT 'abcd' LIKE 'a___'       //text LIKE template
SELECT 'abcdf12344' LIKE 'ab%'       //ký tự '%' đại diện cho toàn bộ những ký tự còn lại, không cần phải dùng đủ số lượng ký tự dấu '_'
SELECT 'abcdf12344' LIKE '%cd%'
SELECT 'abcdf12344' LIKE '%44'
SELECT 'abcdf12344' LIKE '%cd%44'
```
Aggregation - gộp
```SQL
SELECT MIN(age) FROM idols
SELECT MAX(age) FROM idols
SELECT SUM(age) FROM idols
SELECT AVG(age) FROM idols
SELECT COUNT(age) FROM idols
```
## Query data with Clause
👉 Clause dùng để bổ sung thêm các điều kiện ràng buộc cho câu lệnh truy vấn 
```SQL
SELECT * FROM idols
WHERE age BETWEEN 26 AND 29

SELECT * FROM idols
WHERE working               //data type of 'working' is boolean  

UPDATE idols SET age = 28
WHERE id = 3
```
👉 **GROUP BY** dùng để nhóm các bản ghi có dữ liệu trùng nhau ở một cột nào đó
```SQL
SELECT name FROM view_count GROUP BY name
SELECT date FROM view_count GROUP BY date
```
️🥊 Lưu ý: ví dụ bên trên là nhóm cái nào thì select theo cái đó. Trong trường hợp nhóm theo 1 cột nhưng lại select theo cột khác thì những giá trị không chập được (những giá trị nằm ngoài mệnh đề GROUP BY) thì phải đưa chúng vào toán tử Gộp - Aggregation
```SQL
SELECT name, SUM(view_count) FROM view_count GROUP BY name
```
👉 Kết hợp với **WHERE**
```SQL
SELECT name, SUM(view_count) 
FROM view_count 
WHERE date > '2022-01-01'
GROUP BY name
```
👉 Mệnh đề **HAVING** dùng để bổ trợ cho GROUP BY (đi sau GROUP BY). Hoạt động gần giống với WHERE. Điểm khác biệt ở chỗ: WHERE dùng để lọc dữ liệu từ table trong DB, còn HAVING lọc dữ liệu kết quả sau khi đã gộp row bằng GROUP BY. 
```SQL
SELECT name, SUM(view_count) 
FROM view_count 
GROUP BY name
HAVING SUM(view_count) > 5       //đi sau HAVING sẽ là một điều kiện

SELECT date, AVG(view_count) 
FROM view_count 
GROUP BY date
HAVING AVG(view_count) <= 3      //đi sau HAVING sẽ là một điều kiện
```
👉 Sắp xếp dữ liệu trong Table bằng **ORDER BY**
+ ASC: Ascending - tăng dần

+ DESC: Descending - giảm dần
```SQL
#nếu không để mệnh đề ORDER BY thì mặc định sẽ là sắp xếp theo thứ tự tăng dần của PRIMARY KEY
SELECT * FROM idols

#giảm dần
SELECT * FROM idols
ORDER BY age DESC
```
> 🔴 **ORDER BY** đi sau **GROUP BY**, **GROUP BY** đi sau **WHERE** 

👉 Mệnh đề **LIMIT** dùng để giới hạn số row mà chúng ta truy vấn ra từ table
```SQL
#phải đặt sau WHERE, GROUP BY, ORDER BY,... giống như kiểu là bước lọc cuối cùng
SELECT * FROM idols LIMIT 3
```

## Ràng buộc - CONSTRAINT
Là những quy tắc, rules mà chúng ta tạo ra để áp đặt lên data (data ở đây có thể là cả Table, hoặc từng Columns)

️🥊 Mục đích là để tránh được những dữ liệu không hợp lệ được nhập vào DB
> hạn chế thay đổi CONSTRAINT trên 1 table đã có vì có thể sẽ gây lỗi với những dữ liệu cũ, vậy nên cần thiết kế thật chuẩn xác trước khi bắt đầu triển khai.

Liệt kê các CONSTRAINT vào ngay đằng sau data type
```SQL
#thiết lập CONSTRAINT vào sau data type (int)
CREATE TABLE movies (
    id INT NOT NULL,
    title TEXT
)

#xoá CONSTRAINT
ALTER TABLE movies
ALTER COLUMN title DROP NOT NULL

#bổ sung CONSTRAINT cho COLUMN đã có
ALTER TABLE movies
ALTER COLUMN title SET NOT NULL
```
👉 **UNIQUE** được áp đặt cho các Columns, và nó sẽ quy định cho các dữ liệu trong Columns đó không được phép trùng nhau 
```SQL
CREATE TABLE movies (
    id INT PRIMARY KEY,
    title TEXT NOT NULL UNIQUE
)
```
👉 **PRIMARY KEY** là một CONSTRAINT rất quan trọng, bắt buộc phải thiết lập khi tạo Table. Nó đảm bảo tính duy nhất của các record (row) có trong DB 

🆘 Mỗi một Table đều phải có **PRIMARY KEY**. Khá giống với UNIQUE, nhưng UNIQUE là áp trên 1 column, còn PRIMARY KEY thì đảm bảo tính duy nhất của các Rows với nhau và áp dụng cho toàn Table.
> Có thể thiết lập nhiều PRIMARY KEY cho một Table, nhưng thông thường chỉ nên chọn duy nhất 1 cái
```SQL
CREATE TABLE movies (
    id INT PRIMARY KEY,         //PRIMARY KEY ~ NOT NULL + UNIQUE
    title TEXT NOT NULL UNIQUE
)
```
👉 **FOREIGN KEY** được áp đặt cho một column, có quy định tính UNIQUE và đồng thời quy định rằng: *column này chỉ được phép chứa PRIMARY KEY của một Table khác.* 

Giữa những Table có liên quan đến nhau thì chúng có thể lưu KEY của nhau, bảng này lưu KEY của bảng kia.
```SQL
CREATE TABLE movies (
    id INT PRIMARY KEY,
    title TEXT,
    idol_id INT REFERENCES idols(id)        //_nameColumn INT REFERENCES _nameTable(PRIMARY KEY)
)
```
👉 **CHECK** áp đặt cho Column để đảm bảo dữ liệu của nó phải thoả mãn một biểu thức LOGIC nào đấy. 
```SQL
CREATE TABLE movies (
    id INT PRIMARY KEY,
    title TEXT CHECK (LENGTH(title) >= 5),
    idol_id INT REFERENCES idols(id)  
)
```

> NOTE: Tên của Column bản chất như tên của Biến, Column ~ Biến, giá trị thay đổi theo các Row
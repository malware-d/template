# OPENVPN server setup STEP BY STEP
OpenVPN là một giải pháp Transport Layer Security VPN (TLS)

## Requisites
- 01 máy chủ Ubuntu có **sudo non-root user** và **firewall enabled** -> OpenVPN server

- 01 máy chủ Ubuntu riêng biệt được thiết lập làm Certificate Authority (Cơ quan cấp chứng chỉ - CA) riêng -> CA Server
> Lưu ý: Về mặt kỹ thuật có thể sử dụng OpenVPN server hoặc máy local làm CA, NHƯNG không nên vì nó mở ra một số lỗ hổng bảo mật cho VPN. Theo tài liệu chính thức của OpenVPN, CA nên được đặt trên một máy độc lập dành riêng cho việc **import** và **sign** các yêu cầu chứng chỉ.
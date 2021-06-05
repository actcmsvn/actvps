#ActVPS Script

sudo su #Đăng nhập vào root
passwd #Đổi mật khẩu tài khoản root
vi /etc/ssh/sshd_config

PermitRootLogin no  -> yes
PasswordAuthentication no  -> yes
sudo service sshd restart


Chỉnh sửa file /etc/my.cnf tìm dòng  87 và xoá nó
innodb_support_xa=1
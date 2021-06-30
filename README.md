#ActVPS Script

```
ActVPS Script Installer v1.0
To install ActVPS Script type: 

curl -sO https://actcms.work/install && bash install
```

sudo su #Đăng nhập vào root
passwd #Đổi mật khẩu tài khoản root
vi /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
sudo service sshd restart
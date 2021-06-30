#ActVPS Script

<p align="center">
<a href="https://packagist.org/packages/actcmsvn/actvps"><img src="https://poser.pugx.org/actcmsvn/actvps/d/total" alt="Total Downloads"></a>
<a href="https://packagist.org/packages/actcmsvn/actvps"><img src="https://poser.pugx.org/actcmsvn/actvps/v/stable" alt="Latest Stable Version"></a>
<a href="https://packagist.org/packages/actcmsvn/actvps"><img src="https://poser.pugx.org/actcmsvn/actvps/license" alt="License"></a>
</p>

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
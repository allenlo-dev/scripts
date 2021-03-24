# scripts
some linux scripts
  
1. 一键清除阿里云/腾讯云监控  
wget -qO- https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/auto-clean-aliyun-qcloud.sh | bash
  
2. 一键 v2ray vmess 版本  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
9cf38986-5d2b-8158-1419-055ae1f90a08    VLESS协议使用的ID  
myvless                                 VLESS的ws路径  
04b87b96-e511-dc35-3ce9-37e0ccd24bd8    VMESS协议使用的ID  
myvmess                                 VMESS的ws路径  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-v2ray-vmess-caddy.sh) \  
xx.xxxx.com \  
9cf38986-5d2b-8158-1419-055ae1f90a08 \  
myvless \  
04b87b96-e511-dc35-3ce9-37e0ccd24bd8 \  
myvmess  
  
3. 一键 v2ray vless 版本  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
9cf38986-5d2b-8158-1419-055ae1f90a08    VLESS协议使用的ID  
myvless                                 VLESS的ws路径  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-v2ray-vless-caddy.sh) \  
xx.xxxx.com \  
9cf38986-5d2b-8158-1419-055ae1f90a08 \  
myvless  
  
4. 一键 git 服务器 gogs  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-gogs-caddy.sh) \  
xx.xxxx.com  
  
#安装后关闭注册：---> 安装成功后 xx.xxxx.com 即为 gogs 的首页  
#sed -i "s/DISABLE_REGISTRATION   = false/DISABLE_REGISTRATION   = true/g" /home/git/gogs/custom/conf/app.ini  
#chown -R git:git /home/git/gogs/custom/conf/app.ini  
#service gogs restart  
  
5. 一键临时邮箱 forsaken-mail  
注意：VPS需要开启25端口, 这个直接发工单要主机商开启  
     域名解析, 如果你想邮件地址格式都为*@xx.com的形式, 则为xx.com设置MX记录  
参数：  
xx.xxxx.com                             域名  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-forsaken-mail.sh) \  
xx.xxxx.com  
  
6. 一键 qbittorrent & gallery  
注意：使用前，请先把域名a记录的IP地址设置正确  
安装成功后 xx.xxxx.com 即为 gallery 的首页  
xx.xxxx.com:8080 为 qbittorrent 的web管理界面，默认帐号名：admin 默放密码：adminadmin, 登陆后应立即修改  
参数：  
xx.xxxx.com                             域名  
download                                gallery目录使用的根目录  
myuser                                  gallery的用户名  
mypasswd                                gallery的用户密码  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-qbittorrent-gallery.sh) \  
xx.xxxx.com \  
download \  
myuser \  
mypasswd  
  
7. 一键 qbittorrent & h5ai  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-qbittorrent-h5ai.sh) \  
xx.xxxx.com  
  
8. 一键安装 php  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-php-v7.sh) \  
xx.xxxx.com   
  
9. 一键自动同步时间  
参数：  
on/off                                  开启时间同步(on)/关闭时间同步（off)  
"5  0  *  *  1"                         同步时间，默认每个星期一同步一次时间  
![image](https://github.com/allenlo-dev/scripts/blob/master/image/crontab.png)  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/auto-sync-ntp.sh)  
#on "0  0  *  1  *"  
#off  

10. 一键设置自动签到 hostloc  
参数：  
on/off                                  开启时间同步(on)/关闭时间同步(off)  
"[user1]='passwd1' [user2]='passwd2'"   hostloc的帐号与密码，支持多个帐号自动签到  
"5  0  *  *  *"                         同步时间，默认每天 12.05 自动签到  
![image](https://github.com/allenlo-dev/scripts/blob/master/image/crontab.png)  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/auto-login-hostloc.sh) \  
on "[user1]='passwd1' [user2]='passwd2'"  
#on "[user1]='passwd1' [user2]='passwd2'" "15 0  *  *  *"  
#off  
  
11. 一键 xray vmess 版本  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
9cf38986-5d2b-8158-1419-055ae1f90a08    VLESS协议使用的ID  
myvless                                 VLESS的ws路径  
04b87b96-e511-dc35-3ce9-37e0ccd24bd8    VMESS协议使用的ID  
myvmess                                 VMESS的ws路径  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-xray-vmess-caddy.sh) \  
xx.xxxx.com \  
9cf38986-5d2b-8158-1419-055ae1f90a08 \  
myvless \  
04b87b96-e511-dc35-3ce9-37e0ccd24bd8 \  
myvmess  
  
12. 一键 xray vless 版本  
注意：使用前，请先把域名a记录的IP地址设置正确  
参数：  
xx.xxxx.com                             域名  
9cf38986-5d2b-8158-1419-055ae1f90a08    VLESS协议使用的ID  
myvless                                 VLESS的ws路径  
  
bash <(curl -L -s https://raw.githubusercontent.com/allenlo-dev/scripts/master/scripts/install-xray-vless-caddy.sh) \  
xx.xxxx.com \  
9cf38986-5d2b-8158-1419-055ae1f90a08 \  
myvless  

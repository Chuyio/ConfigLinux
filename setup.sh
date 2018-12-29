#!/bin/bash
#Version: 2.0
#owner: AndyWang
#Last updata time: 2018-12-13

SysVer=`cat /etc/redhat-release | awk -F'release' '{print $2}' | awk -F'[ .]+' '{print $2}'`
NetCnf=`ls /etc/sysconfig/network-scripts/ | grep if | head -1`
NetName=`ls /etc/sysconfig/network-scripts/ | grep if | head -1 | awk -F'-' '{print $2}'`
NetPath="/etc/sysconfig/network-scripts/"
YUM='/etc/yum.repos.d'
clear
echo "#####################################"
echo "######       1、配置网络       ######"
echo "######       2、优化系统       ######"
echo "######       3、命令审计       ######"
echo "######       4、配置yum源      ######"
echo "######       5、安装MySQL      ######"
echo "######       6、NEW VPN USER   ######"
echo "######       7、DEL VPN USER   ######"
echo "#####################################"
read -p "Please Input Number (1/2/3/4/5/6/7) :" Nmb
if [ ! $Nmb == 1 ] && [ ! $Nmb == 2 ] && [ ! $Nmb == 3 ] && [ ! $Nmb == 4 ] && [ ! $Nmb == 5 ] && [ ! $Nmb == 6 ] && [ ! $Nmb == 7 ]
then
    echo -e "\033[41;33;5m Input ERROR,you Can only enter 1 or 2 or 3 \033[0m"
    exit 110
fi

Jdt(){
echo "准备中..."
i=0
str=""
arr=("|" "/" "-" "\\")
while [ $i -le 20 ]
do
  let index=i%4
  let indexcolor=i%8
  let color=30+indexcolor
  let NUmbER=$i*5
  printf "\e[0;$color;1m[%-20s][%d%%]%c\r" "$str" "$NUmbER" "${arr[$index]}"
  sleep 0.1
  let i++
  str+='+'
done
printf "\n"
echo "正在执行...稍候！"
}

PanDuan(){
if [ ! $? -eq 0 ]
then
    echo -e "\033[41;33;5m ERROR,Please To Check  \033[0m"
    exit 110
fi
}

C6NetWork(){
cat > $NetPath$NetCnf << END
DEVICE=$NetName
TYPE=Ethernet
ONBOOT=yes
NM_CONTROLLED=yes
BOOTPROTO=static
IPADDR=$Ipa
NETMASK=$Ntm
GATEWAY=$Gtw
DNS1=114.114.114.114
DNS2=223.5.5.5

END

service NetworkManager stop >/dev/null 2>&1
chkconfig NetworkManager off >/dev/null 2>&1
chkconfig network on >/dev/null 2>&1
Jdt
    echo -e "\033[46;35;5m[ ## Network configuration succeeded ## ]\033[0m"
    echo -e "\033[46;35;5m[ ##### Please restart the server ##### ]\033[0m"
}

C7NetWork(){
cat > $NetPath$NetCnf << EOF
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=static
DEFROUTE=yes
IPV4_FAILURE_FATAL=no
NAME=$NetName
DEVICE=$NetName
ONBOOT=yes
IPADDR=$Ipa
NETMASK=$Ntm
GATEWAY=$Gtw
DNS1=223.5.5.5
DNS2=114.114.114.114

EOF

systemctl stop NetworkManager >/dev/null 2>&1
systemctl disable NetworkManager >/dev/null 2>&1
systemctl enable network.service >/dev/null 2>&1
Jdt
    echo -e "\033[46;35;5m[ ## Network configuration succeeded ## ]\033[0m"
    echo -e "\033[46;35;5m[ ##### Please restart the server ##### ]\033[0m"
}

OptSSH(){
echo "#########################################################"
echo -e "\033[46;34;5m[             配置SSH 端口 关闭DNS 反向解析             ]\033[0m"
echo -e "\033[46;34;5m[   关闭此终端后 请使用新SSH端口:$Pt 进行登陆 原端口失效   ]\033[0m"
read -p "Please enter the SSH port :" Pt
Jdt
sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
sed -i "s/#Port 22/Port $Pt/" /etc/ssh/sshd_config
sed -i "s/^Port.*/Port $Pt/g" /etc/ssh/sshd_config
sed -i 's/#PrintMotd yes/PrintMotd yes/' /etc/ssh/sshd_config
case $SysVer in
6)
    service sshd restart >/dev/null 2>&1
    PanDuan
;;
7)
    systemctl restart sshd >/dev/null 2>&1
    PanDuan
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac
}


OffIPv6(){
clear
echo "####################################"
echo -e "\033[46;34;5m[      Shutdown IpV6 关闭IPv6      ]\033[0m"
Jdt
sed -i '/.*net-pf-10.*/d' /etc/modprobe.conf
sed -i '/.*ipv6.*/d' /etc/modprobe.conf
echo "alias net-pf-10 off" >> /etc/modprobe.conf
echo "alias ipv6 off" >> /etc/modprobe.conf
}

OffSE(){
clear
echo "####################################"
echo -e "\033[46;34;5m[         Shutdown selinux         ]\033[0m"
Jdt
sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
setenforce 0 >/dev/null 2>&1
}

OFFfirewalld(){
clear
echo "####################################"
echo -e "\033[46;34;5m[        Shutdown Firewalld        ]\033[0m"
Jdt

case $SysVer in
6)
    service iptables stop >/dev/null 2>&1
    chkconfig iptables off >/dev/null 2>&1
;;
7)
    systemctl stop firewalld >/dev/null 2>&1
    systemctl disable firewalld >/dev/null 2>&1
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac
}

TimeLock(){
clear
echo "####################################"
echo -e "\033[46;34;5m[        Configure TimeLock        ]\033[0m"
Jdt
sed -i '/.*ntpdate.*/d' /var/spool/cron/root
echo "*/5    *    *    *    *    /usr/sbin/ntpdate 202.112.31.197 > /dev/null 2>&1" >> /var/spool/cron/root
case $SysVer in
6)
    service crond restart >/dev/null 2>&1
;;
7)
    systemctl restart crond >/dev/null 2>&1
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac
}

FileLimitsConf(){
cat >> /etc/security/limits.conf << COMMENTBLOCK
*           soft   nofile       102400
*           hard   nofile       102400
*           soft   nproc        102400
*           hard   nproc        102400
COMMENTBLOCK
}

LimitsFile(){
clear
echo "#####################################"
echo -e "\033[46;34;5m[       Configure LimitNumber       ]\033[0m"
Jdt
shu1=`cat /etc/rc.local | grep ulimit | wc -l`
shu2=`cat /etc/security/limits.conf | grep nofile | wc -l`
if [ $shu1 -lt 1 ]
then
    echo "ulimit -SHn 102400" >> /etc/rc.local
fi

if [ $shu2 -lt 2 ]
then
    FileLimitsConf
fi

case $SysVer in
6)
    sed -i 's/1024$/102400/' /etc/security/limits.d/90-nproc.conf
;;
7)
    sed -i 's/4096$/20480/' /etc/security/limits.d/20-nproc.conf
    sed -i 's/^#DefaultLimitNOFILE=.*/DefaultLimitNOFILE=100000/g' /etc/systemd/system.conf
    sed -i 's/^#DefaultLimitNPROC=.*/DefaultLimitNPROC=100000/g' /etc/systemd/system.conf
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac

}

KernelFile(){
clear
echo "#####################################"
echo -e "\033[46;34;5m[          Optimize Kernel          ]\033[0m"
Jdt
true > /etc/sysctl.conf
cat >> /etc/sysctl.conf << EIZ
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.secure_redirects = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
net.ipv4.tcp_syncookies = 1
kernel.msgmnb = 65536
kernel.msgmax = 65536
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.tcp_sack = 1
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 262144
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_fin_timeout = 1
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_probes=3
net.ipv4.tcp_orphan_retries=3
net.ipv4.ip_local_port_range = 1024 65500

EIZ

/sbin/sysctl -p
echo "内核优化的具体参数见上 如需修改请自行修改/etc/sysctl.conf文件"
echo "内核优化的具体参数见上 如需修改请自行修改/etc/sysctl.conf文件"
echo "内核优化的具体参数见上 如需修改请自行修改/etc/sysctl.conf文件"

}

RootEmail(){
clear
echo "#######################################################"
echo -e "\033[46;34;5m[ 禁止 You have new mail in /var/spool/mail/root 提示 ]\033[0m"
Jdt
sed -i '/.*MAILCHECK/d' /etc/profile
echo "unset MAILCHECK">> /etc/profile
source /etc/profile
}

#BieMing(){
#
#}

HisTory(){
#history modify
file_path="/var/log/Command"
file_name="Command.log"
ProFile=`cat /etc/profile | grep HISTORY_FILE | wc -l`
ComMand=`cat /var/spool/cron/root | grep history.sh | wc -l`
CROND='/var/spool/cron/root'

Group1(){
touch $file_path/$file_name
chown -R nobody:nobody $file_path
chmod 001 $file_path
chmod 002 $file_path/$file_name
chattr +a $file_path/$file_name
}
Group2(){
cat >> /etc/profile << EPP
export HISTORY_FILE=$file_path/$file_name
export PROMPT_COMMAND='{ date "+%y-%m-%d %T ## \$(who am i |awk "{print \\\$1,\\\$2,\\\$5}") ## \$(whoami) ## \$(history 1 | { read x cmd; echo "\$cmd"; })"; } >>\$HISTORY_FILE'
EPP
}

if [ ! -d $file_path ]
then
    mkdir -p $file_path
    Group1
else
    if [ ! -f $file_path/$file_name ]
    then
        Group1
    fi
fi
if [ $ProFile -lt 1 ]
then
    Group2
else
    sed -i '/.*HISTORY_FILE.*/d' /etc/profile
    Group2
fi
if [ ! -f $file_path/history.sh ]
then
cat >> $file_path/history.sh << EOF
#!/bin/bash

#Time=\`date +%Y%m%d%H -d '-1 hours'\`
Time=\`date +%Y%m%d%H\`
logs_path="$file_path/"
logs_name="$file_name"
new_file="\$logs_path\$logs_name-\$Time"
old_file=\`find \$logs_path -mtime +30 -type f -name "Command.*"\`
chattr -a \$logs_path\$logs_name
mv \$logs_path\$logs_name \$new_file
chattr +a \$new_file
touch \$logs_path\$logs_name
chown -R nobody:nobody \$logs_path\$logs_name
chmod -R 002 \$logs_path\$logs_name
chattr +a \$logs_path\$logs_name
if [ ! -z \$old_file ]
then
    echo "delet \$old_file \$Time" >> /var/log/messages
    chattr -a \$old_file
    rm -rf \$old_file
fi
EOF

chmod 100 $file_path/history.sh
fi
if [ $ComMand -lt 1 ]
then
    echo "30 10 * * 6 /bin/bash $file_path/history.sh > /dev/null 2>&1" >> $CROND
else
    sed -i '/.*history\.sh.*/d' $CROND
    echo "30 10 * * 6 /bin/bash $file_path/history.sh > /dev/null 2>&1" >> $CROND
fi
case $SysVer in
6)
    service crond restart >/dev/null 2>&1
;;
7)
    systemctl restart crond >/dev/null 2>&1
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac
source /etc/profile
if [ $? -eq 0 ]
then
    echo "###########################################"
    echo -e "\033[46;31;5m 配置完成 命令审计文件位于：/var/log/Command/Command.log \033[0m"
else
    echo -e "\033[41;33;5m ERROR,Please To Check  \033[0m"
    exit 110
fi
}

yumrepo(){
if [ ! -d $YUM/oldbackup ]
then
    mkdir -p $YUM/oldbackup
    mv -bf $YUM/*.repo $YUM/oldbackup
else
    mv -bf $YUM/*.repo $YUM/oldbackup
fi
/bin/ping -c 3 -i 0.1 -w 1 114.114.114.114 >/dev/null 2>&1
PanDuan
echo " "
echo -e "\033[46;31;5m 网络正常 \033[0m"
case $SysVer in
6)
    echo "正在执行中ing...请确保网络连接正常..."
    wget -P $YUM http://mirrors.aliyun.com/repo/Centos-6.repo >/dev/null 2>&1
    if [ ! $? -eq 0 ]
    then
        echo "wget 命令执行失败 正在尝试使用curl命令..."
        curl -Os http://mirrors.aliyun.com/repo/Centos-6.repo
        PanDuan
        mv Centos-6.repo $YUM
        PanDuan
    fi
    rpm -e $(rpm -qa | grep epel-release) >/dev/null 2>&1
    rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-6.noarch.rpm >/dev/null 2>&1
    PanDuan
    echo "重新构建YUM仓库中稍候...如果网络不佳会造成失败"
    yum clean all
    PanDuan
    yum makecache
    PanDuan
;;
7)
    echo "正在执行中ing...请确保网络连接正常..."
    wget -P $YUM http://mirrors.aliyun.com/repo/Centos-7.repo >/dev/null 2>&1
    if [ ! $? -eq 0 ]
    then
        echo "wget 命令执行失败 正在尝试使用curl命令..."
        curl -Os http://mirrors.aliyun.com/repo/Centos-7.repo
        PanDuan
        mv Centos-7.repo $YUM
        PanDuan
    fi
    PanDuan
    rpm -e $(rpm -qa | grep epel-release) >/dev/null 2>&1
    rpm -ivh http://mirrors.aliyun.com/epel/epel-release-latest-7.noarch.rpm >/dev/null 2>&1
    PanDuan
    echo "重新构建YUM仓库中稍候...如果网络不佳会造成失败"
    yum clean all
    PanDuan
    yum makecache
    PanDuan
;;
*)
    echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
    exit 110
;;
esac
}

mysqlInstall(){
echo "https://www.cnblogs.com/LuckWJL/p/9683683.html"
echo -e "\033[46;31;5m 请先前往博客参照进行安装 该脚本功能正在测试当中 请关注该脚本后续发布 \033[0m"
}

NOPENVPN(){
read -p "PLEASE INPUT NEW USER: " USERS
PATH1="/etc/openvpn/easy-rsa/3.0.3"
PATH2="/etc/openvpn/client/easy-rsa/3.0.3"
PATH3="/etc/openvpn/client/$USERS"
if [ -d $PATH3 ]
then
    echo -e "\033[41;33;5m $USERS already exist... \033[0m"
    exit 110
fi

cd $PATH2
/usr/bin/expect <<-EOF
spawn ./easyrsa gen-req $USERS nopass
expect {
        "Common Name"
        {
        send "\n"
        }
        "overwrite"
        {
        send "yes\n"
        expect "Common Name" {send "\n"}
        }
}

expect eof
EOF
PanDuan

cd $PATH1
./easyrsa import-req $PATH2/pki/reqs/$USERS.req $USERS

/usr/bin/expect <<-EOF
spawn ./easyrsa sign client $USERS

expect "Confirm" {send "yes\n"}

expect "phrase" {send "Elements\n"}

expect eof
EOF
PanDuan

mkdir $PATH3
cp $PATH1/pki/ca.crt $PATH3
cp $PATH1/pki/issued/$USERS.crt $PATH3
cp $PATH2/pki/private/$USERS.key $PATH3
NUMB=`ls -l $PATH3 | wc -l`
if [ $NUMB -ne 4 ]
then
    echo -e "\033[41;33;5m FILE ERROR \033[0m"
    exit 110
fi
}

DOPENVPN(){
read -p "DELET USER NAME: " USERS
cd /etc/openvpn/easy-rsa/3.0.3
/usr/bin/expect <<-EOF
spawn ./easyrsa revoke $USERS
expect "revocation" {send "yes\n"}
expect "Enter" {send "Elements\n"}
expect eof
EOF
rm -rf /etc/openvpn/client/$USERS
mv -bf /etc/openvpn/client/easy-rsa/3.0.3/pki/reqs/$USERS.req /tmp
mv -bf /etc/openvpn/client/easy-rsa/3.0.3/pki/private/$USERS.key /tmp
mv -bf /etc/openvpn/easy-rsa/3.0.3/pki/issued/$USERS.crt /tmp
mv -bf /etc/openvpn/easy-rsa/3.0.3/pki/reqs/$USERS.req /tmp
}

case $Nmb in
1)
    rm -rf /etc/udev/rules.d/70-persistent-net.rules >/dev/null 2>&1
    echo "###########################################"
    read -p "Please Input IPAddress :" Ipa
    read -p "Please Input Netmask :" Ntm
    read -p "Please Input Gateway :" Gtw
    echo -e "\033[46;34;5m[ 配置中请稍候... 完成后请使用新地址 $Ipa 进行SSH登陆 ]\033[0m"
    echo "###########################################"
    case $SysVer in
    6)
        C6NetWork
    ;;
    7)
        C7NetWork
    ;;
    *)
        echo -e "\033[41;33;5m System Version Error,Scripts only apply to Centos 6 and 7 versions \033[0m"
        exit 110
    ;;
    esac
;;
2)
    echo -e "\033[46;31;5m以下配置均可在进度条处 有10秒时间 按Ctrl+C结束 请按需优化\033[0m"
    OptSSH
    PanDuan
    OffIPv6
    PanDuan
    OffSE
    OFFfirewalld
    PanDuan
    TimeLock
    PanDuan
    LimitsFile
    PanDuan
    RootEmail
    PanDuan
    KernelFile
    PanDuan
    echo " #####################################"
    echo " #####################################"
    echo " 优化已完成 本次优化内容有："
    echo " 1、优化SSH服务"
    echo " 2、关闭IPv6服务"
    echo " 3、关闭Selinux 机制"
    echo " 4、关闭iptables/firewalld"
    echo " 5、设置时间同步"
    echo " 6、优化内核参数"
    echo " 7、关闭邮件提示"
;;
3)
    echo -e "\033[46;31;5m 此审计会记录30天内所有终端执行过的所有命令 \033[0m"
    Jdt
    HisTory
;;
4)
    echo -e "\033[46;31;5m 正在配置阿里云YUM源 在保障网络正常连接同时 请耐心等待 \033[0m"
    yumrepo
;;
5)
    mysqlInstall
;;
6)
    NOPENVPN
;;
7)
    DOPENVPN
;;
*)
    echo -e "\033[41;33;5m Error, please check the first line variable \033[0m"
    exit 110
;;
esac

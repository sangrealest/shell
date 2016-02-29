#!/bin/bash
#author shanker
#this script is only for CentOS 6 x32
#check up the OS
os=$(uname -i)
    if [ $os != "i386" ]
    then
         echo "this script is only for i386 system"
              exit 1
              fi
              echo "the os is i386"
              version=$(lsb_release -r|cut -f2|cut -c1)
    if [ $version != 6 ]
    then
         echo "this script is only for CentOS 6"
              exit 1
              fi
              cat << EOF
              +---------------------------------------+
              |   your system is CentOS 6 x86_64      |
              |        start optimizing.......        |
              +---------------------------------------
              EOF
#set up the 163.com as the default yum repo
              mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
              wget http://mirrors.163.com/.help/CentOS6-Base-163.repo -O /etc/yum.repos.d/CentOS-Base.repo
              yum clean all
              yum makecache
              rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY* 
              yum  upgrade -y

#update the system and set up the ntp


              yum -y install ntp
              echo "* 4 * * * sbin/ntpdate 210.72.145.44 > /dev/null 2>&1" >> /var/spool/cron/root
              echo '* 5 * * * /ntpdate time.nist.gov >/dev/null 2>&1'>>/var/spool/cron/root
              service crond restart
#set the control-alt-delete disable
              sed -i 's/^\(exec\)./#\1/g' /etc/init/control-alt-delete.conf
#disable selinux and iptables
              sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
              iptables -F


#set sudo

              useradd leo
              echo 'hacker'|passwd --stdin leo && history -c
              sed  -i '82a leo    ALL=(ALL)   ALL' /etc/sudoers

#set ssh no root login and no empty passwd

              sed -i 's/^GSSAPIAuthentication yes$/GSSAPIAuthentication no/' /etc/ssh/sshd_config
              sed -i 's/#UseDNS yes/UseDNS no/' /etc/ssh/sshd_config
              sed -i 's/#PermitRootLogin no/PermitRootLogin no/' /etc/ssh/sshd_config
              sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config
              service sshd restart

              chkconfig bluetooth off
              chkconfig cups off
              chkconfig ip6tables off

#disable the ipv6
              cat > /etc/modprobe.d/ipv6.conf << EOFI
              alias net-pf-10 off
              options ipv6 disable=1
              EOFI
              echo "NETWORKING_IPV6=off" >> /etc/sysconfig/network

#Lock system key files
              chattr +i /etc/passwd
              chattr +i /etc/inittab
              chattr +i /etc/group
              chattr +i /etc/shadow
              chattr +i /etc/gshadow
              mv /usr/bin/chattr /usr/bin/new name not related to chattr, but need remember.


#set vim
              cat >>/root/.vimrc << EOF
              set number
              set ruler
              set laststatus=2
              set showcmd
              set magic
              set history=100
              set showmatch
              set ignorecase
              set cursorline
              let loaded_matchparen=1
              set lazyredraw
              set tabstop=4
              set softtabstop=4
              set cindent shiftwidth=4
              set autoindent shiftwidth=4
              set smartindent shiftwidth=4
              set expandtab
              set hlsearch
              set incsearch
              EOF
#grep and vim

#mkcd
              cat>>/root/.bashrc<<EOF

              alias grep='grep --color=auto'
              alias vi='vim'
              alias ..='cd ..'
              alias ll='ls -altr'
              export PATH=$PATH:/sbin:.
              export TMOUT=1000000

              function mkcd(){
                  mkdir -p $1
                      cd $1
              }
#service $1 restart
function rs(){
    service $1 restart
}
#rm -rf
function fuck(){
    rm -rf $1
}
#chkconfig
function chon(){
    chkconfig $1 on
}
EOF


source /root/.bashrc

#set ulimit
cat >>/etc/rc.local<<EOF
#open files
ulimit -HSn 65535
#stack size
ulimit -s 65535
EOF
+-------------------------------------------------+
|               optimizer is done                               |
|   it's recommond to restart this server !             |
+-------------------------------------------------+
EOF

#!/bin/bash
# 反正也没人用，测试那么多平台干嘛，写错了就写错了，不支持就不支持。

echo '    1) Arch Linux'
echo '    2) Debian'
echo '    3) Ubuntu'
echo '    4) Fedora'
echo '    5) RHEL or CentOS'
echo '    6) Other Linux'
echo '    7) OS X'
read -p 'Select your distribution: ' dist

# Install shadowsocks-libev
ss_debian() {
  debver=`cat /etc/debian_version | cut -d '.' -f 1`
  case $debver in
    '8')
      sh -c 'printf "deb http://deb.debian.org/debian jessie-backports main\n" > /etc/apt/sources.list.d/jessie-backports.list'
      sh -c 'printf "deb http://deb.debian.org/debian jessie-backports-sloppy main" >> /etc/apt/sources.list.d/jessie-backports.list'
      apt update
      apt -t jessie-backports-sloppy install shadowsocks-libev
      ;;
    '9')
      sh -c 'printf "deb http://deb.debian.org/debian stretch-backports main" > /etc/apt/sources.list.d/stretch-backports.list'
      apt update
      apt -t stretch-backports install shadowsocks-libev
      ;;
    *)
      echo 'Unsupported debian version!'
      ;;
  esac
}

ss_ubuntu() {
  apt-get install software-properties-common -y
  add-apt-repository ppa:max-c-lv/shadowsocks-libev -y
  apt-get update
  apt install shadowsocks-libev
}

ss_fedora() {
  hash dnf > /dev/null 2>&1
  if [ $? == 0 ]; then
    dnf copr enable librehat/shadowsocks
    dnf update
    dnf install shadowsocks-libev
  else
    # FIXME: Add the judgement of the distro version
    if [ $dist == '4' ]; then
      # Fedora
      wget 'https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/fedora-27/librehat-shadowsocks-fedora-27.repo'
      mv librehat-shadowsocks-fedora-27.repo /etc/yum.repos.d/
    else
      # CentOS or RHEL
      wget 'https://copr.fedorainfracloud.org/coprs/librehat/shadowsocks/repo/epel-7/librehat-shadowsocks-epel-7.repo'
      mv librehat-shadowsocks-epel-7.repo /etc/yum.repos.d/
    fi
    yum update
    yum install shadowsocks-libev
  fi
}

case $dist in
  '1')
    pacman -S shadowsocks-libev
    ;;
  '2')
    # Other distros are untested
    apt-get install curl
    ss_debian
    ;;
  '3')
    ss_ubuntu
    ;;
  '4')
    ss_fedora
    ;;
  '5')
    ss_fedora
    ;;
  '6')
    echo 'Upcoming!'
    exit 1
    ;;
  '7')
    brew install shadowsocks-libev
    ;;
  *)
    echo 'Not a correct distnumber!'
    exit 1
    ;;
esac

# Install kcptun
ikrnl=`uname -s`
iarch=`uname -m`
case $ikrnl in
    'Linux')
        krnl='linux'
        ;;
    'FreeBSD' | 'GNU/kFreeBSD')
        krnl='freebsd'
        ;;
    'Darwin')
        krnl='darwin'
        ;;
    *)
        echo 'Unsupported platform!'
        exit 1
        ;;
esac
case $iarch in
    'i386' | 'i686')
        arch='386'
        ;;
    'amd64' | 'x86_64')
        arch='amd64'
        ;;
    'armv6l' | 'armv7l')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='arm'
        ;;
    'mips')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='mips'
        ;;
    'mipsel')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='mipsle'
        ;;
    *)
        echo 'Unsupported platform!'
        exit 1
        ;;
esac

url=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/xtaci/kcptun/releases/latest | sed 's/tag/download/g'`
kcptun_ver=`echo ${url} | cut -d '/' -f 8 | cut -d 'v' -f 2`
file=kcptun-${krnl}-${arch}-${kcptun_ver}.tar.gz
wget ${url}/${file}

mkdir kcptun
tar zxf $file -C kcptun
mv kcptun/server_${krnl}_${arch} /usr/bin/kcptun_server
rm -r kcptun $file
cp kcptun.service /lib/systemd/system

# Install udp2raw
case $iarch in
    'i386' | 'i686')
        arch='x86'
        ;;
    'amd64' | 'x86_64')
        arch='amd64'
        ;;
    'armv6l' | 'armv7l')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='arm'
        ;;
    'mips')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='mips24kc_be'
        ;;
    'mipsel')
        if [ '$krnl' != 'linux' ]; then
            echo 'Unsupported platform!'
            exit 1
        fi
        arch='mips24kc_le'
        ;;
    *)
        echo 'Unsupported platform!'
        exit 1
        ;;
esac

url=`curl -Ls -o /dev/null -w %{url_effective} https://github.com/wangyu-/udp2raw-tunnel/releases/latest | sed 's/tag/download/g'`
file='udp2raw_binaries.tar.gz'
wget ${url}/${file}

mkdir udp2raw
tar zxf $file -C udp2raw
mv udp2raw/udp2raw_${arch} /usr/bin/udp2raw
rm -r udp2raw $file
cp udp2raw.service /lib/systemd/system


# Configurations
ciphers[0]=''
ciphers[1]='aes-256-gcm'
ciphers[2]='aes-256-cfb'
ciphers[3]='chacha20-ietf-poly-1305'
ciphers[4]='xchacha20-ietf-poly-1305'

echo '    1) aes-256-gcm'
echo '    2) aes-256-cfb'
echo '    3) chacha20-ietf-poly-1305'
echo '    4) xchacha20-ietf-poly-1305'
read -p 'Select your shadowsocks ciphers: ' cipher
read -p 'Enter your password: ' pwd

sed -i "s/-k \"\"/-k \"${pwd}\"/g" server.conf
sed -i "s/\"password\": \"\"/\"password\": \"${pwd}\"/g" config.json
sed -i "s/\"method\": \"\"/\"method\": \"${ciphers[$(($cipher))]}\"/g" config.json

mkdir -p /etc/kcptun
mkdir -p /etc/udp2raw
cp config.json /etc/shadowsocks-libev
cp server-config.json /etc/kcptun
cp server.conf /etc/udp2raw

#!/bin/bash

GOOGLE_DNS_SERVER="8.8.8.8" 
SLEEP_TIME=5

if [ $# -lt 1 ]; then
    echo "[-] $0 [dns-server]"
    echo ""
    echo "dns-server=DNS server to use. Default: no DNS server."
    read
fi

dns_server="$1"

current_user=`id -u`
if [ ! $current_user == 0 ]; then
    echo "[-] Current user: `id -F`. It is recommended to run script as System Administrator/root."
    exit    
fi

echo "[*] Determing the OS type - Linux (Linux) or Mac (Darwin)"
os=`uname`
echo "[+] OS = $os"

if [ ! "$os" == "Linux" ] && [ ! "$os" == "Darwin" ]; then
    echo "[-] Only Linux/Darwin are currently supported."
    exit
fi

echo "[*] Terminating any openvpn connections first forcefully"
killall -9 openvpn  2>/dev/null

if [ "$os" == "Linux" ]; then
    echo "[*] Restarting networking service"
    service networking restart
fi

echo "[*] Getting list of all interfaces from ifconfig command"
interfaces=`ifconfig | egrep -io "^[a-zA-Z0-9]*" | egrep -v "^lo"`

echo "[*] Bring all the interfaces down"
echo "$interfaces" | xargs -I{} ifconfig {} down

echo "[*] Sleep $SLEEP_TIME secs"
sleep $SLEEP_TIME

echo "[*] Bring all the interfaces up"
echo "$interfaces" | xargs -I{} ifconfig {} up

echo "[*] Sleep $SLEEP_TIME secs"
sleep $SLEEP_TIME

if [ "$os" == "Linux" ]; then
    if [ ! -z "$dns_server" ]; then
        echo "[*] Backing up resolv.conf and setting nameserver in resolv.conf to Google - $dns_server for Linux"
        cp /etc/resolv.conf /etc/resolv.conf.old
        echo 'domain Home' > /etc/resolv.conf
        echo 'search Home' >> /etc/resolv.conf
        echo "nameserver $dns_server" >> /etc/resolv.conf
    fi

    echo "[*] Removing IPs via dhclient command for Linux"
    echo "$interfaces" | xargs -I{} sh -c "echo [*] Interface: {}; dhclient -r {}"

    echo "[*] Reassigning IPs via dhclient command for Linux"
    echo "$interfaces" | xargs -I{} sh -c "echo [*] Interface: {}; dhclient {}"

    sleep $SLEEP_TIME
else
    if [ ! -z "$dns_server" ]; then
        echo "[*] Setting Google as the DNS server - $dns_server - for Mac"
        networksetup -setdnsservers Wi-Fi $dns_server
    fi
    
    echo "[*] Sleep $SLEEP_TIME secs"
    sleep $SLEEP_TIME
fi

echo "[*] Checking internet connectivity by printing IP via ipinfo.io"
curl ipinfo.io

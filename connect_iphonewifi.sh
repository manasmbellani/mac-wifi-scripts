#!/bin/bash

./connect_wifi.sh

read -s -p "'Manas's iPhone' password: " password
echo

set -x
networksetup -setairportnetwork en0 "Manas's iPhone" $password &
set +x

echo "[+] Now wait for iPhone wifi to connect"

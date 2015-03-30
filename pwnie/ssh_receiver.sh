#!/bin/bash
# Script to perform Pwnie Express setup steps on Kali Linux
# Modified version by Pwnie Express: January-2014
# --------------------------------------------------------------------------
# Copyright (c) 2011 Security Generation <http://www.securitygeneration.com>
# This script is licensed under GNU GPL version 2.0
# --------------------------------------------------------------------------
# This script is part of PwnieScripts shell script collection
# Visit http://www.securitygeneration.com/security/pwniescripts-for-pwnie-express/
# for more information.
# --------------------------------------------------------------------------


user_ssh_key="<INSERT PUBLIC KEY HERE>"

#!/bin/bash
#     ____                 _      ______
#    / __ \_      ______  (_)__  / ____/  ______  ________  __________
#   / /_/ / | /| / / __ \/ / _ \/ __/ | |/_/ __ \/ ___/ _ \/ ___/ ___/
#  / ____/| |/ |/ / / / / /  __/ /____>  </ /_/ / /  /  __(__  |__  )
# /_/     |__/|__/_/ /_/_/\___/_____/_/|_/ .___/_/   \___/____/____/
#                                       /_/
#
# Copyright (c) 2010-2015, Pwnie Express (https://www.pwnieexpress.com/) All
# rights reserved.
#
# Use of this software signifies your agreement to the Pwnie Express / Rapid
# Focus Security, Inc. End User License Agreement (EULA). You may find a copy
# of the EULA at the following address: https://www.pwnieexpress.com/pdfs/RFSEULA.pdf
#
# As with any software application, any downloads/transfers of this software
# are subject to export controls under the U.S. Commerce Department's Export
# Administration Regulations (EAR). By using this software you certify your
# complete understanding of and compliance with these regulations.
#
# Not withstanding the above, redistribution and use in source and binary
# forms, with or without modification, are permitted provided that the
# following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of Pwnie Express nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Last Revision: 2014.01.13

if [ "$1" == "-h" ]; then
  echo "Configures and starts all Pwnix SSH Receiver tunnel listeners."
  exit 0
fi

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Generate Kali SSH server keypair if needed
files=$(ls /etc/ssh/ssh_host_* 2> /dev/null | wc -l)
if [ "$files" != "0" ]; then
  echo "[-] SSHd server keys already exist. Skipping generation..."
else
  echo "[+] Generating SSHd server keys..."
  sshd-generate
fi

# Ensure dependencies are installed...
apt-get install make openssl ptunnel openssl stunnel4 psmisc gcc -y

# Kill any active tunnel connections & listeners
for i in `netstat -lntup |grep pwnie |awk '{print$7}' |awk -F"/" '{print$1}'`; do kill $i ; done
killall ptunnel
killall stunnel4
killall dns2tcpd
killall hts

# Start Kali SSH server
echo "[+] Starting SSHD..."
service ssh start

# Create pwnie user account if needed
cut -d: -f1 /etc/passwd | grep "pwnie" > /dev/null
OUT=$?
if [ $OUT -eq 0 ];then
  echo "[-] User 'pwnie' already exists. Skipping."
else
  echo "[+] Adding 'pwnie' user account..."
  useradd -m pwnie
fi

# Make pwnie user .ssh directory if needed
if [ ! -d "/home/pwnie/.ssh" ]; then
  mkdir /home/pwnie/.ssh
fi

# Copy pwnie user SSH public key to authorized_keys
echo "$user_ssh_key" > /home/pwnie/.ssh/authorized_keys

# Configure & start Reverse-SSH-over-HTTP listener
if [ -e "/usr/bin/hts" ]; then
  echo "[-] HTTPTunnel is already installed."
  echo "[+] Starting Reverse-SSH-over-HTTP (HTTPtunnel) listener..."
  hts -F localhost:22 80
else
  echo "[+] Installing HTTPtunnel via apt..."
  apt-get --force-yes --yes -qq install httptunnel
  echo "[+] Starting Reverse-SSH-over-HTTP (HTTPtunnel) listener..."
  hts -F localhost:22 80
fi

# Configure & start Reverse-SSH-over-SSL listener
if [ -d "/root/stunnel/" ]; then
  echo "[-] stunnel is already configured. Remove directory /root/stunnel/ and re-run this script if you want to reconfigure."
  echo "[+] Starting Reverse-SSH-over-SSL (stunnel) listener..."
  stunnel4 /root/stunnel/stunnel.conf &
else
  echo "[+] Configuring stunnel..."
  echo "[+] Generating SSL certificate (press enter for all prompts)..."
  mkdir /root/stunnel/ && cd /root/stunnel/
  openssl genrsa -out pwn_key.pem 2048
  openssl req -new -key pwn_key.pem -out pwn.csr
  openssl x509 -req -in pwn.csr -out pwn_cert.pem -signkey pwn_key.pem -days 1825
  cat pwn_cert.pem >> pwn_key.pem
  echo "[+] SSL certificate created. Configuring stunnel.conf..."
  echo -e "cert = /root/stunnel/pwn_key.pem\nchroot = /var/tmp/stunnel\npid = /stunnel.pid\nsetuid = root\nsetgid = root\nclient = no\n[22]\naccept = 443\nconnect = 22" >> /root/stunnel/stunnel.conf
  mkdir /var/tmp/stunnel
  echo "[+] Starting Reverse-SSH-over-SSL (stunnel) listener..."
  stunnel4 /root/stunnel/stunnel.conf &
fi

if type "dns2tcpd" > /dev/null 2>&1; then
  echo "[+] DNS2TCP is already installed."
else
  # Download & install dns2tcp
  echo "[+] Downloading & Installing DNS2TCP..."
  cd /usr/local/src/
  wget http://hsc.fr/ressources/outils/dns2tcp/download/dns2tcp-0.5.2.tar.gz
  tar xzvf dns2tcp-0.5.2.tar.gz
  cd dns2tcp-0.5.2/
  ./configure
  make
  sudo make install
fi

# Configure & start Reverse-SSH-over-DNS listener
if [ -e /root/dns2tcpdrc ]; then
  echo "[-] DNS2TCP is already configured. Remove /root/dns2tcpdrc and re-run this script if you want to reconfigure."
  echo "[+] Starting Reverse-SSH-over-DNS (dns2tcp) listener..."
  dns2tcpd -d 0 -f /root/dns2tcpdrc &
else
  echo "[+] Configuring DNS2TCP..."
  echo -e "listen = 0.0.0.0\nport = 53\nuser = nobody\nchroot = /var/empty/dns2tcp/\ndomain = rssfeeds.com\nresources = ssh:127.0.0.1:22" >> /root/dns2tcpdrc
  mkdir -p /var/empty/dns2tcp/

  echo "[+] Starting Reverse-SSH-over-DNS (dns2tcp) listener..."
  dns2tcpd -d 0 -f /root/dns2tcpdrc &
fi

# Start Reverse-SSH-over-ICMP listener
echo "[+] Starting Reverse-SSH-over-ICMP (ptunnel) listener (Logging to /tmp/ptunnel.log)..."
ptunnel -daemon /tmp/ptunnel -f /tmp/ptunnel.log &

echo ""
echo "[+] Setup Complete."
echo "[+] Press ENTER to listen for incoming connections..."
read INPUT
watch -d "netstat -lntup4 | grep 'pwn' | grep 333"


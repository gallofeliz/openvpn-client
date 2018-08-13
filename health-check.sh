. /tmp/vpn_env

echo "IP_BEFORE_VPN=$IP_BEFORE_VPN"
echo "VPN_IP=$VPN_IP"
echo "IP_GETTER=$IP_GETTER"

IP=$(wget -qO - $IP_GETTER)

if [[ "$IP" == "$IP_BEFORE_VPN" ]]
then
   echo "WHAT THE FUCK"
   kill -SIGQUIT $(cat /var/run/openvpn.pid)
   exit 1
fi


#!/usr/bin/env sh

echo "Resolving config ..."

OVPN_PATH=/usr/local/etc/.ovpn
OVPN_PASS_PATH=/usr/local/etc/.ovpn-pass

test -f $OVPN_PATH || { echo "Expected $OVPN_PATH" ; exit 1; }
test -f $OVPN_PASS_PATH || { echo "Expected $OVPN_PASS_PATH" ; exit 1; }

test -z "$(grep 'up ' $OVPN_PATH)" || { echo "up script in ovpn file not permitted" ; exit 6; }
test -z "$(grep 'down ' $OVPN_PATH)" || { echo "down script in ovpn file not permitted" ; exit 6; }

VPN_HOST=`grep 'remote ' $OVPN_PATH | awk '{print $2}'`

if expr "$VPN_HOST" : '[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*\.[0-9][0-9]*$' >/dev/null
then
    VPN_IP="$VPN_HOST"
else
    VPN_IP=`dig +short $VPN_HOST | shuf | head -n 1`
fi

echo "$VPN_IP $VPN_HOST" >> /etc/hosts

test -n $VPN_IP || { echo "Unable to resolve VPN ip from extracted host \"$VPN_HOST\"" ; exit 2; }

TESTABLE_HTTP_IP=`dig +short ipecho.net`
test -n $TESTABLE_HTTP_IP || { echo "Unable to resolve testable http ip"; exit 3; }

IP_GETTER='http://ipecho.net/plain'
IP_BEFORE_VPN=$(wget -qO - $IP_GETTER)

test -n $IP_BEFORE_VPN || { echo "Unable to get current IP"; exit 4; }

rm -f /tmp/vpn_env
echo "IP_BEFORE_VPN=$IP_BEFORE_VPN" >> /tmp/vpn_env
echo "VPN_IP=$VPN_IP" >> /tmp/vpn_env
echo "IP_GETTER=$IP_GETTER" >> /tmp/vpn_env

CONTAINER_IP=$(hostname -i)

echo "Configuring iptables ..."

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP

iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

iptables -A OUTPUT -o tun0 -j ACCEPT
iptables -A INPUT  -i tun0 -j ACCEPT

iptables -A OUTPUT -p TCP -o eth0 --dport 443 -d $VPN_IP -j ACCEPT
iptables -A INPUT  -p TCP -i eth0 -s $VPN_IP -j ACCEPT

iptables -A INPUT -i eth0 -p tcp -s $CONTAINER_IP/16 -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp -d $CONTAINER_IP/16 -m state --state ESTABLISHED,RELATED -j ACCEPT

echo "Verifying internet KO ..."

timeout -t 3 wget -q $TESTABLE_HTTP_IP 1>/dev/null 2>&1 && { echo "Unexpected success for HTTP test after iptables"; exit 5; }
DNS_TEST=$(timeout -t 3 dig +short google.fr 2>/dev/null)
test -z $DNS_TEST || { echo "Unexpected success for DNS resolution after iptables"; exit 5; }

echo "Running VPN $VPN_HOST ..."

exec openvpn --config $OVPN_PATH --auth-user-pass $OVPN_PASS_PATH --up /etc/openvpn/up.sh --down /etc/openvpn/down.sh --writepid /var/run/openvpn.pid

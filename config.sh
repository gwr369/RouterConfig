#!/bin/bash

wanInterface="wlx002df45b09dc"
lanInterface="eno1"

# Flushing all rules
iptables -F
iptables -X

# Setting default filter policy
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

# Allow unlimited traffic on loopback
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Allow incoming ssh
iptables -A INPUT -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# allow incoming dns ( local )
iptables -A INPUT -p udp --dport 53 -j  ACCEPT
iptables -A OUTPUT -p udp --sport 53 -j ACCEPT

# allow out / in dns resolver request
# tester kali linux OK
iptables -A OUTPUT -p udp --dport 53 -d 8.8.8.8 -m conntrack -j ACCEPT
iptables -A INPUT -p udp --sport 53 -s 8.8.8.8 -m conntrack -j ACCEPT

# allow DHCP
iptables -A OUTPUT -p udp --dport 67 -j ACCEPT
iptables -A INTPUT -i eno1 -p udp --dport 68 --sport 67 -j ACCEPT

# web
iptables -A INPUT -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# DNAT web server 443
iptables -t nat -A PREROUTING -i $wanInterface -p tcp --dport 443 -j DNAT --to-destination 192.168.1.2:443
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -p tcp -d 192.168.1.2 --dport 443 -m conntrack --ctstate NEW -j ACCEPT

# NAT
iptables -t nat -A POSTROUTING -i $lanInterface -o $wanInterface -j MASQUERADE
iptables -A FORWARD -i $lanInterface -o $wanInterface -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $wanInterface -o $lanInterface -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT


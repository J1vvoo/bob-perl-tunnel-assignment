#!/bin/sh

# iptables: 기본 정책을 모두 DROP으로 설정
iptables -P INPUT   DROP
iptables -P FORWARD DROP
iptables -P OUTPUT  DROP

# iptables: 자기 자신과의 통신(loopback)은 허용
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# iptables: 외부에서 8080 포트로 들어오는 새로운 연결 허용
iptables -A INPUT  -p tcp --dport 8080 -m state --state NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --sport 8080 -m state --state ESTABLISHED     -j ACCEPT

# iptables: 내부 challenge-net 네트워크로의 통신 허용
# Docker가 생성하는 사설 네트워크 대역으로의 исходящий/входящий 트래픽을 허용합니다.
iptables -A OUTPUT -d 172.16.0.0/12 -j ACCEPT
iptables -A INPUT -s 172.16.0.0/12 -j ACCEPT

# 스크립트의 나머지 인자들을 tomcat_user 권한으로 실행
exec su-exec tomcat_user "$@"

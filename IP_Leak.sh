#!/bin/bash

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Улучшенная проверка интернет-соединения
check_internet() {
    local services=(
        "https://google.com"
        "https://cloudflare.com"
        "https://1.1.1.1"
    )
    local success=0
    
    for service in "${services[@]}"; do
        if curl -s --max-time 3 "$service" >/dev/null; then
            success=1
            break
        fi
    done
    
    if [ $success -eq 0 ]; then
        echo -e "${RED}Ошибка: Нет интернет-соединения!${NC}"
        exit 1
    fi
}

# Проверка IP (IPv4 + IPv6)
check_ip() {
    echo -e "\n${BLUE}= Текущий IP =${NC}"
    
    # IPv4 (5 сервисов)
    echo -n "IPv4: "
    ipv4_services=(
        "https://api.ipify.org?format=json"
        "https://ifconfig.co/json"
        "https://ipinfo.io/json"
        "https://ipapi.co/json"
        "https://icanhazip.com"
    )
    for service in "${ipv4_services[@]}"; do
        ipv4_data=$(curl -s --max-time 5 "$service" 2>/dev/null)
        if [ $? -eq 0 ]; then
            ip=$(echo "$ipv4_data" | jq -r '.ip // .ip_address // empty' 2>/dev/null || \
                 echo "$ipv4_data" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
            country=$(echo "$ipv4_data" | jq -r '.country // .country_name // "unknown"' 2>/dev/null)
            if [ -n "$ip" ]; then
                echo -e "${YELLOW}$ip${NC} ($country)" && break
            fi
        fi
    done || echo -e "${RED}Ошибка запроса${NC}"

    # IPv6
    echo -n "IPv6: "
    ipv6_services=(
        "https://ipv6.ipleak.net/json"
		"https://ipv6.icanhazip.com"
		"https://ipv6.seeip.org"
        "https://api64.ipify.org"
		"https://ipv6.jsonip.com"
    )
    for service in "${ipv6_services[@]}"; do
        ipv6_data=$(curl -s --max-time 5 "$service" 2>/dev/null)
        if [ $? -eq 0 ]; then
            ip=$(echo "$ipv6_data" | jq -r '.ip // empty' 2>/dev/null || \
                 echo "$ipv6_data" | grep -oE '([a-f0-9:]+:+)+[a-f0-9]+')
            if [ -n "$ip" ] && [[ "$ip" != *"d:f"* ]]; then  # Фильтрация артефактов
                echo -e "${YELLOW}$ip${NC}" && break
            fi
        fi
    done || echo -e "${YELLOW}Не обнаружен${NC}"
}

# Проверка системных DNS (разделение IPv4/IPv6)
check_system_dns() {
    echo -e "\n${BLUE}= Системные DNS-серверы =${NC}"
    
    if command -v resolvectl &>/dev/null; then
        # Основные DNS (IPv4)
        echo "Основные DNS (IPv4):"
        resolvectl status | awk -F': ' '/DNS Servers:/ {print $2}' | tr ' ' '\n' | \
            grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sed 's/#.*//' | sort -u | \
            while read ip; do [ -n "$ip" ] && echo -e " - ${YELLOW}$ip${NC}"; done

        # Основные DNS (IPv6)
        echo -e "\nОсновные DNS (IPv6):"
        resolvectl status | awk -F': ' '/DNS Servers:/ {print $2}' | tr ' ' '\n' | \
            grep -oE '([a-f0-9:]+:+)+[a-f0-9]+' | sed 's/#.*//' | sort -u | \
            while read ip; do [ -n "$ip" ] && echo -e " - ${YELLOW}$ip${NC}"; done

        # Fallback DNS (IPv4)
        echo -e "\nFallback DNS (IPv4):"
        resolvectl status | awk -F': ' '/Fallback DNS Servers:/ {print $2}' | tr ' ' '\n' | \
            grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | sed 's/#.*//' | sort -u | \
            while read ip; do [ -n "$ip" ] && echo -e " - ${YELLOW}$ip${NC}"; done

        # Fallback DNS (IPv6)
        echo -e "\nFallback DNS (IPv6):"
        resolvectl status | awk -F': ' '/Fallback DNS Servers:/ {print $2}' | tr ' ' '\n' | \
            grep -oE '([a-f0-9:]+:+)+[a-f0-9]+' | sed 's/#.*//' | sort -u | \
            while read ip; do [ -n "$ip" ] && echo -e " - ${YELLOW}$ip${NC}"; done
        
    elif [ -f /etc/resolv.conf ]; then
        echo "DNS из /etc/resolv.conf (IPv4):"
        grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}' | \
            grep -E '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u | \
            while read ip; do echo -e " - ${YELLOW}$ip${NC}"; done
        
        echo -e "\nDNS из /etc/resolv.conf (IPv6):"
        grep -E '^nameserver' /etc/resolv.conf | awk '{print $2}' | \
            grep -E '([a-f0-9:]+:+)+[a-f0-9]+' | sort -u | \
            while read ip; do echo -e " - ${YELLOW}$ip${NC}"; done
    else
        echo -e "${YELLOW}Не удалось определить DNS${NC}"
    fi
}

# Проверка DNS-утечек (с фильтрацией артефактов)
check_dns_leaks() {
    echo -e "\n${BLUE}= Проверка DNS-утечек =${NC}"
    
    services=(
        "https://www.dnsleaktest.com"
        "https://dnsleak.com"
        "https://bash.ws/dnsleak"
    )
    
    for service in "${services[@]}"; do
        echo -n "Проверка через ${service}... "
        ips=$(curl -s --max-time 10 "$service" | \
              grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}|([a-f0-9:]+:+)+[a-f0-9]+' | \
              grep -v "d:f" | sort -u)  # Фильтрация артефактов
        
        if [ -n "$ips" ]; then
            echo -e "Успешно!\n\nDNS-запросы идут через:"
            echo "$ips" | while read ip; do
                echo -e " - ${YELLOW}$ip${NC}"
            done
            return
        else
            echo -e "${YELLOW}Ошибка${NC}"
        fi
    done
    echo -e "${YELLOW}Не удалось проверить DNS через внешние сервисы${NC}"
}

# Напоминание о WebRTC
webrtc_reminder() {
    echo -e "\n${BLUE}= Важно! Утечки WebRTC возможно проверить только через браузер =${NC}"
    echo -e "- ${GREEN}https://browserleaks.com/webrtc${NC}"
    echo -e "- ${GREEN}https://ipleak.net/#webrtc${NC}"
    echo -e "- ${GREEN}https://whoer.net/ru${NC}"
}

# Основная программа
clear

check_internet
check_ip
check_system_dns
check_dns_leaks
webrtc_reminder
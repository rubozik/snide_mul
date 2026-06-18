#!/bin/bash

if [ "$EUID" -ne 0 ]; then
  echo "[!] Пожалуйста, запустите инсталлятор через sudo!"
  exit 1
fi

echo "[*] Начинаю установку SNIDE_MUL v2.5...

mkdir -p /usr/local/bin

cp snide_mul.sh /usr/local/bin/mul

chmod +x /usr/local/bin/mul

echo "[+] Установка успешно завершена!"
echo "[*] Теперь вы можете запустить комбайн из любой точки терминала командой: mul"

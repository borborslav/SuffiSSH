#!/bin/bash

SUFFIX1="borys"
SUFFIX2="foobar"
SUFFIX3="test"

# Обробник завершення процесу
cleanup() {
    echo "Завершуємо всі дочірні процеси..."
    pkill -P $$
    wait
    exit
}

trap cleanup SIGINT

# Видаляємо залишкові файли від попереднього запуску
for file in /dev/shm/temp_key_* /dev/shm/temp_key_*.pub; do
    [ -e "$file" ] && rm "$file"
done

cores=$(grep -c ^processor /proc/cpuinfo)
echo "Запускаємо $cores потоків"

search_key() {
    while true; do
        ssh-keygen -t ed25519 -f /dev/shm/temp_key_$1 -N "" -q
        PUBKEY_BASE64=$(cut -d' ' -f2 /dev/shm/temp_key_$1.pub | tr '[:upper:]' '[:lower:]')

        if [[ "$PUBKEY_BASE64" == *$SUFFIX1 ]] || [[ "$PUBKEY_BASE64" == *$SUFFIX2 ]] || [[ "$PUBKEY_BASE64" == *$SUFFIX3 ]]; then
            echo "Знайдено відповідний ключ в потоці $1, що закінчується на: ${PUBKEY_BASE64: -6}"
            mv /dev/shm/temp_key_$1 id_ed25519
            mv /dev/shm/temp_key_$1.pub id_ed25519.pub
            pkill -P $$
            break
        else
            rm /dev/shm/temp_key_$1 /dev/shm/temp_key_$1.pub
        fi
    done
}

for ((i=1; i<=cores; i++)); do
    search_key $i &
done

wait


#!/bin/bash

net_name=net
subnet=192.168.100.0/24

db_image=mongo:8.0.0-rc16
db_cont_name=db
db_ip=192.168.100.10
db_data=~/rocketchat_db/

app_image=rocket.chat:6.9.2
app_cont_name=rocketchat
app_ip=192.168.100.11
url=http://localhost/
port=80

# Создаём каталог для данных контейнера
mkdir $db_data

# Создаём сеть (используем драйвер по умолчанию - bridge)
docker network create --subnet $subnet $net_name

# Запускаем контейнер с mongodb, указываем параметры и пробрасываем каталог с данными
docker run \
    --name $db_cont_name \
    --hostname $db_cont_name \
    --network=$net_name \
    --ip $db_ip \
    -v $db_data:/data/db:rw \
    --restart unless-stopped \
    -d $db_image

# Запускаем контейнер rocketchat (порт по умолчанию 3000), ссылаемся на контейнер с mongodb
docker run \
    --name $app_cont_name \
    --hostname $app_cont_name \
    --network=$net_name \
    --ip $app_ip \
    -p $port:3000 \
    --env ROOT_URL=$url \
    --link $app_cont_name:$app_cont_name \
    --restart unless-stopped \
    -d $app_image

# Ждем запуск приложения
attempt_counter=0
max_attempts=60
echo -e "\nОжидаем запуск приложения"
until $(curl --output /dev/null --silent --head --fail $url); do
    if [ ${attempt_counter} -eq ${max_attempts} ];then
      echo -e "\nВремя ожидания истеко\n"
      exit 1
    fi
    printf '.'
    attempt_counter=$(($attempt_counter+1))
    sleep 2
done
echo -e '\nПриложение запущено, перейдите по адресу' $url '\n'

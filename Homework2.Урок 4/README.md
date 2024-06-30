# Otus-PG-DmitriyM
## 1.создать ВМ с Ubuntu 20.04/22.04 или развернуть докер любым удобным способом
Создана WSL2 ВМ на Ubuntu 22.04.4

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/0c0bcc10-00f3-4277-86fb-d21289f7485c)
## 2.поставить на нем Docker Engine
Docker был установлен через установку Docker Desktop и скачан образ PostgreSQL.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/2d49e1ae-8dac-4bbb-9e88-65cc9aa39c33)
Проверка что Docker установлен:
docker --version

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/48e1f242-9e07-4e90-976e-cc3a0ca3b7ec)

или так: sudo docker ps

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/76d925e0-2052-4732-9e83-b120df77eadd)
## 3.сделать каталог /var/lib/postgres
Был создан каталог /var/lib/postgres: sudo mkdir /var/lib/postgres
Проведена проверка не его существование: cd /var/lib/postgres

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/c7cc30ee-b820-49c4-ae5e-19c13c0947e2)
## 4.развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql
Создаем сеть, которую будем использовать между контейнерами для связи

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/0154ba85-2eda-42ad-926a-33e61f64b07f)

Был развернут контейнер с PostgreSQL 16 (был скачен новый image, т.к. в скаченном была версия PostgreSQL отличная от 16-го). Установлено с официального образа.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/1bc550ee-31c3-4f3d-94e0-b752d9214643)
Проверим подключение к PG в Docker

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/27c208f9-0f32-4435-9556-953489727297)

Т.к. контейнер был создан без связи с сетью, созданной выше, контейнер был удален через Docker Desktop и запущен заново через команду:

sudo docker run --name dockerPG16 --network netpg16 -e POSTGRES_PASSWORD=67890 -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:16

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/636a9d86-6174-41df-8c77-fd9de8889837)
## 5.развернуть контейнер с клиентом postgres
Запускаем контейнер с клиентом в созданной сети netpg16 и подключаемся к серверу PG в контейнере dockerPG16:

sudo docker run -it --rm --network netpg16 --name dockerPG16-cl postgres:16 psql -h dockerPG16 -U postgres

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/8d569b21-a43e-43dc-82bb-620dbbd5be71)

В docker desktop видно два контейнера:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/e27d49b1-e705-431f-975b-568859152dd0)
## 6.подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк
Создаем базу данных с одной таблицей и заполняем ее двумя записями:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/450839e0-6e1d-434c-92db-94735599304f)

При проверке было выяснено что таблица была создана в БД postgres, т.к. перед созданием БД не было переключен контекст на созданную БД. Была создана заново в нужно БД:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/bc79c351-2da0-410a-8ffa-82de29dced52)
## 7.подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера
Было выбрано подключение через DBeaver. Для этого необходимо было узнать ip контейнера dockerPG16:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/37f2a89f-856c-4ac3-9bac-5f02c9919dd9)

Выяснив IP, была произведена настройка подключения в DBeaver. Главное не забыть установить флаг "Показывать все базы данных", а иначе новую созданную базу не видно в обозревателе.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/9effe528-498f-46a6-b07e-495ba20b69ab)
## 8.удалить контейнер с сервером
Чтобы удалить контейнер необходимо его остановить, а уже потом удалять.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/c10606ca-be4a-4fbc-92d2-9b0b6db05ef4)

Также можно проверить что контейнер остановлен в Docker Desktop.

Затем удаляем контейнер: docker rm dockerPG16

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/39e6b2c3-3e44-4543-bca1-eff205d21d19)
Ни одного контейнера не осталось в Docker Desktop.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/2f65352f-33af-4747-b02b-d5d1bd3b30a2)
## 9.создать его заново
Создаем заново и запускаем контейнер:

sudo docker run --name dockerPG16 --network netpg16 -e POSTGRES_PASSWORD=67890 -d -p 5432:5432 -v /var/lib/postgres:/var/lib/postgresql/data postgres:16

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/124806cd-1af3-4dce-8984-07d89b42ae53)

Проверяем что он создался и запустился:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/96aedb03-76f4-472a-9d7c-5395c91faab6)

или командой sudo docker ps

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/51c1125f-a3bb-4fa6-936c-be832a45ab7e)
## 10.подключится снова из контейнера с клиентом к контейнеру с сервером
Запускаем контейнер с клиентом:

sudo docker run -it --rm --network netpg16 --name dockerPG16-cl postgres:16 psql -h dockerPG16 -U postgres

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/7c79dd98-26e3-410a-aaa0-15b00fca9c0b)
## 11.проверить, что данные остались на месте
Смотрим список БД: \l

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/ac9801e3-c382-4d80-87c1-140048539799)
Переключаемся в БД dbhw2: \c и смотрим список таблиц: \dt

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/cc2555e7-01de-49bb-b164-706d359721da)

Проверяем содержимое созданной ранее таблицы:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/28610a0c-f17c-442f-a063-a3daa2ab1702)

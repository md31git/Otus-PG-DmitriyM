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
Провереда проверка не его существование: cd /var/lib/postgres
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/c7cc30ee-b820-49c4-ae5e-19c13c0947e2)
## 4.развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql
Создаем сеть, которую будем использовать между контейнерами для связи
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/0154ba85-2eda-42ad-926a-33e61f64b07f)
Был развернут контейнер с PostgreSQL 16 (был скачен новый image, т.к. в скаченном была версия PostgreSQL отличная от 16-го). Установдено с официального образа.
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
Создаем базу данных с одной таблицей и заполяем ее двумя записями:
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/450839e0-6e1d-434c-92db-94735599304f)
## 7.подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера
удалить контейнер с сервером
создать его заново
подключится снова из контейнера с клиентом к контейнеру с сервером
проверить, что данные остались на месте
оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами

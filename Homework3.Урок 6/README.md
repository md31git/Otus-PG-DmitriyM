## 1.создайте виртуальную машину c Ubuntu 20.04/22.04 LTS в GCE/ЯО/Virtual Box/докере поставьте на нее PostgreSQL 15 через sudo apt
Уже был установен PG 14 на WSL на Ubuntu. Согласовано что на данной версии тоже будет работать все необходимые команды.

sudo apt install postgresql postgresql-contrib

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/06721ddb-91cc-4b23-80b0-da2473c4dc7e)
## 2.проверьте что кластер запущен через sudo -u postgres pg_lsclusters

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/b1b90cb7-fd92-4c72-b54e-93b0998413c8)
## 3.зайдите из под пользователя postgres в psql и сделайте произвольную таблицу с произвольным содержимым
Зашел в PG под postgres:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/311684a7-7d4d-4b0b-8506-77acdf1f4e93)

Создали и заполнили таблицу:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/7c2b212c-f604-4e7b-af92-e6883a37197d)

## 4.остановите postgres например через sudo -u postgres pg_ctlcluster 15 main stop
Остановили PG и проверили что он остановлен.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/17c31141-6f71-4a1f-b42a-a64840e1723d)

## 5.создайте новый диск к ВМ размером 10GB (отдельная директория)
Переключаемся на пользователя root чтобы были админские права:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/08ff7c6f-646a-4e78-9147-1f080c27613f)

Создаем каталог test в /var/lib/postgresql/

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/6e04bdd5-f9ae-4409-bde6-4c455fca5886)

## 6.сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
sudo chown postgres /var/lib/postgresql/test

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/7ed3e6ba-d143-4bf2-a122-c1535a2dfa60)

## 7.перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data
Перенес весь каталог /var/lib/postgresql/14 в /var/lib/postgresql/test

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/65f55a02-59d8-4b07-9d6b-e0b289a3d152)

## 8.попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
sudo -u postgres pg_ctlcluster 14 main start

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/76dc5337-aee5-4c3f-82ac-3b7f266addf1)

Вышла ошибка, т.к. PG првоерять все пути на доступность согласно файлам конфигурации. 

## 9.задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
Открыли файл /etc/postgresql/14/main/postgresql.conf (именно там указан каталог, где по умолчанию храняться данные БД) и поменяли в параметре data_directory новый путь на /var/lib/postgresql/test/14

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/a6698c10-0127-452f-821f-f610e025b863)

## 10.попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
sudo -u postgres pg_ctlcluster 14 main start

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/1b36b21b-f5c1-4abc-8826-d57a966108f2)

Запуск прошел успешно, т.к. теперь в файле конфигурации postgresql.conf указан верный путь к данным.

## 11.зайдите через через psql и проверьте содержимое ранее созданной таблицы
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/10728d59-0180-489b-b37a-f872a6a6c0d7)

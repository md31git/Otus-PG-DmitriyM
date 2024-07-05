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

сделайте пользователя postgres владельцем /mnt/data - chown -R postgres:postgres /mnt/data/
перенесите содержимое /var/lib/postgres/15 в /mnt/data - mv /var/lib/postgresql/15/mnt/data
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
напишите получилось или нет и почему
задание: найти конфигурационный параметр в файлах раположенных в /etc/postgresql/15/main который надо поменять и поменяйте его
напишите что и почему поменяли
попытайтесь запустить кластер - sudo -u postgres pg_ctlcluster 15 main start
напишите получилось или нет и почему
зайдите через через psql и проверьте содержимое ранее созданной таблицы
задание со звездочкой *: не удаляя существующий инстанс ВМ сделайте новый, поставьте на его PostgreSQL, удалите файлы с данными из /var/lib/postgres, перемонтируйте внешний диск который сделали ранее от первой виртуальной машины ко второй и запустите PostgreSQL на второй машине так чтобы он работал с данными на внешнем диске, расскажите как вы это сделали и что в итоге получилось.

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
## 3.сделать каталог /var/lib/postgres
Был создан каталог /var/lib/postgres: sudo mkdir /var/lib/postgres
Провереда проверка не его существование: cd /var/lib/postgres
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/c7cc30ee-b820-49c4-ae5e-19c13c0947e2)
## 4.развернуть контейнер с PostgreSQL 15 смонтировав в него /var/lib/postgresql

развернуть контейнер с клиентом postgres
подключится из контейнера с клиентом к контейнеру с сервером и сделать таблицу с парой строк
подключится к контейнеру с сервером с ноутбука/компьютера извне инстансов GCP/ЯО/места установки докера
удалить контейнер с сервером
создать его заново
подключится снова из контейнера с клиентом к контейнеру с сервером
проверить, что данные остались на месте
оставляйте в ЛК ДЗ комментарии что и как вы делали и как боролись с проблемами

## 1.Установка WSL
```bash
wsl --install --distribution Ubuntu
```
## 2. Обновление Ubuntu и установка PostgreSQL 14
```bash
sudo apt update && sudo apt upgrade
sudo apt install postgresql postgresql-contrib
sudo nano /etc/postgresql/14/main/postgresql.conf
sudo nano /etc/postgresql/14/main/pg_hba.conf
sudo -u postgres psql -d postgres -p 5432
ALTER USER postgres PASSWORD '12345';
sudo pg_ctlcluster 14 main restart  
```
![image](https://github.com/user-attachments/assets/e0b76f56-cc57-475a-9f73-b865dfb006d7)

## 3. Необходимо установить библиотеку FreeTDS. Для Ubuntu это пакеты freetds-dev и freetds-common
```bash
sudo apt-get install freetds-dev freetds-common
```
Возникал ошибка, что файл менеджера пакетов dpkg уже заблокирован — то есть, уже выполняется какой-то процесс, который его задействует.
![image](https://github.com/user-attachments/assets/b8a02be2-0245-410d-9c21-3fb197d8c299)
Посмотрим какие процессы запущены и завершим их, и попробуем снова установить FreeTDS
```bash
ps aux | grep -i apt
sudo kill -9 39110
sudo apt-get install freetds-dev freetds-common
```
![image](https://github.com/user-attachments/assets/3f7a0557-70c7-4cd1-84ff-1698df725674)
Теперь все выполнилось успешно.

## 4.Cкачиваем и собираем tds_fdw
Скачиваем tds_fdw с github, переходим в скаченную папку и ставим расширение tds_fdw
```bash
git clone https://github.com/tds-fdw/tds_fdw.git
cd tds_fdw
sudo make USE_PGXS=1 install
```
Но возникает ошибки при установке
![image](https://github.com/user-attachments/assets/6e0d87e0-d4ba-457c-a3e7-a9afed6744b5)
Решение найдено через установку postgresql-server-dev-all  - это инструмент для сборки расширений для нескольких версий PostgreSQL.
```bash
sudo apt-get install postgresql-server-dev-all
sudo make USE_PGXS=1 install
```
Теперь все выполнилось успешно.







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
Все получилось.





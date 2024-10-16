## 1.Установка WSL2 (Ununtu)
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

## 3. Установка библиотеки FreeTDS
Необходимо установить библиотеку FreeTDS. Для Ubuntu это пакеты freetds-dev и freetds-common.
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

## 4.Загрузка и сборка расширения tds_fdw
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

## 5.Настройка подключения в базе MS SQL 2019
Настраиваем подключение: настройка FreeTDS для подключения к MS SQL Server выполняется с помощью файла /etc/freetds/freetds.conf
```bash
sudo nano /etc/freetds/freetds.conf
```
Вместо шаблонной настройки создаем свою

![image](https://github.com/user-attachments/assets/92eaea7b-aa46-4c5f-895c-e31d8dbb2457)

Т.к. у меня на локальной машине только один экземпляр MS SQL SERVER то instance не указываем

![image](https://github.com/user-attachments/assets/0fc7631c-5915-4997-a36e-c1dd606a0234)

## 6.Создание БД приемника PostgreSQL и ее структуры
```bash
sudo -u postgres psql -d postgres -p 5432
CREATE DATABASE project; -- создаем базу project, где владелец - pguser. Это делаем чтобы не тратить время на настройку прав (не тема этого проекта)
\c project --переключаемся на БД project
CREATE SCHEMA IF NOT EXISTS test; --создаем схему
CREATE USER pguser PASSWORD 'qwerty'; - создаем пользователя через которого будет происходить подключение
ALTER DATABASE project OWNER TO pguser;
GRANT USAGE ON foreign server MSSQL to pguser; --даем права на работу с внешними таблицами
GRANT all ON schema test to pguser;  -- даем полные права на схему test
```
## 7.Устанавливаем расширение tds_fdw и настраиваем внешний сервер MSSQL2019
```bash
CREATE EXTENSION tds_fdw; --подключение расширения tds_fdw
CREATE SERVER MSSQL FOREIGN DATA WRAPPER tds_fdw  OPTIONS (servername 'MSSQL2019', database 'PM', msg_handler 'notice'); --создание сервера с подключением к MS SQL Server, servername берем из настройки freetds.conf
CREATE USER MAPPING FOR pguser SERVER MSSQL OPTIONS (username 'admin', password '12345'); -- Сопоставление пользователей pguser из PostgresSQL и adimn из MS SQL Server
```
Подключаем внешние таблицы из MS SQL Server таблицам. Наименование таблиц должны быть в кавычках, иначе они не подключаться но и ошибки не будет

```bash
SET ROLE pguser; --Переключемся на пользователя pguser
IMPORT FOREIGN SCHEMA "dbo"
LIMIT TO ("Change_type", "Owner_Object", "Operation_Kind", "Operation_type", "Employee", "Change_log", "Operation_log", "Exchange_log")
FROM SERVER MSSQL
INTO test;
```
При попытке сделать импорт схемы возникает ошибка
![image](https://github.com/user-attachments/assets/942970c2-b043-4f79-86bf-f315e3fbeb5a)

Проверяем что FreeTDS установлен и получаем ошибку 
```bash
tsql -C
```
![image](https://github.com/user-attachments/assets/4a7e0217-6c67-4090-80e2-67902950fab5)

У нас нет утилиты для тестирования FreeTDS. Пришлось ставить ее из отдельного пакета
```bash
sudo apt install freetds-bin
```
Проверяем, теперь утилита установлена и работает. Отображает данные по настройке FreeTDS
```bash
tsql -C
```
![image](https://github.com/user-attachments/assets/f5b7b0b2-6317-4b31-8d06-2675edef9005)

Но при проверке соединения все равно возникает ошибка
```bash
tsql -S MSSQL2019
```
![image](https://github.com/user-attachments/assets/8181df14-f9f9-45fb-bcc4-9f8424364892)

После поиска ошибки в интернете пришло понимание, что указание в настройках (/etc/freetds/freetds.conf) адрес MS SQL Server не верный. localhost - это служба FreeTDS будет искать внути WSL, а мне необходимо подключиться к локальной машине. 
```bash
ip route show | grep -i default | awk '{ print $3}'
```
![image](https://github.com/user-attachments/assets/dbcd27fd-a9dd-42f8-88d2-94be1cfbdc1e)

И меняем host на верный в настройке FreeTDS
```bash
sudo nano /etc/freetds/freetds.conf
```
![image](https://github.com/user-attachments/assets/b8e7981b-8635-4413-88dd-46e66bcbd230)

Проверяем что таблицы подключены.
```bash
sudo -u postgres psql -d project -p 5432
select * from information_schema.foreign_tables;
```
![image](https://github.com/user-attachments/assets/2eaf0440-0d9e-49b6-a4ee-fff9e167d7da)

## 8.Перенос данных справочных таблиц
Переключаемся на пользователя миграции, создаем схему и переносим данные по справочникам (5 таблиц)
```bash
set role pguser;
create schema if not exists dbo;
create table if not exists dbo.Change_type as select * from test."Change_type";
create table if not exists dbo.Owner_Object as select * from test."Owner_Object";
create table if not exists dbo.Operation_Kind as select * from test."Operation_Kind";
create table if not exists dbo.Operation_type as select * from test."Operation_type";
create table if not exists dbo.Employee as select * from test."Employee";
```
![image](https://github.com/user-attachments/assets/ec6a8978-67f8-4cdd-b98c-639129e19a28)

## 9. Переносим данных "больших" таблиц
Особенности:
1. limit оператор не работает, все равно выбирается сначала все записи, а потом производиться ограничение.
2. Для проверки использовано where
3. Для обращения к внешним таблицам и полям нужно всегда писать в их кавычках

При попытке выбрать данные из таблицы, где есть поле datetime2 (на стороне MS SQL SERVER), возникает ошибка. 
```bash
select *
from test."Operation_log" where "Operation_log"."ID_Operation_log"<100
```
![image](https://github.com/user-attachments/assets/196929c4-f0ce-4a67-ab05-9c5dd093b236)

Проблема именно в двоеточии вместо десятичной точки для типа datetime2. Для решения проблемы необходимо поменять тип данных на стороне PostgreSQL на текстовый, поменять двоеточие на точку и привести к типу timestamp.

Меняем типы и проверяем.
```bash
alter foreign table test."Operation_log" alter column "Operation_Date" SET DATA type VarChar(100);
alter foreign table test."Operation_log" alter column "Operation_End_Date" SET DATA type VarChar(100);
select 
       "ID_Operation_log",
       regexp_replace("Operation_Date",'(:..:..):','\1.')::timestamp as "Operation_Date",
       "ID_Operation_type",
       "Status",
       "ID_Employee",
       "Error",
       "Info",
       "Task_link",
       regexp_replace("Operation_End_Date",'(:..:..):','\1.')::timestamp as "Operation_End_Date", 
       "Operation_Guid"
from test."Operation_log" where "Operation_log"."ID_Operation_log"<100;
```
![image](https://github.com/user-attachments/assets/0c19a2e8-e79e-4d53-9373-cd0febdda62e)

Запускаем копирование данных таблицы test."Operation_log"
```bash
create table if not exists test.Operation_log as 
select 
       "ID_Operation_log",
       regexp_replace("Operation_Date",'(:..:..):','\1.')::timestamp as "Operation_Date",
       "ID_Operation_type",
       "Status",
       "ID_Employee",
       "Error",
       "Info",
       "Task_link",
       regexp_replace("Operation_End_Date",'(:..:..):','\1.')::timestamp as "Operation_End_Date", 
       "Operation_Guid"
from test."Operation_log";

ALTER TABLE test.Operation_log SET SCHEMA dbo; -- меняем схему, т.к. нужна схема dbo а не text

select * from dbo.Operation_log  limit 10; --проверяем что все перенеслось
```
![image](https://github.com/user-attachments/assets/d7da4cb0-2b52-4cbe-8b72-ef5908199b50)

Запускаем копирование данных оставшихся двух таблиц test."Change_log" и test."Exchange_log"
```bash
create table if not exists dbo.Change_log as select * from test."Change_log";
create table if not exists dbo.Exchange_log as select * from test."Exchange_log";
```
![image](https://github.com/user-attachments/assets/3cebb700-6639-4cde-8863-10046edaa5c4)
![image](https://github.com/user-attachments/assets/04ca79b0-40ab-434a-8350-c64951699145)

## 10. Подведение итогов
1. В PostgreSQL были созданы таблицы на основе "внешних" таблиц из MS SQL.
2. Перенесены данные как есть по всем 8 таблицам.
3. Соответствие типов было предложено самими расширением tds_fdw
4. Первичные, внешние ключи и индексы не переносились.
5. Перенос больших таблиц занял от 0.5 до 5 часов в зависимости от объема.

Использованные материалы:

https://winitpro.ru/index.php/2022/01/10/wsl-perenos/

https://wiki.postgresql.org/wiki/Foreign_data_wrappers

https://github.com/tds-fdw/tds_fdw

https://www.pvsm.ru/postgresql/200099?ysclid=m15hhupuj8902504740

https://habr.com/ru/companies/postgrespro/articles/309490/

https://postgrespro.ru/docs/postgresql/14/sql-importforeignschema

https://postgrespro.ru/docs/postgresql/14/infoschema-foreign-tables
   
https://habr.com/ru/articles/774486





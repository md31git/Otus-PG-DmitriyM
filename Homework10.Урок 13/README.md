## Замечание по реализации. 
Вместо виртальных машин буду использовать разные кластеры PG на одной ВМ. Для меня как разработчика БД развертываение нескольких ВМ и настройка доступа между ними явяется не тревиальной задачей и обычно приводить к "танцы с бубном" (опыт из предыдущих ДЗ). Право на развертывание ВМ оставим Администраторам БД, с которыми я в будущем планирую работать. Для понимания репликации и ее настройки достаточно работы с несколькими кластерами. Поэтому было принято такое решение. 

## 1. Создаение 4-х кластеров:

Первый кластер PG уже развернут (порт 5432, дериктория main):

![image](https://github.com/user-attachments/assets/8d41a60a-e964-403f-84fa-639b41bb6fd7)

Остальные рзворачиваем командами 
```bash
sudo pg_createcluster -d /var/lib/postgresql/14/main2 14 main2
sudo pg_createcluster -d /var/lib/postgresql/14/main3 14 main3
sudo pg_createcluster -d /var/lib/postgresql/14/main4 14 main4
```
И заппускаем их
```bash
sudo pg_ctlcluster 14 main2 start
sudo pg_ctlcluster 14 main3 start
sudo pg_ctlcluster 14 main4 start
```
Итого получилось 4 кластера PG:
1. порт 5432, дериктория main
2. порт 5433, дериктория main2
3. порт 5434, дериктория main3
4. порт 5435, дериктория main4

## 1.На Кластере 1 создаем таблицы test для записи, test2 для запросов на чтение.
Подключаемся к первому кластеру
```bash
sudo -u postgres psql	-d postgres -p 5432
```
Cоздаем базу db и схему test в ней и 2 таблицы в test (заплненную данными) и test2:
```bash
CREATE Database db;
\c db
CREATE schema test;
CREATE TABLE test.test as select generate_series as id, substr(md5(random()::text), 1, 25)::varchar(100) as name from generate_series(1,5,1);
CREATE TABLE test.test2(test_id int, decription varchar(100));
```
![image](https://github.com/user-attachments/assets/24d448ea-54fd-49b5-8ba9-cef2b164c829)

А также задаем пароль для пользователя, под которым будет происходить публикация (для упрощения берем пользователя postgres): pass5432
```bash
\password
```
![image](https://github.com/user-attachments/assets/3110fec8-bb01-44d8-9a8c-9ad19dab8e04)

## 2.На Кластере 2 создаем таблицы test2 для записи, test для запросов на чтение.
Подключаемся ко второму кластеру
```bash
sudo -u postgres psql	-d postgres -p 5433
```
Cоздаем базу db и схему test в ней и 2 таблицы в test (заплненную данными) и test2:
```bash
CREATE Database db;
\c db
CREATE schema test;
CREATE TABLE test.test(id int, name varchar(100));
CREATE TABLE test.test2(test_id int, decription varchar(100));
INSERT INTO test.test2 SELECT 1, 'Описание 1' UNION ALL SELECT 2, 'Описание 2';
```
![image](https://github.com/user-attachments/assets/47c0aed8-2e51-455b-a612-52dcb0b96dd5)

А также задаем пароль для пользователя под которым будет происходить публикация (для упрощения берем пользователя postgres): pass5433 
```bash
\password
```
![image](https://github.com/user-attachments/assets/c595e137-49a2-45ab-b53c-dd94acaa808f)


## 3.На кластере 1: Создаем публикацию таблицы test и подписываемся на публикацию таблицы test2 с ВМ №2.
Возвращаемся в кластер 1. Чтобы создать публикацию для логической репликации параметр сервера wal_level должен иметь значение logical и перезапустить PG. 
Иначе публикация создастся но не будет работать.
Но на кластере 1 уже установлено значени то что нам нужно. Поэтому ничего не меняем.
```bash
sudo -u postgres psql -d postgres -p 5432
show wal_level;
exit
```
![image](https://github.com/user-attachments/assets/ea0f459a-f77c-427c-827a-0d34711f509d)

Создаем публикацию и подписку.
```bash
CREATE PUBLICATION test_pub1 FOR TABLE test.test;
CREATE SUBSCRIPTION test2_sub1 
CONNECTION 'host=localhost port=5433 user=postgres password=pass5433 dbname=db' 
PUBLICATION test2_pub2 WITH (copy_data = false);
```
Подписка создаться если будет объект на который подписываешься. Если публикации на которую подписываешься не будет, то подписка создастся, но предупредит что публикации нет. 
![image](https://github.com/user-attachments/assets/8576d99b-7c1e-44f3-848c-d8b1cee0f9b4)

Проверяем что публикация создана:
```bash
\dRp+
select * from pg_publication_tables \gx
```
![image](https://github.com/user-attachments/assets/9f8b3dcd-d90e-4128-8a6c-a642f9aaa9aa)

Проверяем что подписка создана:
```bash
\dRs+
SELECT * FROM pg_stat_subscription \gx
```
![image](https://github.com/user-attachments/assets/bdd1cbff-b7e8-4949-bb8f-20ab468e80ee)

## 4.Создаем публикацию таблицы test2 и подписываемся на публикацию таблицы test1 с ВМ №1.
Возвращаемся в кластер 2. Чтобы создать публикацию для логической репликации параметр сервера wal_level должен иметь значение logical и перезапустить PG. 
```bash
sudo -u postgres psql -d postgres -p 5433
show wal_level;
ALTER SYSTEM SET wal_level = logical;
exit
sudo pg_ctlcluster 14 main2 restart
```
![image](https://github.com/user-attachments/assets/2bab2a31-f1e3-4383-9c5c-e3e7bfb9e8c8)

Создаем подписку(с копированием данных из таблицы кластера 1) и публикацию.
```bash
CREATE SUBSCRIPTION test_sub2 
CONNECTION 'host=localhost port=5432 user=postgres password=pass5432 dbname=db' 
PUBLICATION test_pub1 WITH (copy_data = true);
CREATE PUBLICATION test2_pub2 FOR TABLE test.test2;
```
![image](https://github.com/user-attachments/assets/7b9c9023-4b62-4b7f-b72f-fd5432243382)

Как мы видим что данные с кластера 1 таблицы test.test полностью перенесены логической репликацией в кластер 2 таблицы test.test, которая изначально было пустая.

## Процерка
При добавлении на Кластере 2 в таблицу test.test2 новых значений на Кластере 1 в таблице test.test2 они не появлялись.
```bash
tail -n 10 /var/log/postgresql/postgresql-14-main.log
```
![image](https://github.com/user-attachments/assets/80541624-e141-4a69-bb83-ae6f5b202ea7)

Выяснилось что созданная подписка на Кластере 1 test2_sub1 не видит публикацию test2_pub2 на Кластере 2, т.к. была создана ранее публикации. Пришлось удалять подписку и заново создавать и тогда все отработало корректно: добавленные новые данные в таблице test.test2 Кластера 2 появились на Кластере 1.

![image](https://github.com/user-attachments/assets/d89f8818-700b-419d-992d-aa6058ee45fd)

![image](https://github.com/user-attachments/assets/55b3dac7-f2f5-467b-a762-7d35cd74f75d)

## 5.Кластер 3 использовать как реплику для чтения и бэкапов (подписаться на таблицы из ВМ №1 и №2 ).
Заходим в Кластер 3 и создаем необходимую структуру для репликации:
```bash
sudo -u postgres psql -d postgres -p 5434
CREATE Database dbtest;
\c dbtest
CREATE schema test;
CREATE TABLE test.test(id int, name varchar(100));
CREATE TABLE test.test2(test_id int, decription varchar(100));
```
![image](https://github.com/user-attachments/assets/3d3ff8d8-ea7b-48e0-b2c0-29c085ff8a11)

**Внимание! Тут остается wal_level = replica, т.к. на 3 Кластере не надо создавать публикации, а создаем только подписки**

Создаем подписки на таблицы с первоначальным копированим данных (copy_data = true) и проверяем что они создались и данные скопированы:
```bash
CREATE SUBSCRIPTION test_sub3 
CONNECTION 'host=localhost port=5432 user=postgres password=pass5432 dbname=db' 
PUBLICATION test_pub1 WITH (copy_data = true);

CREATE SUBSCRIPTION test2_sub3 
CONNECTION 'host=localhost port=5433 user=postgres password=pass5433 dbname=db' 
PUBLICATION test2_pub2 WITH (copy_data = true);
```
![image](https://github.com/user-attachments/assets/0c513fcf-d375-4c86-8146-907ed34a5101)

Проверем что репликация работает. Заходим на Кластер 1 и создаем 2 записи в таблице test.test.

![image](https://github.com/user-attachments/assets/f5290d3b-da05-4ee3-aeba-83a64d418814)

Переходим на кластер 3 и проверяем наличие двух новых добавленных записей:

![image](https://github.com/user-attachments/assets/2ca9ca1c-1571-46ad-8055-1566f1750ba9)

Логическая репликаия работает!

## 6. Реализовать горячее реплицирование для высокой доступности на Кластере 4. Источником должна выступать Кластер 3. Написать с какими проблемами столкнулись
Здесь будем использовать физическую репликацию.

Проверяем что кластер работает и смотрим содержимое списка БД в кластере 4. Здесь тоже wal_level = replica
```bash
pg_lsclusters
sudo pg_ctlcluster 14 main4 start
sudo -u postgres psql -d postgres -p 5435
\l
Exit 
```
![image](https://github.com/user-attachments/assets/a4541098-85a6-4275-b7e3-20d24519c729)

Затем останавливаем Кластер 4 и удаляем его содержимое, чтобы можно было востановить туда данные из Кластера 3 и включить физическую репликацию.
```bash
sudo pg_ctlcluster 14 main4 stop
sudo rm -rf /var/lib/postgresql/14/main4
sudo -u postgres pg_basebackup -p 5433 -R -D /var/lib/postgresql/14/main4
sudo chown postgres -R /var/lib/postgresql/14/
sudo -u postgres pg_basebackup -p 5433 -R -D /var/lib/postgresql/14/main4
```
![image](https://github.com/user-attachments/assets/4355ce37-dd7b-4f1d-a986-c1926fb31846)

Пришлось дать права владельца на папку /var/lib/postgresql/14 пользователю postgres, иначе у него не было прав там созавать новую папку.

Запускаем сервер и смотрим состояние репликации и содержимое кластера (должно быть равно Кластеру 3)
```bash
sudo pg_ctlcluster 14 main4 start
pg_lsclusters
sudo -u postgres psql -d dbtest -p 5435
select * from test.test;
select * from test.test2;
```
![image](https://github.com/user-attachments/assets/fa35c938-68f8-432e-be3c-d189550654da)

Проверяем что физическая репликация работает на реплике (Кластер 4):

```bash
select * from pg_stat_wal_receiver \gx
```
![image](https://github.com/user-attachments/assets/c331e5e4-fd7b-4feb-8f1a-466b500cb8e1)

Проверяем что физическая репликация работает на мастере (Кластер 3):

```bash
sudo -u postgres psql -p 5434
SELECT * FROM pg_stat_replication \gx
```
![image](https://github.com/user-attachments/assets/6a77bb07-94d9-4fff-b640-dd8afb0b31e7)


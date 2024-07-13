## 1.Создаем ВМ/докер c ПГ
ВМ развернута и кластер PG 14.12 создан

![image](https://github.com/user-attachments/assets/419eb487-3ab0-4af5-884b-3c3ba4cd9457)

## 2.Создаем БД, схему и в ней таблицу и Заполним таблицы автосгенерированными 100 записями.
```bash
create database testdb2;
\c testdb2;
create schema test;
create table test.Pay1 as select t.id:: int, 'Наименование '||t.id::varchar(100) from (select generate_series(1,100,1) as id) t;
```

![image](https://github.com/user-attachments/assets/f4e7cb89-bc09-4ee6-ba5f-4e726ed6c5df)
![image](https://github.com/user-attachments/assets/d823e312-6673-4023-9952-51d11b02da2d)

## 3.Под линукс пользователем Postgres создадим каталог для бэкапов

Создаем каталог backup:

![image](https://github.com/user-attachments/assets/3b43ca9a-3d10-4612-87bf-f6b860c9cd4a)

Делаем владельцем пользователя postgres каталога backup, чтобы у него было прав создавать там файлы:

![image](https://github.com/user-attachments/assets/ba8ea941-a96c-4c37-ad82-210738920727)

## 4.Сделаем логический бэкап используя утилиту COPY
Подключаемся к PG под postgres и делаем копию данных (без создания структуры) таблицы в файл

![image](https://github.com/user-attachments/assets/3486c2c8-287c-43c9-aad2-b9187f3eeead)

Проверяем что файл создался (во 2-м подключении чтобы не переключаться между PG и ОС):
![image](https://github.com/user-attachments/assets/c8fa661c-bb56-4343-b4d3-34caec5ca6d6)


## 5.Восстановим в 2 таблицу данные из бэкапа.
Создаем пустую таблицу:

![image](https://github.com/user-attachments/assets/eeaa1473-60ab-4c0b-856b-96ffe558e92d)

При попытки скопировать данные из файла возникал ошибка (value too long for type character varying(10)):

![image](https://github.com/user-attachments/assets/b1d128ee-ddba-4f44-981d-20065e15bc43)

Причина: размер данных во 2 колонке в фале больше чем в таблице. Поэтому увеличиваем размер колонке в таблице и повторяем операцию:

![image](https://github.com/user-attachments/assets/c24ed5c1-38fd-4470-b984-4b4b79690521)

Вывод: можно восстанавливать в любую таблицу из файлов, главное чтобы кол-во колонок, а также типы были совместимы (не обязательно такие же как у исходной таблицы) и согласовывались по размерам с данными. 

## 6.Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц
Предварительно дал полные права на папку, т.к. при попытки выполнить дамп была ошибка: -bash: /backup/testdb2_bk.gz: Permission denied

![image](https://github.com/user-attachments/assets/2f41cf6e-70bf-433c-9a0c-277b99d47d18)

```bach
sudo -u postgres pg_dump -d testdb2 --create -Fc > /backup/testdb2_bk.gz
```
![image](https://github.com/user-attachments/assets/b8f55250-c452-471b-a5b2-59a292804c7d)


## 7.Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!
При восстановлнии были использованы дополнительные фалги: verbose -для вывода читаемого вида ошибок, single-transaction - чтобы операция была атомарной, -n test - только объекты из схемы test восстанавливать, -t pay2 - только таблицу pay2.
```bach
sudo -u postgres createdb testdb3 && sudo -u postgres pg_restore -d testdb3 --verbose --single-transaction -n test -t pay2 /backup/testdb2_bk.g
```
![image](https://github.com/user-attachments/assets/2d23b022-343f-477b-a2c0-130e9dcc215d)

Ошибка возникла, т.к. при указании таблицы или таблиц при восстановлении не восстанавлиаются объекты, от которых может зависеть таблица, в т.ч. и схема.

![image](https://github.com/user-attachments/assets/2ed23234-486c-4047-8d05-dc65584cf3e5)

Т.е. БД уже создана предудущей командой, необходимо вручную создать схему test в testdb3:

![image](https://github.com/user-attachments/assets/bde231f2-360e-4f0a-8aca-2f333e352ddb)

После этого выполним вторую часть комнады, которая "упала" в ошибку и проверим что таблица test.pay2 создалась и заполнилась данными (проверяем первые 10 строк для сокращения вывода):

```bach
sudo -u postgres pg_restore -d testdb3 --verbose --single-transaction -n test -t pay2 /backup/testdb2_bk.gz
```
![image](https://github.com/user-attachments/assets/5206c898-918a-4a2c-893f-74769b060270)







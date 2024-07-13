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
Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!

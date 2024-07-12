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


![image](https://github.com/user-attachments/assets/3b43ca9a-3d10-4612-87bf-f6b860c9cd4a)

![image](https://github.com/user-attachments/assets/ba8ea941-a96c-4c37-ad82-210738920727)


Сделаем логический бэкап используя утилиту COPY
Восстановим в 2 таблицу данные из бэкапа.
Используя утилиту pg_dump создадим бэкап в кастомном сжатом формате двух таблиц
Используя утилиту pg_restore восстановим в новую БД только вторую таблицу!

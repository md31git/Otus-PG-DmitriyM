# Otus-PG-DmitriyM
## Урок 2. SQL и реляционные СУБД. Введение в PostgreSQL 
Работа производиться в DBeaver v.24
### 0. Выключение автоматической фиксации транзакции
Выключение через отдельную кнопку на панели.
Если через команду:
 ```sql
/set AUTOCOMMIT off
  ```
### 1. Создание и наполнение таблицы persons
Сессия 1:
```sql
create table persons
 (
     id serial, 
     first_name text, 
     second_name text);
    
insert into persons(first_name, second_name)
values('ivan', 'ivanov'), 
      ('petr', 'petrov');
commit;

id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 ```
 ### 2. Посмотреть текущий уровень изоляции
 ```sql
 show transaction isolation level;
transaction_isolation|
---------------------+
read committed       |
 ```
 ### 3. Исследование уровня изоляции транзакции 'read committed':
 **Сессия 1**
 Шаг 1
  ```sql
 insert into persons(first_name, second_name) 
 values('sergey', 'sergeev');
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
  ```
 Шаг 3
   ```sql
 commit;
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
  ```
 **Сессия 2**
 Шаг 2
   ```sql
 select * from persons
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
   ```
  Шаг 4
   ```sql
 select * from persons
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
   ```  
 **Вывод:**
 В Сессии 2 новую добавленную запись не видно, т.к. уровень изоляции транзакции 'read committed' видит только завершенные транзакции. После завершения транзакции в Сессии 1, Сессия 2 увидела новую запись.
 В свою очередь в Сессии 1 видно новую запись, т.к. для нее открытая, но не завершенная транзакция является текущей и все ранее созданные изменения, даже не зафиксированные, видны.
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

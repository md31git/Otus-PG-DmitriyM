# Otus-PG-DmitriyM
## Урок 2. SQL и реляционные СУБД. Введение в PostgreSQL 
Работа производится в DBeaver v.24
### 0. Выключение автоматической фиксации транзакции
#### **Шаг 1.Сессия 1 и 2**
Выключение через отдельную кнопку на панели.
Если через команду:
 ```sql
/set AUTOCOMMIT off
  ```
### 1. Создание и наполнение таблицы persons
#### **Шаг 1.Сессия 1**
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
 #### **Шаг 1.Сессия 1 и 2**
 ```sql
 show transaction isolation level;
transaction_isolation|
---------------------+
read committed       |
 ```
 ### 3. Исследование уровня изоляции транзакции 'read committed'
 _Запросы выполняются последовательно согласно номерам шагов_
 #### **Шаг 1.Сессия 1**
  ```sql
 insert into persons(first_name, second_name) 
 values('sergey', 'sergeev');
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
  ```
 Выполнением insert мы открыли новую транзакцию в Сессии 1. Новая запись сразу видна, т.к. это текущая транзакция и все изменения видны сразу внутри одной транзакции.
  #### **Шаг 2.Сессия 2**
   ```sql
 select * from persons
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
   ```
  В Сессии 2 новую добавленную запись не видно, т.к. уровень изоляции транзакции 'read committed' видит только завершенные транзакции, а в Сессии 1 транзакция не звершена.  
  #### **Шаг 3.Сессия 1**
   ```sql
 commit;
 id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
  ```
 Завершаем транзакцию в Сессии 1. Изменения теперь зафиксированы в БД и видны для всех сессий с уровнем изоляции транзакции 'read committed'. 
  #### **Шаг 4.Сессия 2**
   ```sql
 select * from persons
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
   ```  
 После завершения транзакции в Сессии 1, Сессия 2 увидела новую запись, хотя транзакция в Сессии 2 не завершена. После ее завершения результат не изменится. Мы получили фантомное чтение: две одинаковые выборки (Шаг 2 и 4), запущенные в разное время, дали разный результат.
 
 ### 4. Исследование уровня изоляции транзакции 'read committed'
  _Запросы выполняются последовательно согласно номерам шагов_
  #### **Шаг 1. Сессия 1 и 2**
```sql
 set session characteristics as transaction isolation level repeatable read;
 show transaction isolation level;
 transaction_isolation|
---------------------+
repeatable read      |
 ```
  Устанавливаем для Сессии 1 и 2 уровень изоляции транзакции на соединение в целом для удобства, чтобы можно было запускать операции по отдельности.
  #### **Шаг 2. Сессия 2**
```sql
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 ```
 Выполнением select мы открыли новую транзакцию в Сессии 2.
  #### **Шаг 3. Сессия 1**
```sql
insert into persons(first_name, second_name) 
values('sveta', 'svetova');
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 4|sveta     |svetova    |
 ```
 Выполнением insert мы открыли новую транзакцию в Сессии 1. Новая запись сразу видна, т.к. это текущая транзакция и все изменения видны сразу внутри одной транзакции.
  #### **Шаг 4. Сессия 2**
```sql
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 ```
 Выборка в Сессии 2 не видит добавленную запись в Сессии 1, т.к. транзакция в Сессии 1 не завершена.
  #### **Шаг 5. Сессия 1**
```sql
commit;
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 4|sveta     |svetova    |
 ``` 
 Завершаем транзакцию в Сессии 1. Изменения теперь зафиксированы в БД и видны для всех сессий с уровнем изоляции транзакции 'read committed'.
   #### **Шаг 6. Сессия 2**
```sql
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 ```
 В Сессии 2 все также не видно новую добавленную запись в Сессии 1, т.к. для уровня изоляции транзакции 'repeatable read' создается снимок БД на момент выполнения первой команды транзакции (шаг 2). Далее все открытые и зафиксированные позже транзакции до завершения транзакции в Сессии 2 видны ей не будут. Исключаются фантомные чтения.
   #### **Шаг 7. Сессия 2**
```sql
commit;
select * from persons;
id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 3|sergey    |sergeev    |
 4|sveta     |svetova    |
 ``` 
Как только была завершена транзакция в Сессии 2, то выборка из таблицы persons отобразила новую добавленную запись. Это случилось потому что мы открыли новую транзакции и получили снимок БД на этот момент, к которому уже новая запись была добавлена в БД и зафиксирована транзакцией в Сессии 1.

**ВЫВОД:** 
* repeatable read - работает со снимком на момент первого оператора в транзакции
* read committed - работает со снимком на момент каждого оператора в транзакции
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

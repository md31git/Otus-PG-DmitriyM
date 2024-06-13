# Otus-PG-DmitriyM
## Урок 2. SQL и реляционные СУБД. Введение в PostgreSQL 

### 1. Создание и наполнение таблицы persons
```sql
create table persons
 (
     id serial, 
     first_name text, 
     second_name text);
    
insert into persons(first_name, second_name)
values('ivan', 'ivanov'), 
      ('petr', 'petrov');

id|first_name|second_name|
--+----------+-----------+
 1|ivan      |ivanov     |
 2|petr      |petrov     |
 ```
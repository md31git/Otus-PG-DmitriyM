## 1 Получаем размеры таблиц 
```bash
SELECT C.relname AS "relation",
       pg_size_pretty (pg_relation_size(C.oid)) as table,
       pg_size_pretty (pg_table_size(C.oid) - pg_relation_size(C.oid)) as TOASTtable
FROM pg_class C
WHERE  C.relname IN ('exchange_log', 'operation_log','change_log');
```
![image](https://github.com/user-attachments/assets/024dc2ac-6cd2-4c7b-8204-7e5d6c64d0ae)

## 2 Анализ типов полей в таблицах
### 2.1 dbo.exchange_log 
![image](https://github.com/user-attachments/assets/b72ace71-6a65-41ff-860e-3712024ecf1b)

Тут смысловых полей всего два Input_xml, Output_xml. В них хранятся входные и выходные запросы в формате xml, но тип данных text.

По идее надо изменить тип данных на xml, но этого делать не будем, т.к. по этим полям необходим поиск строки в строке и для полнотекстового поиска нужно все равно преобразовывать в тип text, а индексов на тип xml в PostgreSQL нет.

**Итого: ничего не меняем**
### 2.2 dbo.change_log
![image](https://github.com/user-attachments/assets/cba17ae6-d514-437a-bb32-01baa2326ef2)

Что планируется сделать:

1.Для полей справочников "ID_Owner_Object" и "ID_Change_Type" имеет смысл уменьшить размерность с Int до SmallInt. Это сократит в два раза занимаемый объем данных этим полем с 8 байт до 4 байт

2.В PostgreSQL есть понятие "выравнивание" столбцов фиксированной длины до 8 байт. Поэтому необходимо придерживаться следующего правила расположения столбцов в таблице:

**Сначала идут широкие столбцы, затем средние, маленькие столбцы в последнюю очередь, а столбцы переменного размера, такие как NUMERIC и TEXT, в самом конце**

Подробнее можно ознакомиться тут: https://habr.com/ru/articles/756074/

Проведем эксперимент - создадим еще две копии таблицы, где в первой копии изменение будет как типов, так и порядка (согласно рекомендации выше), а во второй только типов и проверим их размерность. 

Копия первая (поля поменяны местами "ID_Change_Type" и "Data_xml"):
```Bash
create table dbo.change_log_new as
select 
       "ID_Change_log",
       "ID_Operation_log",
       "ID",
       cast("ID_Owner_Object" as smallint) as "ID_Owner_Object", 
       cast("ID_Change_Type" as smallint) as "ID_Change_Type",
       "Data_xml"       
from dbo.change_log;

```
Копия вторая:
```Bash
create table dbo.change_log_new_2 as
select 
       "ID_Change_log",
       "ID_Operation_log",
       "ID",
       cast("ID_Owner_Object" as smallint) as "ID_Owner_Object", 
       "Data_xml",
       cast("ID_Change_Type" as smallint) as "ID_Change_Type"
from dbo.change_log;
```
Проверяем размеры копий и исходной таблицы:
```Bash
SELECT C.relname AS "relation",
       pg_relation_size(C.oid),
       pg_size_pretty (pg_relation_size(C.oid)) as table,
       pg_size_pretty (pg_table_size(C.oid) - pg_relation_size(C.oid)) as TOASTtable
FROM pg_class C
WHERE  C.relname IN ('change_log', 'change_log_new', 'change_log_new_2');
```
![image](https://github.com/user-attachments/assets/d3965f1e-146f-47e9-88b8-baf5b002ce93)

**Хотя и видно что размерность полей больше повлияло на размер таблицы, чем порядок. Но для таблиц с большим набором полей меньше 8 байт и большим количеством записей перестановка порядка полей может сократить размер таблицы на 10-20% и соответственно ускорить работу с ней.**

К сожаления в PostgreSQL нет возможности переставить последовательность полей налету, поэтому придется использовать следующий подход: создаем копию таблицы, удаляем исходную таблицу и затем переименовываем новую. Также незабываем создать PK, FK, индексы, триггеры и прочие объекты принадлежащие таблице. Сделаем это:
```Bash
drop table dbo.change_log;
alter table dbo.change_log_new rename to change_log;
drop table dbo.change_log_new_2;
```
Также необходимо изменить тип поля в самих справочниках:
```Bash
   ALTER TABLE dbo.Change_type alter column "ID_Change_type" type Smallint using "ID_Change_type"::smallint;
   ALTER TABLE dbo.Owner_object alter column "ID_Owner_object" type Smallint using "ID_Owner_object"::smallint;
```
**Итог: изменили тип у двух полей и поменяли порядок полей, что уменьшило размер таблицы на 5%**

![image](https://github.com/user-attachments/assets/baee2fb7-4fba-41b7-b3be-1a9b0452635b)

### 2.3 dbo.operation_log
![image](https://github.com/user-attachments/assets/c8819aab-1613-46c4-a7ce-6f51fbd435d0)

Что планируется сделать:

1.Для полей справочников "ID_Employee" и "ID_Operation_Type" имеет смысл уменьшить размерность с Int до SmallInt. Это сократит в два раза занимаемый объем данных этим послем с 8 байт до 4 байт.

2.Поле "Status" меняем на boolean (c 2 байт до 1 байта), поле "Operation_Guid" с varchar меняем на UUId (быстрее и компактнее, занимаем 16 байт) для оптимизации хранения.

3.Изменение порядка полей для более оптимального хранения данных производить не будем, т.к. это потребует много времени выполнения (создание копии таблицы, пересоздания PK, FK и индексов (они уже созданы на текущий момент)) и считаю нецелесообразным. Тем более тут расположение полей почти оптимальное. Необходимо лишь поля "Error","Info","Task_link" перенести в конец таблицы. Посмотрим положение полей и размерность:
```Bash
SELECT a.attname, t.typname, t.typalign, t.typlen
  FROM pg_class c
  JOIN pg_attribute a ON (a.attrelid = c.oid)
  JOIN pg_type t ON (t.oid = a.atttypid)
WHERE c.relname = 'operation_log'
   AND a.attnum >= 0
 ORDER BY a.attnum;
```
![image](https://github.com/user-attachments/assets/971042b8-e6f9-4a0d-8e73-3dac1b1a756f)

Тут видно следующее: после изменения размеров полей, три поля ID_Operation_type, Status, ID_Employee вместе будут занимать 5 байт, чтобы будет помещаться в 8 байт и будет оптимально, т.к. больше нет других полей мнеьше 8 байт.  

Замерим размер таблицы до изменения 
```Bash
SELECT C.relname AS "relation",
       pg_relation_size(C.oid) as table_bytes,
       pg_size_pretty (pg_relation_size(C.oid)) as table,
       pg_size_pretty (pg_table_size(C.oid) - pg_relation_size(C.oid)) as TOASTtable,
       pg_indexes_size(C.oid) as "Index_bytes",
       pg_size_pretty (pg_indexes_size(C.oid)) as "Index"
FROM pg_class C
WHERE  C.relname IN ('operation_log');
```
![image](https://github.com/user-attachments/assets/1738f8cd-c5aa-477d-aa83-152cfe508966)

Выполним изменение 
```Bash
alter table dbo.operation_log 
     alter column "Status" type Boolean using "Status"::Int::boolean,
     alter column "Operation_Guid" type UUID using "Operation_Guid"::UUID,
     alter column "ID_Operation_type" type smallint using "ID_Operation_type"::smallint,
     alter column "ID_Employee" type smallint using "ID_Employee"::smallint;
```
После изменения типов полей:
![image](https://github.com/user-attachments/assets/24a3e626-0233-41b6-b3c0-62b4f89e8346)
Размер индексов уменьшился на 30%, а данных на 35%. Что составило более 7Гб.

Также необходимо изменить тип поля в самих справочниках:
```Bash
   ALTER TABLE dbo.Employee alter column "ID_Employee" type Smallint using "ID_Employee"::smallint;
   ALTER TABLE dbo.Operation_kind alter column "ID_Operation_kind" type Smallint using "ID_Operation_kind"::smallint;
   ALTER TABLE dbo.Operation_type alter column "ID_Operation_type" type Smallint using "ID_Operation_type"::smallint;
```
**Итог: изменили тип у 4 полей, что уменьшило размер таблицы более чем на 30%**

![image](https://github.com/user-attachments/assets/4258d943-ff96-4a41-97e0-3594633c037c)














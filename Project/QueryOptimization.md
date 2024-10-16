## 1 Исходные данные
### 1.1 Запрос, выводящий необходимые данные для пользователя.
```Bash
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from dbo.Operation_log        ol
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
order by ol."Operation_Date" desc
limit 10000;
```
### 1.2 Наиболее частные запросы - поиски
#### Поиск 1. 
 * Поиск по идентификатору операции (Operation_log.ID_Operation_log)
#### Поиск 2.
 * Поиск Guid запроса, который сохранен в отдельном поле (Operation_log.Operation_Guid)
#### Поиск 3. 
* Дата операции в диапазоне дат (Operation_log.Operation_Date). 90% запросов за последние 2 месяца, остальные 10% за другие периоды.
* Тип операции (список значений через запятую) (Operation_log.ID_Operation_Type)
* Поиск по тексту входящего запроса (Exchange_log.Input_xml) 
#### Поиск 4. 
* Вид объекта (Сhange_log.ID_Owner_Object)
* Идентификатор объекта  (Сhange_log.Id)


## 2 Поиск 1.
```Bash
Explain
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from dbo.Operation_log        ol
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
where ol."ID_Operation_log" = 1000
order by ol."Operation_Date" desc;
```
План запроса без каких-либо индексов и актуальной статистики выглядит "ужасно". Почти все соединения таблиц производиться через Hash join. Планировщик попытался распараллелить запросы, чтобы хоть как-то уменьшить время выполнения, но все равно это очень долго. 

![image](https://github.com/user-attachments/assets/ff3e6608-9af0-4ae3-9073-6d97ba9cd0cb)

Использование таблиц в PostgreSQL без первичного ключа может привести к проблемам с целостностью данных и производительностью. Могут появиться дублирующие строки, а производительность поиска может значительно снизиться. Также с будут проблемы с репликацией: если на узел кластера приходит строка изменения без первичного ключа, то приходится делать полное сканирование таблицы и искать, в какой строке появились изменения. 

**Вывод 1 - Общий рекомендаций:** 
1. Необходимо на каждую таблицу создать первичный ключ, чтобы можно было однозначно идентифицировать каждую запись.
2. На связанные таблицы создать внешний ключ на ранее созданные первичные ключи.
   
**Вывод 2 -  исходя из плана запроса:**
1. Не хватает индекса на поле  dbo.Operation_log."ID_Operation_log". Наличие сканирование таблицы Seq Scan
2. Не хватает индекса на поле  dbo.Exchange_log."ID_Operation_log". Наличие сканирование таблицы Seq Scan

### 2.1 Создание Primary key
```Bash
   ALTER TABLE dbo.Change_type ADD CONSTRAINT "PK_Change_type(ID_Change_type)" PRIMARY KEY ("ID_Change_type");
   ALTER TABLE dbo.Employee ADD CONSTRAINT "PK_Employee(ID_Employee)" PRIMARY KEY ("ID_Employee");
   ALTER TABLE dbo.Operation_kind ADD CONSTRAINT "PK_Operation_kind(ID_Operation_Kind)" PRIMARY KEY ("ID_Operation_Kind");
   ALTER TABLE dbo.Operation_type ADD CONSTRAINT "PK_Operation_type(ID_Operation_type)" PRIMARY KEY ("ID_Operation_type");
   ALTER TABLE dbo.Owner_object ADD CONSTRAINT "PK_Owner_object(ID_Owner_Object)" PRIMARY KEY ("ID_Owner_Object");

   ALTER TABLE dbo.Operation_log ADD CONSTRAINT "PK_Operation_log(ID_Operation_log)" PRIMARY KEY ("ID_Operation_log");
   ALTER TABLE dbo.Exchange_log ADD CONSTRAINT "PK_Exchange_log(ID_Exchange_log)" PRIMARY KEY ("ID_Exchange_log");
   ALTER TABLE dbo.Change_log ADD CONSTRAINT "PK_Change_log(ID_Change_log)" PRIMARY KEY ("ID_Change_log");
```

После создания проверим на сколько увеличился объем данных по таблицам (прирост более 5Гб). Про таблицам справочникам прирост не существенный, т.к. сами таблицы содержать немного данных

```bash
SELECT C.relname AS "relation",
       pg_size_pretty (pg_relation_size(C.oid)) as table,
       pg_size_pretty (pg_table_size(C.oid) - pg_relation_size(C.oid)) as TOASTtable,
       pg_size_pretty (pg_indexes_size(C.oid)) as "Index"
FROM pg_class C
WHERE  C.relname IN ('exchange_log', 'operation_log','change_log');
```
![image](https://github.com/user-attachments/assets/513141b5-334c-4c38-b42c-ebdda7898c58)

### 2.2 Создание Внешних ключей и индексов на них.
```bash
  create index "IX_Exchange_log(ID_Operation_log)" on dbo.Exchange_log ("ID_Operation_log"); 
  create index "IX_Change_log(ID_Operation_log)" on dbo.Change_log ("ID_Operation_log");  
  ALTER TABLE dbo.Exchange_log ADD CONSTRAINT "FK_Exchange_log(ID_Operation_log)" FOREIGN KEY ("ID_Operation_log") REFERENCES dbo.Operation_log("ID_Operation_log");
  ALTER TABLE dbo.Change_log ADD CONSTRAINT "FK_Change_log(ID_Operation_log)" FOREIGN KEY ("ID_Operation_log") REFERENCES dbo.Operation_log("ID_Operation_log");
```
После создания запрос выполняется меньше чем за 1 сек.
![image](https://github.com/user-attachments/assets/36e87715-af8a-4630-89ce-2c079d36aeed)

### 3 Поиск 2
```bash
explain 
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from dbo.Operation_log        ol
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
where ol."Operation_Guid" = 'df356347-6462-4235-9631-d9aed0bf4a4a'
order by ol."Operation_Date" desc;
```

![image](https://github.com/user-attachments/assets/82851f60-662a-44b1-837a-6eaf671a1702)

Самая долгая операция - это Seq Scan - полное сканирование таблицы, т.к. индекса на поле Operation_Guid нет. 
```bash
  create index "IX_Operation_log(Operation_Guid)" on dbo.Operation_log("Operation_Guid"); 
```
После создания индекса запрос выполняется на порядки быстрее
![image](https://github.com/user-attachments/assets/3d935a72-d1bb-4abe-b892-c74362ff990e)

### 4 Поиск 3
```bash
explain 
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from dbo.Operation_log        ol
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
where ol."Operation_Date" >= '20220701' and ol."Operation_Date" <= '20220705'
      and ol."ID_Operation_type"= 173
      and el."Input_xml" like '%1051783%'
order by ol."Operation_Date" desc;
```
![image](https://github.com/user-attachments/assets/69439de7-1bdc-45d6-acb9-c94d54520674)
Тут идет параллельное сканирование таблицы dbo.Operation_log  с фильтрацией по дате операции и его типу и поиск по индексу в таблице dbo.Exchange_log с фильтрацией по полю Input_xml (текст входящего запроса).

Здесь появилась мысль о том чтобы ускорить выполнение запроса необходимо разделить его на две части:
1.Сначала мы получаем список ID_Operation_log во временную таблицу
2.Потом по этому списку из временной таблицы получаем данные для пользователя. 

### 4.1 Новый вариант выборки, разделенный на 2 запроса
```bash
create temporary table if not exists _Operation_log (id bigint primary key);
explain
insert into _Operation_log (Id)
select ol."ID_Operation_log"
from dbo.Operation_log ol
where ol."Operation_Date" >= '20200801' and ol."Operation_Date" <= '20200831'
      and ol."ID_Operation_type"= 41
      and exists(select 1 
                 from dbo.Exchange_log el
                 where el."ID_Operation_log" = ol."ID_Operation_log"
                     and el."Input_xml" like '%12605930%'
                 limit 1
                );

explain
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from _Operation_log t
inner join dbo.Operation_log  ol on ol."ID_Operation_log" = t."id"
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
order by ol."Operation_Date" desc;
```
Даже разделение на две части запрос все еще очень долго выполняется (ожидание больше получаса и он не завершился).
Теперь оптимизируем именно первую часть где фильтруются данные. 

План следующий:

1. На таблицу dbo.Operation_log сделать индекс на дату операции с включенными столбцами Тип операции и сам id операции. По сути сделаем покрывающий индекс, что должно существенно ускорить запрос. А также этим же индексом ускорим сортировку "order by ol."Operation_Date" desc".
2. На таблицу dbo.Exchange_log нужно создать индекс для полнотекстового поиска.
   
   а) поиск через приведение к tsvector без индекса
   
   б) поиск через приведение к tsvector с индексом
   
   в) создание отдельной таблицы для хранения данных в формате tsvector. Но этот вариант требует дополнительные накладные расходы при добавления данных (триггер на заполнения новой таблице на основе данных "основной").

### 4.1.1 Индекс на таблицу dbo.Operation_log
```bash
  create index "IX_Operation_log(Operation_Date)" on dbo.Operation_log("Operation_Date") 
  include ("ID_Operation_type", "ID_Operation_log"); 
```
Проверяем насколько ускорился запрос. 
```bash
create temporary table if not exists _Operation_log (id bigint primary key);
truncate _Operation_log;

explain analyze
insert into _Operation_log (Id)
select ol."ID_Operation_log"
from dbo.Operation_log ol
where ol."Operation_Date" >= '20200801' and ol."Operation_Date" <= '20200831'
      and ol."ID_Operation_type"= 41
      and exists(select 1 
                 from dbo.Exchange_log el
                 where el."ID_Operation_log" = ol."ID_Operation_log"
                     and el."Input_xml" like '%12605930%'
                 limit 1
                );

explain analyze
select
    ol."ID_Operation_log"   as "Id",
    ol."Operation_Date"     as "Дата/время",
    ol."Operation_End_Date" as "Дата/время завершения",
    ot."Operation_type"     as "Операция",
    K."Operation_Kind"      as "Тип операции",
    E."FIO"                 as "ФИО",
    ol."Info"               as "Примечание",
    ol."Error"              as "Ошибка",
    ol."Status"             as "Успех",
    el."Input_xml"          as "Вх. запрос", 
    el."Output_xml"         as "Исх. запрос"
from _Operation_log t
inner join dbo.Operation_log  ol on ol."ID_Operation_log" = t."id"
inner join dbo.Employee        E on E."ID_Employee" = ol."ID_Employee"
inner join dbo.Operation_type ot on ot."ID_Operation_type" = ol."ID_Operation_type"
inner join dbo.Operation_Kind  K on K."ID_Operation_Kind" = ot."ID_Operation_Kind"
 left join dbo.Exchange_log   el on el."ID_Operation_log" = ol."ID_Operation_log"
order by ol."Operation_Date" desc;
```
![image](https://github.com/user-attachments/assets/3e3f41e8-900f-4946-ae8c-be3eabdf4ca1)
Даже добавления одного индекса ускорило выполнение запроса. Всего 5 сек, чтобы найти все идентификаторы операций (10 штук).
![image](https://github.com/user-attachments/assets/da63cdc1-3a9b-46e2-9f73-81383027a698)
Сам же запрос для пользователя выполнился за 0.2 сек. Это очень хороший результат. 

Далее имеет смысл "ускорять" только первый запрос - заполнение временной таблицы.

#### Дополнение 
После изменения размерности полей в таблице, индекс "IX_Operation_log(Operation_Date)" перестает использоваться планировщиком. Почему - непонятно. 

Vacuum Full и обновление статистики по таблице результата не дало. Все равно планировщик решает использовать Seq Scan, хотя запрос не менялся. 
![image](https://github.com/user-attachments/assets/c3271077-1918-4127-b716-106186d52f05)

Только создание индекса где поле "ID_Operation_type" перенесено в сам индекс из Include вернуло операцию Index only scan (сканирование только индекса без обращение к данным)
```bash
  create index "IX_Operation_log(Operation_Date,ID_Operation_type)" on dbo.Operation_log("Operation_Date","ID_Operation_type") 
  include ("ID_Operation_log"); 
```
![image](https://github.com/user-attachments/assets/9d10b891-2f97-4639-be6e-969b0db8583f)

### 4.1.2 Индекс на таблицу dbo.Exchange_log

Для упрощения тестирования используем только select из первого запроса.

#### а) Поиск простой через like без индекса
```bash
explain analyze
select ol."ID_Operation_log"
from dbo.Operation_log ol
where ol."Operation_Date" >= '20200801' and ol."Operation_Date" <= '20200831'
      and ol."ID_Operation_type"= 41
      and exists(select 1 
                 from dbo.Exchange_log el
                 where el."ID_Operation_log" = ol."ID_Operation_log"
                     and el."Input_xml" like '%12605930%'
                 limit 1
                );
```
![image](https://github.com/user-attachments/assets/b8606bee-7ef5-4241-9229-90050a74e07d)

**Результат: 5 сек** 

#### б)Поиск через приведение к tsvector без индекса
```bash
explain analyze
select ol."ID_Operation_log"
from dbo.Operation_log ol
where ol."Operation_Date" >= '20200801' and ol."Operation_Date" <= '20200831'
      and ol."ID_Operation_type"= 41
      and exists(select 1 
                 from dbo.Exchange_log el
                 where el."ID_Operation_log" = ol."ID_Operation_log"
                     and to_tsvector(el."Input_xml") @@ to_tsquery('12605930:*')
                 limit 1
                );               
```
![image](https://github.com/user-attachments/assets/b8e9563e-17bb-4dd0-9aac-a1674c75262c)

**Результат: 7 сек** 

#### в)Создание отдельной таблицы для хранения данных в формате tsvector.
```bash
create table dbo.exchange_log_Extended as
select 
"ID_Operation_log",
to_tsvector(regexp_replace(el."Input_xml",'[<>/]',' ','g')) as "Input_ts",
to_tsvector(regexp_replace(el."Output_xml",'[<>/]',' ','g')) as "Output_ts"
from dbo.exchange_log el;

create index "IX_exchange_log_Extended(ID_Operation_log)" on dbo.exchange_log_Extended("ID_Operation_log"); 
```
Получаем ошибку что длина строки превышает максимальную 
![image](https://github.com/user-attachments/assets/43b2be23-e82e-4bc6-b6a4-2c64489e32b4)
Необходимо изменить скрипт создания таблицы (см. https://stackoverflow.com/questions/30470151/postgresql-how-to-go-around-ts-vector-size-limitations)
```bash
create table dbo.exchange_log_Extended as
select 
"ID_Operation_log",
to_tsvector(regexp_replace(el."Input_xml",'[<>/]',' ','g')) as "Input_ts",
to_tsvector(regexp_replace(el."Output_xml",'[<>/]',' ','g')) as "Output_ts"
from dbo.exchange_log el;

create index "IX_exchange_log_Extended(ID_Operation_log)" on dbo.exchange_log_Extended("ID_Operation_log"); 
```
И все равно получаю ошибку.
![image](https://github.com/user-attachments/assets/920112d7-1b03-4d3d-8147-05f16278a7e4)

**Результат:**
Я отказался от создание отдельной таблицы по следующим причинам:
1. В итоге будут неполные данные для поиска (обрезаем текст до 1 Гб)
2. Будет вторая таблица практически равная по размеру самой большой таблицы.
3. Необходимо отдельная поддержка наполнения новой таблицы даннымии через триггер и как следствие накладные расходы.

#### г)Создание индекса GIST на поле "Input_Xml" для полнотекстового поиска
Для этого устанавливаем расширение pg_trgm
```bash
create extension pg_trgm;
create index "IX_gist_Exchange_log(Input_xml)" on dbo.Exchange_log 
using gist ("Input_xml" gist_trgm_ops);
```
![image](https://github.com/user-attachments/assets/a7ecc56a-e637-41b5-8fdd-6ce6aa83eb87)

**Результат: ошибка - превышен максимальный размер строки индекса**

#### д)Создание индекса GIN на поле "Input_Xml" для полнотекстового поиска
```bash
create index "IX_gin_Exchange_log(Input_xml)" on dbo.Exchange_log 
using gin ("Input_xml" gin_trgm_ops);
```
![image](https://github.com/user-attachments/assets/0c52df2f-37ad-446e-a8b7-a1dcd2787a2c)

Индекс создан успешно, но при проверке запроса выходит ошибка в данных.
```bash
explain analyze
select ol."ID_Operation_log"
from dbo.Operation_log ol
where ol."Operation_Date" >= '20200801' and ol."Operation_Date" <= '20200831'
      and ol."ID_Operation_type"= 41
      and exists(select 1 
                 from dbo.Exchange_log el
                 where el."ID_Operation_log" = ol."ID_Operation_log"
                     and el."Input_xml" like '%12605930%'
                 limit 1
                );
```
![image](https://github.com/user-attachments/assets/97c5bcab-f9a3-401a-a8ba-e67d24a070e7)

По id объекта определяем где ошибка и находим что это наш индекс Gin "IX_gin_Exchange_log(Input_xml)"
```bash
select pg_filenode_relation(0,1032906);
```
![image](https://github.com/user-attachments/assets/869bad41-476b-45af-90bd-483befd6de27)

Если отключаешь созданный индекс "IX_gin_Exchange_log(Input_xml) при помощи команды ниже, то ошибки не возникает.
```bash
update pg_index
SET indisvalid = False
WHERE indexrelid = 'dbo."IX_gin_Exchange_log(Input_xml)"'::regclass;
```

Попытка "исправить" поврежденные страницы и пересоздать индекс не увенчалась успехом. Ошибка никуда не ушла. 
```bash
SET zero_damaged_pages = on;
vacuum full dbo.exchange_log;
SET zero_damaged_pages = off;
reindex INDEX dbo."IX_gin_Exchange_log(Input_xml)";
```

В итоге (если бы индекс работал) план запроса бы выглядел так:
 
![image](https://github.com/user-attachments/assets/fc5a94bd-f2ce-4485-9f3b-7a20827516c7)

**Результат: Индекс получилось создать, но использовать нельзя. Скорее всего по причине превышение размера.**

### 5 Поиск 4
Тут необходим поиск по Вид объекта (Сhange_log.ID_Owner_Object) и Идентификатор объекта (Сhange_log.Id). Это поля находятся в одной таблице dbo.Сhange_log
```bash
explain analyze
select ol."ID_Operation_log"
from dbo.Operation_log ol
where  exists(select 1 
              from dbo.change_log cl
              where cl."ID_Operation_log" = ol."ID_Operation_log"
                   and cl."ID_Owner_Object"  = 32
                   and cl."ID"  = 4445327
              limit 1
                );
```
![image](https://github.com/user-attachments/assets/763c9519-0f85-457c-82d0-dae84844b36e)

**Результат: 0.625 сек до создания индекса. Т.к. таблица dbo.Сhange_log не очень большая по сравнению с другими, то и без индексов работает достаточно быстро.**

Создаем индекс и пробуем выполнить запрос снова. В индекс включаем поле "ID_Operation_log", чтобы он был покрывающим для запроса. 
```bash
   create index "IX_Change_log(ID,ID_Owner_Object)" on dbo.change_log("ID","ID_Owner_Object") 
   include ("ID_Operation_log");
```
И выполняем запрос снова.
![image](https://github.com/user-attachments/assets/84426da1-764e-4dd2-86e2-ab60832b2078)
**Результат: 0.115 милисек с индексом. Практически моментально. Ну и не стоит забывать про запрос самой выборки данных на основе полученных идентификаторов id.**

Использованные материалы:

https://dba.stackexchange.com/questions/129413/full-text-search-in-xml-documents?newreg=f509224b72f3470a865ed18db92f2c4b

https://habr.com/ru/articles/442170/

https://stackoverflow.com/questions/30470151/postgresql-how-to-go-around-ts-vector-size-limitations

https://pganalyze.com/blog/5mins-postgres-forcing-join-order

https://eax.me/postgresql-full-text-search/

https://stackoverflow.com/questions/1566717/postgresql-like-query-performance-variations

https://habr.com/ru/companies/postgrespro/articles/340978/

https://sky.pro/wiki/sql/optimizatsiya-poiska-skhozhikh-strok-v-postgre-sql-pg-trgm/


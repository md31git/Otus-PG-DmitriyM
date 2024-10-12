## 1 Исхоные данные
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
* Тип опрерации (список значений через запятую) (Operation_log.ID_Operation_Type)
* Поиск по тексту входящего запроса (Exchange_log.Input_xml) 
#### Поиск 4. 
* Вид объекта (Сhange_log.ID_Owner_Object)
* Идентификатор объекта  (Сhange_log.Id)
#### Поиск 5. 
* Дата операции в диапазоне дат (Operation_log.Operation_Date). 90% запросов за последние 2 месяца, остальные 10% за другие периоды.
* Пользователь, совершивший операцию (Employee.ID_Employee) 

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
План запроса без каких-либо индексов и актуальной статистики выглядит "ужасно". Почти все соединения таблиц производиться через Hash join. Палнировщик попытался распаралеллить запросы, чтобы хоть как-то уменьшить время выполнения, но все равно это очень долго. 

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

### 2 Поиск 2 На guid
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

Самая долгая операци это Seq Scan - полное сканирование таблицы, т.к. индекса на поле Operation_Guid нет. 
```bash
  create index "IX_Operation_log(Operation_Guid)" on dbo.Operation_log("Operation_Guid"); 
```
После создания индекса запрос выполняется на порядки быстрее
![image](https://github.com/user-attachments/assets/ef964ce6-fe59-4310-9c9e-c5e74c390047)





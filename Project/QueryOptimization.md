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

Вывод исходя из плана запроса:
1. Не хватает индекса на поле  dbo.Operation_log."ID_Operation_log"
2. Не хватает индекса на поле  dbo.Exchange_log."ID_Operation_log"

Вывод исходя из поддержания целлостности базы: 
1. Необходимо на каждую таблицу создать первичный ключ, чтобы можно было однозначно идентифицировать каждую запись.





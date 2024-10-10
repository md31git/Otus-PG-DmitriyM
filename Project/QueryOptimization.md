## 1 Исхлные данные
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
#### б) Operation_log.Operation_Date - между датами с и по
   Operation_log.ID_Operation_Type - тип операции
   exchange_log.Input_xml поиск по произвольному тексту.
3. change_log.ID_Owner_Object - вид объекта
   change_log.ID - id объекта
4. Operation_log.Operation_Date - между датами с и по
   Employee.ID_Employee - Пользователь, совершивший операцию



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
where ol."ID_Operation_log" =1000
order by ol."Operation_Date" desc;
```
![image](https://github.com/user-attachments/assets/ff3e6608-9af0-4ae3-9073-6d97ba9cd0cb)

Создаем индекс





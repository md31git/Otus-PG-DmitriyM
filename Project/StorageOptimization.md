## 1 Получаем размеры таблиц 
![image](https://github.com/user-attachments/assets/024dc2ac-6cd2-4c7b-8204-7e5d6c64d0ae)

## 2 Определяем план изменения и меняет типы полей таблицы
## 3 Оптимизируем toast данные





---------------------------------------

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








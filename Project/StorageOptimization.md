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
Тут смысловых полей всего два Input_xml, Output_xml. В них храняться входные и выходные запросы в формате xml, но тип данных text.
![image](https://github.com/user-attachments/assets/b72ace71-6a65-41ff-860e-3712024ecf1b)

По идее надо изменить тип данных на xml, но этого делать не будем, т.к. по этим полям необходим поиск строки в строке и для полнотекстого поиска нужно все равно преобразовывать в тип text, а индексов на тип xml в PostgreSQL нет.
**Итого: ничего не меняем **
### 2.2 dbo.change_log
1.Для полей справочников "ID_Owner_Object" и "ID_Change_Type" имеет смысл уменьшить размерность с Int до SmallInt. Это сократит в два раза занимаемый объем данных этим послем с 8 байт до 4 байт
2.В PostgreSQL есть понятие "выравнивание" столбцов фиксированной длины до 8 байт. Поэтому необходимо придерживаться следующего правила положени столбцов в таблице:

**Сначала идут широкие столбцы, затем средние, маленькие столбцы в последнюю очередь, а столбцы переменного размера, такие как NUMERIC и TEXT, в самом конце**

Подробнее можно изнакомиться тут: https://habr.com/ru/articles/756074/

![image](https://github.com/user-attachments/assets/cba17ae6-d514-437a-bb32-01baa2326ef2)



### 2.3 dbo.operation_log
```Bash
alter table dbo.operation_log 
     alter column "Status" type Boolean using "Status"::Int::boolean,
     alter column "Operation_Guid" type UUID using "Operation_Guid"::UUID;
```


## 3 Оптимизируем toast данные
```bash
ALTER TABLE dbo.exchange_log 
      ALTER COLUMN "Input_xml" SET STORAGE MAIN,
      ALTER COLUMN "Output_xml" SET STORAGE MAIN;
```








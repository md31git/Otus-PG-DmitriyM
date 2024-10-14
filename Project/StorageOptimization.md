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
![image](https://github.com/user-attachments/assets/fa70789a-2e1d-4f74-9b1e-7f372b4ef77e)

По идее надо изменить тип данных на xml, но этого делать не будем, т.к. по этим полям необходим поиск строки в строке и для полнотекстого поиска нужно все равно преобразовывать в тип text, а индексов на тип xml в PostgreSQL нет.
### 2.2 dbo.change_log

### 2.3 dbo.operation_log


## 3 Оптимизируем toast данные









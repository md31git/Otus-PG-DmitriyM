## 1.Создание двух таблиц для теста
Создаме таблицу платежей test.pay и таблицу детализаций платежей с суммами test.pay_detail
```bash
create table if not exists test.Pay as
SELECT
  s as "id",
  format('pay%s', (round((random() * 10000)::numeric,0))::text) as "name",
  (array['ok', 'error', 'process'])[floor(random() * 3 + 1)] as "status",
   md5(random()::text) as "external_code"
FROM
  generate_series(1, 10000) s;
  
 create table if not exists test.Pay_Detail as
 SELECT
  row_number() over (order by P.id) as "Id",
  P.id as "pay_id",
  round((random() * 10)::numeric,0) as "service_id",
  round((random() * 1000)::numeric,2) as "summ"
FROM test.Pay P
CROSS JOIN generate_series(1, P.id % 5) s;
```
![image](https://github.com/user-attachments/assets/ae6c0c48-f60e-4db9-b3d9-f3525bf96a78)


## 2.Создать индекс к какой-либо из таблиц вашей БД
## 2.Прислать текстом результат команды explain, в которой используется данный индекс
## 3.Реализовать индекс для полнотекстового поиска
## 4.Реализовать индекс на часть таблицы или индекс на поле с функцией
## 5.Создать индекс на несколько полей
## 6.Написать комментарии к каждому из индексов
## 7.Описать что и как делали и с какими проблемами столкнулись

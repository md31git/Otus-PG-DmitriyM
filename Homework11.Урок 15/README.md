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

## 2.Создать индекс к какой-либо из таблиц вашей БД и Прислать текстом результат команды explain, в которой используется данный индекс
Выборка без индекса занимает 1 мс. Используется оператор Filter, который обозначет фильтрацию даннных без индекса
```bash
EXPLAIN ANALYZE 
select P.id, p.name 
from test.Pay P
where id>100 and id<200;
```
![image](https://github.com/user-attachments/assets/1545faab-6e99-4d9d-ba2c-22625b502bbd)

Если создадим индекс на поле id, то скорость выполнения увеличилась более чем 10 раз и уже используется оператор Index Cond, указывающий что условие отрабатывает уже по индексу.
```bash
create index ix_pay_id on test.pay(id);
EXPLAIN ANALYZE 
select P.id, p.name 
from test.Pay P
where id>100 and id<200;
```
![image](https://github.com/user-attachments/assets/9fd37a01-f5b1-451c-ad11-f1fc9f5906e3)

## 3.Реализовать индекс для полнотекстового поиска
Для полнотекстого поиска будем использовать индекс GIN и для этого создадим еще одно поле в таблице. Оно будет вычисляемое от функции to_tsvector и данных из поля txt. Оно нужно чтобы не вычислять на лету и был существенный выигрыш в скорости поиска.
```bash
alter table test.Pay add column txt_ts tsvector GENERATED ALWAYS as (to_tsvector('english',txt)) stored;

EXPLAIN ANALYZE 
select P.id, p.name
from test.Pay P
where txt_ts @@ to_tsquery('ocean');
```
![image](https://github.com/user-attachments/assets/f4fbf13e-1ca9-4173-85cc-469f95b255cc)

Время работы без индекса 16 мс. Без индекса требуется полное сканирование таблицы Seq scan

```bash
create index ix_pay_txt_ts on test.pay using GIN (txt_ts);

EXPLAIN ANALYZE 
select P.id, p.name
from test.Pay P
where txt_ts @@ to_tsquery('ocean');
```
![image](https://github.com/user-attachments/assets/de8a1a8f-2645-451a-9dc9-297570810b11)

Время работы без индекса 1 мс. Что в 16 раз быстрее. 

## 4.Реализовать индекс на часть таблицы или индекс на поле с функцией
Чтобы индекс занимал меньше места и по нему был быстрее поиск определенных запросов, то используется частичный индекс с выражением where
```bash
EXPLAIN ANALYZE 
select P.id, p.name 
from test.Pay P
where status = 'ok';
```
![image](https://github.com/user-attachments/assets/90674bbb-f359-4d65-a95a-a00c5586702c)

Тут опять используется оператор filter и сканирование таблицы.
```bash
create index ix_pay_status on test.pay(id) include (name) where status='ok';

EXPLAIN ANALYZE 
select P.id, p.name 
from test.Pay P
where status = 'ok';
```
![image](https://github.com/user-attachments/assets/b71c2f8a-8b4d-4732-adfc-1343300e4770)

Был создан индекс, который полносью содержаит все поля для выборки, а также он создан на часть таблицы. И поэтому здесь используется Index only scan, т.е. PG обращается только к индексу без обращения к даным таблице, т.е. у нас "покрывающий" индекс.

## 5.Создать индекс на несколько полей
```bash
create index ix_pay_status on test.pay(id) include (name) where status='ok';

EXPLAIN ANALYZE 
select P.id, p.name 
from test.Pay P
where status = 'ok';
```


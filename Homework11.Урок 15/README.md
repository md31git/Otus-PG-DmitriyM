## 1.Создание двух таблиц для теста
Создаем таблицу платежей test.pay.
```bash
create table if not exists test.Pay as
SELECT
  s as "id",
  format('pay%s', (round((random() * 10000)::numeric,0))::text) as "name",
  (array['ok', 'error', 'process'])[floor(random() * 3 + 1)] as "status",
   md5(random()::text) as "external_code",
   concat_ws(' ', (array['green', 'red', 'black', 'white', 'grey', 'blue'])[(random() * 6)::int],
                  (array['like', 'go', 'swim', 'drive', 'get', 'quess'])[(random() * 6)::int],
                  (array['home', 'field', 'mountain', 'rock', 'ocean', 'garden'])[(random() * 6)::int]) as "txt"
FROM
  generate_series(1, 10000) s;
```
![image](https://github.com/user-attachments/assets/ab7b2ad1-dd09-4ea3-aeea-e813fa44ce71)


## 2.Создать индекс к какой-либо из таблиц вашей БД и Прислать текстом результат команды explain, в которой используется данный индекс
Выборка без индекса занимает 1 мс. Используется оператор Filter, который обозначает фильтрацию данных без индекса
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
Для полнотекстового поиска будем использовать индекс GIN и для этого создадим еще одно поле в таблице. Оно будет вычисляемое от функции to_tsvector и данных из поля txt. Оно нужно чтобы не вычислять на лету и был существенный выигрыш в скорости поиска.
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

Был создан индекс, который полностью содержит все поля для выборки, а также он создан на часть таблицы. И поэтому здесь используется Index only scan, т.е. PG обращается только к индексу без обращения к данным таблице, т.е. у нас "покрывающий" индекс.

## 5.Создать индекс на несколько полей
```bash
EXPLAIN ANALYZE
select P.id, p.name
from test.Pay P
where name='pay1167' and status = 'error';
```
![image](https://github.com/user-attachments/assets/f32c841f-fdf2-46f3-b43a-da0bc6babee3)

Как видим из плана выполнения PG удалил из выборки 99999 не совпадающих значений и при этом сканировал таблицу полностью.

```bash
create index ix_pay_name on test.pay(name, status);

EXPLAIN ANALYZE
select P.id, p.name
from test.Pay P
where name='pay1167' and status = 'error';
```
![image](https://github.com/user-attachments/assets/7cd5ed71-35d8-4e5f-b516-d18622ae6edc)

Теперь используется составной индекс по двум полям. Причем первым по порядку полем было выбрано именно name, т.к. оно имеет лучшую селективность, что повышает эффективность индекса. 

Запросы, где будет только фильтрация по полю name тоже будет использоваться индекс. Но план уже будет другой.
```bash
EXPLAIN ANALYZE
select P.id, p.name
from test.Pay P
where name='pay1167';
```
![image](https://github.com/user-attachments/assets/951b547d-c868-4320-933f-8fb71fb3e7bd)

В то же время если будет фильтрация только по полю status, то индекс использоваться не будет, т.к. в составном индексе главное последовательность полей в индексе. 
```bash
EXPLAIN ANALYZE
select P.id, p.name
from test.Pay P
where status = 'error';
```
![image](https://github.com/user-attachments/assets/d77131a7-8377-4c84-a5f4-181c83b6fb31)


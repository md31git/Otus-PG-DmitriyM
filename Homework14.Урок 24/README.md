## 1 Исходные данные
### 1.1 подключаемся к базе, создаем схему и делаем ее по умолчанию
```bash
DROP SCHEMA IF EXISTS pract_functions CASCADE;
CREATE SCHEMA pract_functions;
SET search_path = pract_functions, public;
```
![image](https://github.com/user-attachments/assets/9563097f-7caa-4e8a-bd16-e72216abed47)

### 1.2 Создаем таблицы и заполняем их данными
```bash
-- товары:
CREATE TABLE goods
(
    goods_id    integer PRIMARY KEY,
    good_name   varchar(63) NOT NULL,
    good_price  numeric(12, 2) NOT NULL CHECK (good_price > 0.0)
);
INSERT INTO goods (goods_id, good_name, good_price)
VALUES 	(1, 'Спички хозайственные', .50),
		(2, 'Автомобиль Ferrari FXX K', 185000000.01);

-- Продажи
CREATE TABLE sales
(
    sales_id    integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    good_id     integer REFERENCES goods (goods_id),
    sales_time  timestamp with time zone DEFAULT now(),
    sales_qty   integer CHECK (sales_qty > 0)
);

INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
```
### 1.3 Отчет
```bash
-- отчет:
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```
![image](https://github.com/user-attachments/assets/10f6a6ad-e304-46d3-b997-abd2a7f56298)

### 1.4 С увеличением объёма данных отчет стал создаваться медленно. Принято решение денормализовать БД, создать таблицу
```bash
CREATE TABLE good_sum_mart
(
	good_name   varchar(63)  NOT NULL,
	sum_sale	numeric(16, 2) NOT NULL
);
```
## 2.Задача: Создать триггер (на таблице sales) для поддержки.
Рассуждение:
1. Триггер на каждую отельную строку делать не будем, т.к. нам при любом обновлении кол-ва строк таблицы sales нужно один раз обновить таблицу-отчет.
2. Полное удаление таблицы и перестроение заново тоже делать не будем, т.к. это по сути перестроение всего отчета при каждом обновлении, а исходя из задачи сам отчет тормозит.
3. Будем обновлять только строки в таблице good_sum_mart только по тем товарам, у которых изменились продажи. Это будет быстрее чем пункты 1 и 2.

### 2.1 Создаем три отдельные триггерные функции для каждой операции INSERT, UPDATE, DELETE.
Делаем отдельные функции для уменьшения кода и использования REFERENCING (хотелось проверить работу).

Функция на вставку
```bash
CREATE OR REPLACE FUNCTION good_sum_mart_insert() 
RETURNS TRIGGER AS $$
BEGIN   
   
    insert into good_sum_mart (good_name, sum_sale)
    select  G.good_name, SUM(G.good_price * S.sales_qty)
    from goods G
    inner join sales S ON S.good_id = G.goods_id
    where exists(select 1 from Inserted N where N.good_id = G.goods_id)
    group by G.good_name
    on conflict (good_name)
    do update set 
        sum_sale = excluded.sum_sale; 
    
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;
```

Функция на изменение
```bash
CREATE OR REPLACE FUNCTION good_sum_mart_update() 
RETURNS TRIGGER AS $$
BEGIN   
   
    insert into good_sum_mart (good_name, sum_sale)
    select G.good_name, SUM(G.good_price * S.sales_qty)
    from goods G
    inner join sales S ON S.good_id = G.goods_id
    where exists
          (select 1 
           from Inserted N 
           where N.good_id = G.goods_id
           union all  -- на случай если good_id измениться
           select 1 
           from Deleted N 
           where N.good_id = G.goods_id
           )
    group by G.good_name
    on conflict (good_name)
    do update set 
        sum_sale = excluded.sum_sale;
    
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;
```

Функция на удаление
```bash
CREATE OR REPLACE FUNCTION good_sum_mart_delete() 
RETURNS TRIGGER AS $$
BEGIN   
   
    insert into good_sum_mart (good_name, sum_sale)
    select  G.good_name, SUM(G.good_price * S.sales_qty)
    from goods G
    inner join sales S ON S.good_id = G.goods_id
    where exists(select 1 from Deleted N where N.good_id = G.goods_id)
    group by G.good_name
    on conflict (good_name)
    do update set 
        sum_sale = excluded.sum_sale; 
       
    delete from good_sum_mart GS
    using 
    (
         select G.good_name
         from goods G
         left join sales S ON S.good_id = G.goods_id
         where exists(select 1 from Deleted N where N.good_id = G.goods_id)
               and not exists(select 1 from Deleted N where N.good_id = S.good_id)
         group by G.good_name   
    ) V 
    where V.good_name = GS.good_name; 
    
    RETURN NULL; 
END;
$$ LANGUAGE plpgsql;
```

### 2.2 Создаем три отдельных триггера AFTER на INSERT, UPDATE, DELETE.
Делаем AFTER, т.к. по сути изменение данных первично, а обновление таблицы-отчета вторично. И для триггера UPDATE нужно, чтобы в триггерной таблице NEW были уже именные значения
```bash
create trigger sales_I_trigger
after insert
on sales
REFERENCING NEW TABLE AS inserted
for each statement 
execute function good_sum_mart_insert();

create trigger sales_U_trigger
after update
on sales
REFERENCING NEW TABLE AS inserted OLD TABLE AS deleted
for each statement 
execute function good_sum_mart_update();

create trigger sales_D_trigger
after delete
on sales
REFERENCING OLD TABLE AS deleted
for each statement 
execute function good_sum_mart_delete();
```
### 2.3 Создаем уникальный индекс на таблицу good_sum_mart
Причины:
1. Т.к. в триггерных функциях используем конструкцию ON CONFLICT и он требует уникальности 
2. Триггерной функции на удаление есть условие where V.good_name = GS.good_name - для ускорения выполнения.
```bash
create unique index  "IQ_good_sum_mart(good_name)" on good_sum_mart (good_name);
```

## 3 Проверка работы
### 3.1 Подготовка
Удаляем все записи из таблицы sales и проверяем что в таблице good_sum_mart пусто.
```bash
delete from sales;
select * from good_sum_mart;
```
![image](https://github.com/user-attachments/assets/08048965-fa0c-458d-9af8-ca2d89d4d59b)

### 3.2 Добавление
Выполняем вставку согласно исходным данным и сравниваем таблицу good_sum_mart и результат запрос отчета
```bash
INSERT INTO sales (good_id, sales_qty) VALUES (1, 10), (1, 1), (1, 120), (2, 1);
---
select * from good_sum_mart;
---
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```
![image](https://github.com/user-attachments/assets/5cb2b74b-b6bb-4cc3-880a-e14a6f635c19)

Результат одинаковый - значит триггер на изменение работает корректно
### 3.3 Изменение
**Изменение кол-ва**
```bash
update sales
set sales_qty=3
where good_id = 1 and sales_qty = 10;
---
select * from good_sum_mart;
---
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```
![image](https://github.com/user-attachments/assets/363c5d4e-05cc-4976-a260-cb61c3111ab4)

Результат одинаковый - значит триггер на изменение работает корректно

**Изменение товара**
```bash
update sales
set sales_qty=3
where good_id = 1 and sales_qty = 10;
---
select * from good_sum_mart;
---
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```
![image](https://github.com/user-attachments/assets/76ea4b4c-19c0-4504-9583-85bb9159a70e)

Результат одинаковый - значит тригрер на измененение работет корректно
### 3.4 Удаление 
Удаление всех продаж одного товара 
```bash
delete from sales where good_id = 2;
---
select * from good_sum_mart;
---
SELECT G.good_name, sum(G.good_price * S.sales_qty)
FROM goods G
INNER JOIN sales S ON S.good_id = G.goods_id
GROUP BY G.good_name;
```
![image](https://github.com/user-attachments/assets/f077f4c2-650b-44ff-8cd9-b0d6dd92e7f1)

Результат одинаковый - значит триггер на удаление работает корректно.

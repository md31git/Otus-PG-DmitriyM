## 1.Исходные данные - структура таблиц и связей
Взята база данных полетов (big версия) 
```Bash
sudo wget https://edu.postgrespro.ru/demo_big.zip && sudo apt install unzip && unzip demo_big.zip && sudo -u postgres psql -d postgres -p 5432 -f /home/mihi/demo_big.sql -c 'alter database demo set search_path to bookings'
```

Структура базы данных:
![image](https://github.com/user-attachments/assets/267c27de-8adf-4e77-bfe2-c505ffa96205)

## 2.Реализовать прямое соединение двух или более таблиц
Выбираем все бронирования и включенные в это бронирования билеты. 
```Bash
explain ANALYZE 
select b.book_date, t.ticket_no, t.passenger_name
from bookings.bookings b
inner join bookings.tickets t on t.book_ref= b.book_ref;
```
![image](https://github.com/user-attachments/assets/c418a972-5675-4edb-b846-4c5af52f1138)

Описание: используется соединение двух таблиц через хеш таблицу. И полное сканирование таблиц заказв и билетов. 

## 3.Реализовать левостороннее (или правостороннее)соединение двух или более таблиц
Выбираем 100 рейсов те, которые не состоялись (нет ниодного билета на рейс)
```Bash
explain ANALYZE 
select distinct F.flight_no, F.departure_airport, F.arrival_airport
from (select * from bookings.flights limit 100) F
left join bookings.ticket_flights tf on tf.flight_id = F.flight_id
where tf.flight_id is null;
```
![image](https://github.com/user-attachments/assets/775dc919-fbd8-4317-a9a3-32047bda4e87)

Описание: Т.к. мы не указали в select поля из ticket_flights, то испольузется сканирование только индекса и паралельно выбирается 100 записей из flights. Т.к. записей немного, то использется вложенные цикл. Ну и в конце идет сортировка из-за использования distinct.

## 4.Реализовать кросс соединение двух или более таблиц
Просто декартовое произведение двух справочников.
```Bash
explain ANALYZE 
select *
from bookings.aircrafts r
cross join bookings.airports t;
```
![image](https://github.com/user-attachments/assets/ff9e53ab-7b98-4c63-9ad3-c3969eaf6b0f)

Описание: планироващик здесь использует вложенный цикл, т.к. таблицы небольшие. А также Materialize (сохранение в памяти, чтобы не обращаться каждый раз к таблице) по таблицы aircrafts для ускорения выполенния запроса.  

## 5.Реализовать полное соединение двух или более таблиц
Выборка купленных билетов на рейс и зарегистрированнх на рейс. Специльно сделана выборка так, чтобы были и спарва и слева записи, которые не соединились.
```Bash
explain ANALYZE 
select tf.Fare_conditions, bp.boarding_no
from (select * from bookings.ticket_flights where flight_id between 2 and 7) tf
full join (select * from bookings.boarding_passes  where flight_id between 3 and 8) bp on bp.flight_id = tf.flight_id and bp.ticket_no = tf.ticket_no;
```
![image](https://github.com/user-attachments/assets/91451d6e-9a9e-44e2-8b6d-c5853804891a)

Описание: Здест используется сканирование двух таблиц. Причем готовит два запроса для full join паралельно друг другу и использует в итое Full hash join.

## 6.Реализовать запрос, в котором будут использованы разные типы соединений
Определяем количество незарегистрированных пасажиро-мест из города Анадырь с группировой по аэропорту прибытия
```bash
explain ANALYZE 
select  
      f.arrival_airport as "аэропорт прибытия",
      count(*) as "кол-во мест"
FROM bookings.ticket_flights tf
inner join bookings.flights f ON tf.flight_id = f.flight_id
inner join airports dep on dep.airport_code = f.departure_airport
left join bookings.boarding_passes bp ON tf.flight_id = bp.flight_id and tf.ticket_no = bp.ticket_no
where bp.flight_id is null and dep.city = 'Анадырь'
group by f.arrival_airport;
```
![image](https://github.com/user-attachments/assets/fd03786b-d30f-49e6-a010-679b70219b33)

Описание: тут использовается паралелльное агрегация по пачкам. 


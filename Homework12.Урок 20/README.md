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
## 5.Реализовать полное соединение двух или более таблиц
## 6.Реализовать запрос, в котором будут использованы разные типы соединений
## 7.Сделать комментарии на каждый запрос


## Секционировать большую таблицу из демо базы flights.
### Взята база данных полетов (big версия) 
```Bash
sudo wget https://edu.postgrespro.ru/demo_big.zip && sudo apt install unzip && unzip demo_big.zip && sudo -u postgres psql -d postgres -p 5432 -f /home/mihi/demo_big.sql -c 'alter database demo set search_path to bookings'
```
### Выбираем наибольшую таблицу по размеру:
```Bash
SELECT schemaname, C.relname AS "tabe"
FROM pg_class C
LEFT JOIN pg_namespace N ON (N.oid = C .relnamespace)
LEFT JOIN pg_stat_user_tables A ON C.relname = A.relname
WHERE nspname NOT IN ('pg_catalog', 'information_schema')
AND C.relkind <> 'i'
AND nspname !~ '^pg_toast'
ORDER BY pg_total_relation_size (C.oid) desc
limit 1;
```
Эта таблица bookings.boarding_passes. 

### Создаем копию данной таблицы bookings.boarding_passes_part и создаем 4 таблицы секций по хешу, т.к. тут по списку или диапазону создавать не имеет смысла.
```Bash
create table bookings.boarding_passes_part (
	ticket_no bpchar(13) NOT NULL,
	flight_id int4 NOT NULL,
	boarding_no int4 NOT NULL,
	seat_no varchar(4) NOT NULL,
	CONSTRAINT boarding_passes_part_pkey PRIMARY KEY (ticket_no, flight_id),
	CONSTRAINT boarding_passes_part_ticket_no_fkey FOREIGN KEY (ticket_no,flight_id) REFERENCES bookings.ticket_flights(ticket_no,flight_id)
) partition by hash (ticket_no, flight_id);

do $$
begin
	for i in 0 .. 3
	loop
		execute format('create table bookings.boarding_passes_part_%s partition of bookings.boarding_passes_part for values with (modulus 4, remainder %s);', i, i);
	end loop;
end
$$ 
language plpgsql;
```
![image](https://github.com/user-attachments/assets/2babb13f-7a74-4126-9d7e-c424e5fa898b)

### Проверяем что все верно создали: 1 родительскую таблицу и 4 секции в ней
```Bash
select *
from pg_partitioned_table;

select relname, relkind, relpartbound
from pg_class
where relname like '%boarding_passes_part%'
order by relkind, relname;
```
![image](https://github.com/user-attachments/assets/e12f5ced-08d1-4693-a194-f39a4e9bc68e)

### Заполняем данными из исходной таблицы. Берем только 10000 записей для примера, чтобы не ждать слишком долго. 
```Bash
insert into bookings.boarding_passes_part 
select *
from bookings.boarding_passes
limit 10000;
```
![image](https://github.com/user-attachments/assets/e70cab4e-459b-4435-ba7c-99a9c7bab867)

### Проверим размерность и кол-во записей в секциях и в родительской таблице
```Bash
select pg_size_pretty(pg_table_size('boarding_passes_part')) as main, 
       pg_size_pretty(pg_table_size('boarding_passes_part_0')) as part0,
       pg_size_pretty(pg_table_size('boarding_passes_part_1')) as part1,
       pg_size_pretty(pg_table_size('boarding_passes_part_2')) as part2,
       pg_size_pretty(pg_table_size('boarding_passes_part_3')) as part3;
  
SELECT schemaname,relname,n_live_tup
FROM pg_stat_user_tables
where relname like 'boarding_passes_part%'
ORDER BY n_live_tup DESC;     
```
![image](https://github.com/user-attachments/assets/b719b7b8-cced-48f8-9ac8-5cf72dc8f120)


**Т.к. мы использовали секционирование по хешу и ключ у хеша выбрали равным первичному ключу, то размер и кол-во записей в секции должны быть примерно одинаковыми у всех четырех секций. А в родительской таблице 0 записей, т.к. она служит только для шаблона структуры данных**

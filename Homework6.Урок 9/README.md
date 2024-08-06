## 1.Настройте выполнение контрольной точки раз в 30 секунд.
Заходим в PG и устанавливаем значение параметра checkpoint_timeout = 30 секунд. Контрольная точка будет происходить раз в 30 секунд. 
```bash
sudo -u postgres psql -d postgres -p 5433
Show checkpoint_timeout;
alter system set checkpoint_timeout = 30;
SELECT pg_reload_conf();
Show checkpoint_timeout;
```
А также получаем последний LSN (идентификатор записи) в журнале WAL. Он нужен чтобы сравнить его с LSN полученным после нагрузки.
```bash
select pg_current_wal_insert_lsn(), pg_current_wal_lsn();
```
![image](https://github.com/user-attachments/assets/5faf8c0f-dc31-4ad5-bc53-16093e7cf040)

Запомним полученный LSN: 0/23A1360

А также просматриваем и сбрасываем накопленную статистику по созданию контрольных точек.
```bash
SELECT * FROM pg_stat_bgwriter \gx
SELECT pg_stat_reset_shared('bgwriter');
SELECT * FROM pg_stat_bgwriter \gx
```
![image](https://github.com/user-attachments/assets/ada2d4d9-2d71-4683-b155-7027006677cf)

## 2.10 минут c помощью утилиты pgbench подавайте нагрузку.
Переключаемся на пользователя postgres, инициируем pgbench и запускаем нагрузку в 4 потока на 10 мин с 10 соединениями.

Все это мы запускали в синхронном режиме записи WAL (synchronous_commit = on)
```bash
sudo su postgres
pgbench -i -p 5433 postgres
pgbench -c 10 -j 4 -P 60 -T 600 postgres
```
![image](https://github.com/user-attachments/assets/0f76b7a3-69a1-4a38-a914-ee6c85506956)

**Итоговый tps = 30.245466**

## 3.Измерьте, какой объем журнальных файлов был сгенерирован за это время. Оцените, какой объем приходится в среднем на одну контрольную точку.
Получаем текущую LSN
```bash
select pg_current_wal_insert_lsn(), pg_current_wal_lsn();
```
![image](https://github.com/user-attachments/assets/86b6fddd-413a-4147-92e0-8c123e0496bc)

Объем журнала получаем как разница между двумя LSN (текущей и до нагрузки) в Мб.
```bash
select ('0/3030ED0'::pg_lsn - '0/23A1360'::pg_lsn)/1024/1024;
```
![image](https://github.com/user-attachments/assets/1fff55d7-7863-4a69-9f44-27bf3a7d322c)

**Итого объем журнала WAL при подачи нагрузки pgbench 10 мин составил примерно 12.5МБ**

## 4.Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?
Сразу после окончания нагрузки было выполнено получение статистики по контрольным точкам. Иначе контрольные точки будут создаваться каждые 30сек исходя из настройки, установленной выше.
```bash
SELECT * FROM pg_stat_bgwriter \gx
```
![image](https://github.com/user-attachments/assets/353d79ed-d435-4860-86f7-7b549f2539ec)

Итоги:
* Всего было выполнено checkpoints_timed = 34 контрольные точки по расписанию. 
* Внеплановых (выполненных по превышению объема max_wal_size) контрольный точек не было checkpoints_req = 0. Т.к. max_wal_size= 1Гб, а на контрольную точку приходилось по 12.5МБ/34 = 0.36Мб. 

## 5.Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.
Включаем ассинхронный режим synchronous_commit = off, т.к. в синхронном режиме записи WAL мы уже прогоняли нагрузку. 
```bash
show synchronous_commit;
alter system set synchronous_commit = off;
SELECT pg_reload_conf();
show synchronous_commit;
```
![image](https://github.com/user-attachments/assets/57c77bc2-d870-4131-b40b-4008141be1fc)

Повторяем нагрузку:
```bash
pgbench -c 10 -j 4 -P 60 -T 600 postgres
```
![image](https://github.com/user-attachments/assets/082463d6-3d19-4b68-a7b1-4698196ebe8c)

**Итоговый tps = 35.180802**. Скорость возросла боьеш чем на 15%.

## 6.Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений. Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?
### Создайте новый кластер с включенной контрольной суммой страниц
```bash
sudo pg_createcluster -d /var/lib/postgresql/14/main5 14 main5 -- --data-checksums
sudo pg_ctlcluster 14 main5 start
```
![image](https://github.com/user-attachments/assets/defc4e5c-090b-49d9-80cd-7eb2e11ba591)

### Создайте таблицу. Вставьте несколько значений.
Подключаемся к новому кластеру, создаем БД, схему и в ней таблицу для теста
```bash
pg_lsclusters
sudo -u postgres psql -d postgres -p 5436
CREATE Database db;
CREATE schema test;
CREATE TABLE test.test as select generate_series as id, substr(md5(random()::text), 1, 25)::varchar(100) as name from generate_series(1,5,1);
select * from test.test;
```
![image](https://github.com/user-attachments/assets/1af66786-da90-4b00-b52d-6cdf6b5d4af6)

### Выключите кластер. Измените пару байт в таблице.
Определяем путь к файлу, где лежит таблица:
```bash
SELECT pg_relation_filepath('test.test'); 
```
![image](https://github.com/user-attachments/assets/164338a9-1f2e-4522-b2aa-d589a3a6cbe3)


Останавливаем кластер, заходим под postgres и редактируем файл таблицы (удаляем пару символов из файла). 
```bash
sudo pg_ctlcluster 14 main5 stop
sudo su postgres
nano /var/lib/postgresql/14/main5/base/16384/24590
exit
```
![image](https://github.com/user-attachments/assets/c66ebfc4-7938-43f4-b208-91f83a2aa362)

**Внимание. Если удалим символы в начале файла, то скорее всего повредим заголовок и таблица станет пустой. Поэтому меняем символы ближе к концу файла.
А также необходими именно добавить новые символы. Если произвести удаление, то таблица в итоге будет пустой при открытии**

### Включите кластер и сделайте выборку из таблицы.
```bash
sudo pg_ctlcluster 14 main5 start
sudo -u postgres psql -d db -p 5436
select * from test.test;
```
![image](https://github.com/user-attachments/assets/13175204-d4ac-48e1-b101-100f8d71f380)

Возникла ошибка что нарушена контрольная сумма таблицы. 

### Что и почему произошло? как проигнорировать ошибку и продолжить работу?
Чтобы игнорировать ошибку необходимо включить значение ignore_checksum_failure = on
```bash
alter system set ignore_checksum_failure = on;
SELECT pg_reload_conf();
show ignore_checksum_failure;
select * from test.test;
```
![image](https://github.com/user-attachments/assets/23c5fae6-ce9d-441a-8bbe-3edc2f5ecda3)

В итоге была испорчена первая строка таблицы и она исчезла (вместо 5 строк стало 4), а также именились данные во 2-ой строке (в файл мы их и меняли), но данные вывелись с предупреждением выше о нарушении контрольной суммы. 

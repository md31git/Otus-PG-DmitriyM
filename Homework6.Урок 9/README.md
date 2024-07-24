## 1.Настройте выполнение контрольной точки раз в 30 секунд.
Заходим в PG и устанавиваем значение параметра checkpoint_timeout = 30 секунд. Контрольная точка будет происходить раз в 30 секунд. 
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

А также просмативаем и сбрасываем накопленную статистику по созданию котрольных точек.
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

Объем журнала получаем как разница между двумя LSN (текузей и до нагрузки) в Мб.
```bash
select ('0/3030ED0'::pg_lsn - '0/23A1360'::pg_lsn)/1024/1024;
```
![image](https://github.com/user-attachments/assets/1fff55d7-7863-4a69-9f44-27bf3a7d322c)

**Итого объем журнала WAL при подачи нагрузки pgbench 10 мин составил примерно 12.5МБ**

## 4.Проверьте данные статистики: все ли контрольные точки выполнялись точно по расписанию. Почему так произошло?
Сразу после окончания нагрузки было выполнено получение статистики по контрольным точкам. Иначе котрольные точки будут создаваться каждые 30сек исходя из настройки, установленной выше.
```bash
SELECT * FROM pg_stat_bgwriter \gx
```
![image](https://github.com/user-attachments/assets/353d79ed-d435-4860-86f7-7b549f2539ec)

Итоги:
* Всего было выполнено checkpoints_timed = 34 котрольные точки по расписанию. 
* Внеплановых (выполенных по превышению объема max_wal_size) контрольный точек не было checkpoints_req = 0. Т.к. max_wal_size= 1Гб, а на котрольную точку приходилось по 12.5МБ/34 = 0.36Мб. 

## 5.Сравните tps в синхронном/асинхронном режиме утилитой pgbench. Объясните полученный результат.



## 6.Создайте новый кластер с включенной контрольной суммой страниц. Создайте таблицу. Вставьте несколько значений. Выключите кластер. Измените пару байт в таблице. Включите кластер и сделайте выборку из таблицы. Что и почему произошло? как проигнорировать ошибку и продолжить работу?

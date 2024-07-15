## 1.Развернута ВМ со следующими данными через WSL
### Исходные данные:
* Виртуальная машина =  WSL (Ubuntu 22.04.1)
* PostgreSQL =  14.12
* Процессор = 8 ядер
* ОЗУ = 8Гб
* Диск = HDD

## 2.Создать БД для тестов: выполнить pgbench -i postgres
Для использования утилиты необходимо ее инициализировать: создаются набор таблиц для использования в нагрузке в указанной БД postgres. Запуск от имени пользователя postgres

![image](https://github.com/user-attachments/assets/41ae36ab-c5b4-4f72-8efd-749c8e6c29b3)

## 3.Запустить pgbench -c8 -P 6 -T 60 -U postgres postgres
![image](https://github.com/user-attachments/assets/0acba6c2-2749-42a4-bd70-1a003ca5bc0b)

**Итоговая tps = 26.175445**

## 4.Применить параметры настройки PostgreSQL из прикрепленного к материалам занятия файла
### Чтобы применить новые параметры конфигурации воспользуемся созданием пользовательской конфигурации в папке conf.d.

Сначала проверим что эта настройка включена в файле postgresql.conf

![image](https://github.com/user-attachments/assets/fad60280-8adc-432c-9972-3568a7d343dc)

Листаем в конец файла. Использование пользовательских файлов конфигурации PG включено.

![image](https://github.com/user-attachments/assets/7f641675-7491-4171-a46e-3654dd85da56)

Создаем файл с расширением conf и вставляем туда данные из прикрепленного файла к ДЗ

![image](https://github.com/user-attachments/assets/e1096c65-c327-403c-8604-4577895317fa)

Добавляем настройки и сохраняем

![image](https://github.com/user-attachments/assets/298beebb-5935-410d-a546-75e95acd4981)

Проверяем какие параметры сейчас применяются:

![image](https://github.com/user-attachments/assets/be31a18f-1fde-40a7-8e8c-6d3363bda5bb)

Видим что часть параметров применилось из нового файла test.conf, но часть их них требует перезагрузки службы PG. Перезагрузим службу.

![image](https://github.com/user-attachments/assets/b9991e35-4a54-45b3-b020-948b0ac98e2c)

### Запускаем заново тестовую нагрузку 

![image](https://github.com/user-attachments/assets/ac4a09d2-fbcf-4060-aa45-94ebd4a236b5)

**Итоговая tps = 29.318227**

## 3.Что изменилось и почему?
Кол-во транзакций в секунду увеличилось за счет: увеличения размера WAL (дольше копиться для сброса на диск), shared_buffers увеличен до 25% от общего объема ОЗУ.

## 4.Создать таблицу с текстовым полем и заполнить случайными или с генерированными данным в размере 1млн строк
```bash
CREATE TABLE test.mrecords as select generate_series as id, substr(md5(random()::text), 1, 25) as name from generate_series(1,power(10,6)::int,1);
```
![image](https://github.com/user-attachments/assets/557526ab-0f1b-4d06-8797-d09c2ca93d8f)

### Посмотреть размер файла с таблицей
```bash
SELECT pg_size_pretty(pg_total_relation_size('test.mrecords'));
```
![image](https://github.com/user-attachments/assets/90ff27b6-0a2a-49c3-909e-98df68a41499)

**Размер 57Мб**

## 5.Тест №1
Исходные данные по "мертвым" записям и дата autovacuum
![image](https://github.com/user-attachments/assets/b466d9b2-2a2d-4514-9c22-d324b21058f4)

### 5 раз обновить все строчки и добавить к каждой строчке любой символ
```bash
do
$$
declare 
  i record;
begin
  for i in 1..5 loop
    update test.mrecords
    set name=name||1;
  end loop;
end;
$$
```
![image](https://github.com/user-attachments/assets/9664c608-33c8-4b46-a223-b801f229d61e)

### Посмотреть количество мертвых строчек в таблице и когда последний раз приходил автовакуум
```bash
SELECT relname, n_live_tup, n_dead_tup,
        trunc(100*n_dead_tup/(n_live_tup+1))::float AS "ratio%", last_autovacuum
FROM pg_stat_user_tables WHERE relname = 'mrecords';
```
![image](https://github.com/user-attachments/assets/deb03e99-d29f-4eb9-81b5-0ff826d07965)

Раз мы выполнили 5 раз обновление всех строк, то и мертвых строк будет 5*кол-во обновленных строк = 5 млн.

### Подождать некоторое время, проверяя, пришел ли автовакуум
![image](https://github.com/user-attachments/assets/65c0a4a0-050b-4523-9de6-b72915c5005d)

Пришлось ждать 47 мин, чтобы он отработал. На таблице из 100 строк (тоже обновлял все) нужно было ждать 5-7 секунд.

![image](https://github.com/user-attachments/assets/fa7e549d-dc8d-4934-9eae-636762c018b5)

После отработки autovacuum размер таблицы остался без изменений и занял 368Mb. Это как раз примерно в 6 раз больше чем начальный объем 57Mb. Вычисляется как 1 млн действующих строк + 5 млн "мертвых".
А размер остался без изменений по причине того, что autovacuum лишь помечает что страницы свободны и их можно использовать для данных таблицы повторно, но не сообщает ОС что они свободны.
Для этого нужно выполнить команду Vacuum Full

## 6.Тест №2
### 5 раз обновить все строчки и добавить к каждой строчке любой символ
![image](https://github.com/user-attachments/assets/dde5afa1-be77-4317-8b48-062e8d28c563)
### Посмотреть размер файла с таблицей
![image](https://github.com/user-attachments/assets/195315d4-1d81-4af4-bf88-0b047b5117d0)

Размер таблицы незначительно увеличился, т.к. большую часть занятого места было переиспользовано заново (то что было помечено autovacuum как свободное).

### Отключить Автовакуум на конкретной таблице
```bash
ALTER TABLE test.mrecords set (autovacuum_enabled = off);
```
![image](https://github.com/user-attachments/assets/a3b29a2f-8eaf-47d2-8aaa-f199d9e6ab5e)

### 10 раз обновить все строчки и добавить к каждой строчке любой символ

### Посмотреть размер файла с таблицей
![image](https://github.com/user-attachments/assets/b69cec4b-1f90-4e3e-a535-07c89fd9a851)

### Объясните полученный результат
Размер таблицы увеличился больше чем 10 размеров исходной таблицы, т.к. появилось 10*кол-во строк таблицы "метвых" строк + освобожденное пространство autovacuum не все переиспользовано и занято новое. Чтобы вернуть размер таблицы к исходному состоянию нужно выполнить vacuum full для таблицы. Он скопирует только действующие записи в другое место (oid таблицы поменяется), а текущую версию таблицы удалит.
### Не забудьте включить автовакуум)
```bash
ALTER TABLE test.mrecords set (autovacuum_enabled = on);
```
## 7.Задание со *: Написать анонимную процедуру, в которой в цикле 10 раз обновятся все строчки в искомой таблице. Не забыть вывести номер шага цикла.
```bash
do
$$
declare 
  i record;
  n int = 10;
begin
  for i in 1..n loop
    update test.mrecords
    set name=name||2;
    raise notice 'Шаг % из %', i, n;
  end loop;
end;
$$;
```

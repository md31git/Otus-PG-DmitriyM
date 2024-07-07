## 1.создайте новый кластер PostgresSQL 14 и зайдите в созданный кластер под пользователем postgres
sudo -u postgres psql

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/0d0f266d-3c88-4efd-82aa-35a8c7d33b84)

## 2.создайте новую базу данных testdb и зайдите в созданную базу данных под пользователем postgres
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/76c87e71-d691-48e3-8e30-8cb24ca8d3ed)

## 3.создайте новую схему testnm и создайте новую таблицу t1 с одной колонкой c1 типа integer и вставьте строку со значением c1=1
При создании таблицы необходимо указывать схему, иначе она создастся в схеме по умолчанию. Как и при создании схемы необходимо переключиться в нужную БД, иначе схема создастся в БД postgres.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/66429001-19de-45e9-8b58-0a1bb604d407)

## 4.создайте новую роль readonly и дайте новой роли право на подключение к базе данных testdb и дайте новой роли право на использование схемы testnm и дайте новой роли право на select для всех таблиц схемы testnm

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/e18101f5-55c9-40b7-b2ca-30c9a02cc361)

Далее проверим что права даны:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/623b906a-60dd-47d0-bd5c-bccb86afa00f)

## 5. создайте пользователя testread с паролем test123 и дайте роль readonly пользователю testread

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/3b2bf249-bcdd-4df7-bea5-f05d27b18b09)

Проверим что пользователь создался и у него установлен флаг что он может выполнять подключения:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/2e261203-327d-4929-9885-585e5f9f6167)

## 6. зайдите под пользователем testread в базу данных testdb и сделайте select * from t1;
При попытки подключиться к БД testdb под пользователем testread вышла ошибка (не попросил ввод пароля):
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/0a901b40-be7d-4bd4-824b-ec18c75c2cf8)

Пришлось выходить из psql и заходить заново  и тогда был запрошен пароль на su и затем на testread

sudo -u postgres psql -h localhost -U testread -d testdb
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/ddaf6f0f-714e-471a-a3a9-7ae471c15f46)

Запрашиваем таблицу с явным указанием схемы как делали выше при создании ее и тогда ошибки нет:
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/1b734efb-6b0d-4eb5-92e0-a7aa4bf0a27e)

## 7. теперь попробуйте выполнить команду create table t2(c1 integer); insert into t2 values (2); а как так? нам же никто прав на создание таблиц и insert в них под ролью readonly?
Таблица без указания схемы создалась в схеме по умолчанию public согласно настройке search_path. А в 14 версии у всех пользователей после создания выдаются права на CREATE в схеме public.

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/3f9c058f-207f-4054-b580-db9e7aa53e56)

Если попытаться создать таблицу в нужной схеме testnm, то получаем ошибку об отсутствии прав, т.к. права на создания мы не давали для схемы testnm:

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/31d3d849-7269-424f-b1c0-d2e3a5fd76ad)

## 7.есть идеи как убрать эти права? если нет - смотрите шпаргалку
В итоге посмотрев шпаргалку забрал права у роли public:  
* все права в схеме public
* все права на БД testdb (это надо повторить для всех БД)
  
![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/5b13b43d-916a-40d5-b208-93f1511b4886)

П.С. когда забрал только на создание права в схеме public, то все равно PG разрешал создавать таблицу в схеме public.

## 8.теперь попробуйте выполнить команду create table t3(c1 integer); insert into t2 values (2);
Теперь нельзя ни создать таблицу, ни вставить данные в схеме public, т.к. забраны все права. 

![image](https://github.com/md31git/Otus-PG-DmitriyM/assets/108184930/257e233b-6965-4cc6-b0f2-50b0b9c35cdc)

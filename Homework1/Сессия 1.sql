----------------------------------------------------------
drop table persons;
create table persons
 (
     id serial, 
     first_name text, 
     second_name text);
 
delete from persons;
insert into persons(first_name, second_name)
values('ivan', 'ivanov'), 
      ('petr', 'petrov');
commit;

select *
from persons
----------------------------------------------------------
show transaction isolation level;
----------------------------------------------------------
 insert into persons(first_name, second_name) 
 values('sergey', 'sergeev');
 
select *
from persons

commit;
---------------------------------------------------------
set session characteristics as transaction isolation level repeatable read;
---------------------------------------------------------
insert into persons(first_name, second_name) 
values('sveta', 'svetova');

select * from persons;
commit;

--delete from persons where first_name = 'sveta'







create table persons
 (
     id serial, 
     first_name text, 
     second_name text);
    
insert into persons(first_name, second_name)
values('ivan', 'ivanov'), 
      ('petr', 'petrov');

select *
from persons
----------------------------------------------------------
show transaction isolation level;
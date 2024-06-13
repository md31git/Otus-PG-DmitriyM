select *
from persons;

---------------------------------------------------------------------------
set session characteristics as transaction isolation level repeatable read;
show transaction isolation level;

select *
from persons;

commit



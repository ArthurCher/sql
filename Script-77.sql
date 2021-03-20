numeric/decimal: 10.35 + 9.65 = 20
float(real/double precision): 10.350000000001 + 9.649999999999 ~ 20

select x,
  round(x::numeric) as num_round,
  round(x::double precision) as dbl_round
from generate_series(-3.5, 3.5, 1) as x;

create or replace function some_func_1 (x int, y int, out z numeric) as $$
	begin
		select power(x, y) into z;
	end;
$$ language plpgsql

select some_func_1(2, 3)

create or replace function some_func_1 (x int, y int, out z numeric) as $$
	begin
		if x < 0 
			then raise exception 'x должен быть больше нуля';
		else
			select power(x, y) into z;
		end if;
	end;
$$ language plpgsql

select some_func_1((select customer_id from customer where customer_id = 3), 3)

select some_func_1(c.customer_id, c.address_id), c.customer_id, c.address_id
from customer c
join address a using(address_id)
where c.customer_id < 10 and c.address_id < 10

create function some_func_3() returns setof record as $$
declare 
	t record;
	c integer;
begin
	for t in 
		select table_name
		from information_schema.tables 
		where table_schema = 'dvd-rental' and table_type != 'VIEW'
		order by 1
	loop
		execute 'select count(*) cnt from ' || t.table_name into c;
		return query select t::text, c::text;
	end loop;
end;
$$ language plpgsql

select * from some_func_3() f(table_name text, count_records text)

create table a (
	id serial primary key,
	name varchar(100) not null,
	create_date timestamp default now(),
	last_update timestamp,
	old_name varchar(50)
)

create or replace function some_func_4() returns trigger as $$
	begin
		new.last_update = now();
		new.old_name = old.name;
		return new;
	end;
$$ language plpgsql

drop function some_func_4

create trigger some_func_4_trigger
before update on a
for each row execute procedure some_func_4()
-- до 10 включительно и ниже procedure, после 10 function 

insert into a (name) 
values ('a'), ('b'), ('c')

select * from a

update a 
set name = 'x'
where id = 2

create function process_table_audit() returns trigger as $$
declare 
x text;
    begin 
	    x = concat(old.id, ' | ', old.name, ' | ', old.create_date, ' | ', old.last_update, ' | ', old.old_name, ' | ', old.new_column) 
   		if (TG_OP = 'DELETE') then 
       		insert into emp_audit select 'D', now(), user, x, TG_TABLE_NAME;
       	elsif (TG_OP = 'UPDATE') then 
           	insert into emp_audit select 'U', now(), user, new.*, TG_TABLE_NAME;
       	elsif (TG_OP = 'INSERT') then 
           	insert into emp_audit select 'I', now(), user, new.*, TG_TABLE_NAME;
       	end if;
       	return null; -- возвращаемое значение для триггера AFTER игнорируется
    end;
$$ language plpgsql;

create trigger table_audit
after insert or update or delete on some_table
for each row execute function process_table_audit();

select concat(id, ' | ', name, ' | ', create_date, ' | ', last_update, ' | ', old_name) 
from a
where id = 2









create table author (
	author_id serial primary key,
	full_name varchar(70) unique not null,
	nickname varchar(30) unique,
	bith_date date not null
)

insert into author (full_name, nickname, bith_date)
values ('Федор Достоевский', 'dost', '1821-11-11'),
	   ('Сергей Есенин', 'esenya', '1895-09-21'),
	   ('Джэк Лондон', 'london', '1876-01-12')
	   
alter table author add column birth_place varchar(30)

update author set birth_place = 'Сан-Франциско'
where author_id = 3

select *
from author a 

create table literary_work(
	"year" varchar(30) not null,
	title varchar(30) not null,
	author_id integer references author(author_id),
	primary key (title, author_id)
)

insert into literary_work ("year", title, author_id)
values ('1920', 'стихотворение', '2'),
	   ('1906', 'белые клык', '3')
	   
delete from author 
where author_id = 2
	   
select *
from literary_work lw

CREATE TABLE orders (
	ID serial NOT NULL PRIMARY KEY, 
	info json NOT null
)

INSERT INTO orders (info)
VALUES ( '{ "customer": "John Doe", "items": {"product": "Beer","qty": 6}}' ), 
	   ( '{ "customer": "Lily Bush", "items": {"product": "Diaper","qty": 24}}' ), 
	   ( '{ "customer": "Josh William", "items": {"product": "Toy Car","qty": 1}}' ), 
	   ( '{ "customer": "Mary Clark", "items": {"product": "Toy Train","qty": 2}}' )

select *
from orders o

select sum(cast(info -> 'items'->> 'qty' as integer))
from orders

select f.film_id, f.title, f.special_features, array_length(f.special_features, 1) count_special_features
from film f 
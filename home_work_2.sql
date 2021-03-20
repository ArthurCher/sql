-- Домашнее задание №2

/* 1) Перечислить все таблицы и первичные ключи в базе данных. Формат решения в виде таблицы:
| Название таблицы | Первичный ключ | */

-- Мне показалось запросом вывести название таблиц с их PRIMARY KEY проще, чем переписывать из ER-диаграммы.
-- Получилось вот так - поправьте, пжл, если не прав

select table_constraints.table_name, 
	   table_constraints.constraint_name, 
	   table_constraints.constraint_type
from information_schema.table_constraints
where table_constraints.constraint_schema = 'public' and table_constraints.constraint_type = 'PRIMARY KEY';

-- 2) вывести всех неактивных покупателей. Вывел только имена, email и активность

select first_name as customer_first_name,
	   last_name as customer_last_name,
	   email as customer_email,
	   active as customer_active
from customer
where active = 0;

-- 3) Вывести все фильмы, выпущенные в 2006 году. Все фильмы и были выпущены в 2006 году - поэтому вывелись все

select film_id as FilmId, 
	   title as FilmTitle, 
	   description as FilmDescription, 
	   release_year as FilmReleaseYear,
	   rental_rate / rental_duration as FilmRentalPrice,
	   rating as FilmRating
from film
where release_year = 2006;

-- 4) Вывести 10 последних платежей за прокат фильмов. Взял только id, платеж и дату. 
-- Отсортировал по дате - от последних к первым, и вывел первые 10. Может не прав

select payment_id, 
	   amount as payment_amount,
	   payment_date
from payment
order by payment_date desc
limit 10;

-- Дополнительные задания

-- 1) Вывести первичные ключи через запрос. 
-- Вывели имя и тип ключа, чтобы убедиться, что именно PRIMARY KEY

select table_constraints.table_name, 
	   table_constraints.constraint_name, 
	   table_constraints.constraint_type 
from information_schema.table_constraints
where table_constraints.constraint_schema = 'public' and constraint_type = 'PRIMARY KEY';

-- 2) Расширить запрос с первичными ключами, добавив информацию по типу данных
/* Тут самые большие сложности, но мог ошибиться. Запросил constraint_name, constraint_type из table_constraint и data_type из columns
Через пересение table_constraint с key_column_usage по constraint_name, а затем key_column_usage с columns по column_name объединил таблицы
Получилось, что один и тот же PRIMARY KEY может иметь разный тип данных. Это верно? */

select table_constraints.table_name,
	   key_column_usage.column_name,
	   table_constraints.constraint_name,
	   columns.data_type as constraint_data_type,
	   table_constraints.constraint_type 
from information_schema.table_constraints 
left join information_schema.key_column_usage on  key_column_usage.constraint_name = table_constraints.constraint_name
		and table_constraints.table_name = key_column_usage.table_name
		and table_constraints.constraint_schema = key_column_usage.constraint_schema
left join information_schema.columns on columns.column_name = key_column_usage.column_name
		and key_column_usage.table_name = columns.table_name
		and key_column_usage.constraint_schema = columns.table_schema
where table_constraints.constraint_type = 'PRIMARY KEY' and table_constraints.constraint_schema = 'public';
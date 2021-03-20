-- 1. Сколько оплатил каждый пользователь за прокат фильмов за каждый месяц

select c.customer_id, 
	   concat(c.first_name, ' ', c.last_name) customer_name,
	   sum(p2.amount) customer_payment, 
	   to_char(p2.payment_date, 'YYYY-MM') "month"
from customer c 
join payment p2 on p2.customer_id = c.customer_id 
group by "month", c.customer_id
order by c.customer_id, "month"

-- 2. На какую сумму продал каждый сотрудник магазина

select s.staff_id, concat(s.first_name, s.last_name), sum(p.amount) sum_sale
from staff s 
join payment p on p.staff_id = s.staff_id 
group by s.staff_id 

-- 3. Сколько каждый пользователь взял фильмов в аренду

select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, count(r.rental_id) count_rent_film
from customer c 
join rental r on r.customer_id = c.customer_id 
group by c.customer_id 
order by c.customer_id 

-- 4. Сколько раз брали в прокат фильмы, в которых снимались актрисы с именем Julia

select  f.film_id, f.title, count(r2.rental_id) count_rent, a.first_name actor_first_name
from film f 
join inventory i on i.film_id = f.film_id 
join rental r2 on i.inventory_id = r2.inventory_id 
join film_actor fa on fa.film_id = f.film_id 
join actor a on a.actor_id =fa.actor_id 
where a.first_name = 'Julia' 
group by f.film_id, a.first_name 
order by f.film_id 

-- 5. Сколько актеров снимались в фильмах, в названии которых встречается подстрока bed

select count(a.actor_id) count_actor, f.title 
from actor a 
join film_actor fa on fa.actor_id = a.actor_id 
join film f on f.film_id = fa.film_id 
where f.title ilike '%bed%'
group by f.film_id 
order by f.title 

-- 6. Вывести пользователей, у которых указано два адреса
-- Проверил у a.address указано not null, поэтому не проверял a.address на null

select c.customer_id, concat(c.first_name, ' ', c.last_name) customer_name, a.address2 
from customer c 
left join address a on a.address_id = c.address_id 
where (a.address2 is not null and trim(a.address2) <> '') and trim(a.address) <> ''

-- 7. Сформировать массив из категорий фильмов и для каждого фильма вывести индекс массива соответствующей категории

select f.film_id, f.title, c."name" "film_category", 
	array_position(
		(
			select array_agg(c."name") as name_category
			from category c
		),
		c."name"
	) id_array_cat
from film f 
left join film_category fc on f.film_id = fc.film_id 
left join category c on c.category_id = fc.category_id 
group by f.film_id, c.category_id 
order by f.film_id

-- 8. Вывести массив с идентификаторами пользователей в фамилиях которых есть подстрока 'ah'

select array_agg(c.customer_id) 
from customer c 
where c.last_name ilike '%ah%'

-- 9. Вывести фильмы, у которых в названии третья буква 'b'

select f.film_id, f.title 
from film f 
where f.title ilike '__b%'

-- 10. Найти последнюю запись по пользователю в таблице аренда без учета last_update??

select first_tab.customer_id, first_tab.rental_id, first_tab.inventory_id, first_tab.staff_id, first_tab.last_date
from (select r.rental_id, r.inventory_id, r.customer_id, r.staff_id, 
	max(case when r.rental_date > r.return_date then r.rental_date
		     when r.rental_date < r.return_date then r.return_date
		end) as last_date
from rental r 
group by r.rental_id) as first_tab
join (
	select r.customer_id, 
		max(case when r.rental_date > r.return_date then r.rental_date
			 when r.rental_date < r.return_date then r.return_date
		end) as last_date
	from rental r
	group by r.customer_id 
) as help_tab on help_tab.customer_id = first_tab.customer_id and 
				 help_tab.last_date = first_tab.last_date
order by first_tab.customer_id

-- 11. Вывести ФИО пользователя и название третьего фильма, который он брал в аренду.

select *
from (
	select concat(c.first_name, ' ',  c.last_name) customer_name, f2.title,
		row_number () over (partition by c.customer_id order by r2.rental_date) as film_number
	from customer c 
	left join rental r2 on c.customer_id = r2.customer_id 
	left join inventory i on r2.inventory_id = i.inventory_id 
	left join film f2 on i.film_id = f2.film_id 
	order by c.customer_id
) as result_tab
where result_tab.film_number = 3

-- 12. Вывести пользователей, которые брали один и тот же фильм больше одного раза.

select *
from (
	select concat(c.first_name, ' ', c.last_name) customer_name, f2.film_id , count(f2.film_id) as rent_count
	from customer c 
	left join rental r2 on c.customer_id = r2.customer_id 
	left join inventory i2 on r2.inventory_id = i2.inventory_id 
	left join film f2 on i2.film_id = f2.film_id 
	group by c.customer_id, f2.film_id 
	order by c.customer_id  
) as result_tab
where result_tab.rent_count > 1

-- 13. Какой из месяцев оказался наиболее доходным?

select to_char(p.payment_date, 'YYYY-MM') as "month", sum(p.amount) month_rent_payment_amount
from payment p 
group by "month" 
order by month_rent_payment_amount desc 
limit 1

-- 14. Одним запросом ответить на два вопроса: в какой из месяцев взяли в аренду фильмов больше всего? 
-- На сколько по отношению к предыдущему месяцу было сдано в аренду больше/меньше фильмов.

select first_table."month", first_table.count_rent, second_table.diff_prev_month, first_table.max_month
from (
	select main_table."month", main_table.count_rent, help_table."month" as max_month
	from (
		select date_trunc('month', r.rental_date) as "month", count(r.rental_id) count_rent,
			   max(count(r.rental_id)) over () max_count
		from rental r 
		group by "month"
	) as main_table
	left join (
		select *
		from (
			select date_trunc('month', r.rental_date) as "month", count(r.rental_id) count_rent,
				   row_number () over (order by count(r.rental_id)) as max_month
			from rental r 
			group by "month"
		) as max_data
		where max_data.max_month = 5
	) as help_table on help_table.count_rent = main_table.max_count
) as first_table
left join (
	select max_data."month", max_data.count_rent, max_data.count_rent - dif_date.count_rent as diff_prev_month
	from (
		select date_trunc('month', r.rental_date) as "month", count(r.rental_id) count_rent,
			   row_number () over (order by date_trunc('month', r.rental_date)) as max_month
		from rental r 
		group by "month"
	) as max_data
	left join (
		select date_trunc('month', r.rental_date) as "month", count(r.rental_id) count_rent,
			   row_number () over (order by date_trunc('month', r.rental_date)) as num_month
		from rental r 
		group by "month"
	) as dif_date on dif_date.num_month = max_data.max_month - 1
	order by max_data."month"
) as second_table on first_table."month" = second_table."month"

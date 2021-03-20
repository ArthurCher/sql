with cte_table as (
	select concat(s.first_name, ' ', s.last_name) full_name_staff, r.rental_id 
	from staff s 
	left join rental r on r.staff_id = s.staff_id 
	order by r.rental_id 
)
select full_name_staff, count(rental_id) count_rent
from cte_table
group by full_name_staff

select concat(a.first_name, ' ', a.last_name) as full_name, f.title, 
count(concat(a.first_name, ' ', a.last_name)) over (partition by concat(a.first_name, ' ', a.last_name)) as count_film
from actor a 
left join film_actor fa on fa.actor_id = a.actor_id 
left join film f on f.film_id =fa.film_id 
order by full_name, f.title

create view info_last_customer_rental as
select last_customer_rental.customer_id, full_customer_name, email, last_customer_rental.last_rental, last_film_rental.title
from (
	select c.customer_id, concat(c.first_name, ' ', c.last_name) full_customer_name, c.email, max(r.rental_date) last_rental 
	from customer c 
	left join rental r on c.customer_id = r.customer_id 
	left join inventory i on i.inventory_id  = r.inventory_id 
	left join film f on f.film_id = i.film_id 
	group by c.customer_id, full_customer_name, c.email 
) last_customer_rental
join (
	select f.title, max(r.rental_date) last_rental, c.customer_id
	from film f 
	left join inventory i on f.film_id = i.film_id 
	left join rental r on r.inventory_id = i.inventory_id 
	left join customer c on c.customer_id = r.customer_id 
	group by c.customer_id, f.title 
) last_film_rental on last_customer_rental.customer_id = last_film_rental.customer_id and 
					  last_customer_rental.last_rental = last_film_rental.last_rental

select *
from info_last_customer_rental




-- 1. выведите магазины, имеющие больше 300-от покупателей

select c.store_id, count(c.customer_id) as count_customer
from customer c
group by c.store_id 
having count(c.customer_id) > 300

-- 2. выведите у каждого покупателя город в котором он живет

select c.customer_id, concat(c.first_name, ' ', c.last_name) full_name_customer, c2.city 
from customer c
left join address a on c.address_id = a.address_id 
left join city c2 on c2.city_id = a.city_id 
order by c.customer_id 

-- Дополнительные задания
-- 1. Выведите ФИО сотрудников и города магазинов, имеющих больше 300-от покупателей

select s.store_id, c.city, concat(s2.first_name, ' ', s2.last_name) staff_name, rs.count_customer
from store s 
left join address a on s.address_id = a.address_id
left join city c on c.city_id = a.city_id 
left join staff s2 on s2.store_id = s.store_id 
right join (
		select c2.store_id, count(c2.customer_id) as count_customer
		from customer c2 
		group by c2.store_id 
		having count(c2.customer_id) > 300
) as rs on rs.store_id = s.store_id 

-- 2. Выведите количество актеров, снимавшихся в фильмах, которые сдаются в аренду за 2,99

select count(a.actor_id) count_actor, f.title, f.rental_rate
from film f 
left join film_actor fa on f.film_id =fa.film_id 
left join actor a on a.actor_id = fa.actor_id 
group by f.title, f.rental_rate 
having f.rental_rate = 2.99
order by f.title 
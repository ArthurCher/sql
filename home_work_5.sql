-- 1. Сделайте запрос к таблице rental. 
-- Используя оконую функцию добавьте колонку с порядковым номером аренды для каждого пользователя (сортировать по rental_date)

select r.customer_id, r.rental_date, 
	row_number() over (partition by r.customer_id order by r.rental_date) as "row_number",
	r.rental_id, r.inventory_id, r.return_date, r.staff_id, r.last_update
from rental r 

-- 2. Для каждого пользователя подсчитайте сколько он брал в аренду фильмов со специальным атрибутом Behind the Scenes
-- -напишите этот запрос
-- -создайте материализованное представление с этим запросом
-- -обновите материализованное представление
-- -напишите три варианта условия для поиска Behind the Scenes

select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where 'Behind the Scenes' = any(f.special_features)
group by c.customer_id 
order by c.customer_id 

create materialized view count_customer_film as
select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where 'Behind the Scenes' = any(f.special_features)
group by c.customer_id 
order by c.customer_id
with no data

refresh materialized view count_customer_film

-- три условия для поиска Behind the Scenes (третье в изначальном запросе)

select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where 'Behind the Scenes' = some(f.special_features)
group by c.customer_id 
order by c.customer_id

select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where '{Behind the Scenes}' && f.special_features 
group by c.customer_id 
order by c.customer_id

-- Доп задание
-- - открыть по ссылке sql запрос [https://letsdocode.ru/sql-hw5.sql], сделать explain analyze запроса
-- - основываясь на описании запроса, найдите узкие места и опишите их

explain analyze
select distinct cu.first_name  || ' ' || cu.last_name as name, 
	count(ren.iid) over (partition by cu.customer_id)
from customer cu
full outer join 
	(select *, r.inventory_id as iid, inv.sf_string as sfs, r.customer_id as cid
	from rental r 
	full outer join 
		(select *, unnest(f.special_features) as sf_string
		from inventory i
		full outer join film f on f.film_id = i.film_id) as inv 
		on r.inventory_id = inv.inventory_id) as ren 
	on ren.cid = cu.customer_id 
where ren.sfs like '%Behind the Scenes%'
order by count desc

-- Очень много ресурсов съели:
-- 1) две сортировки: одна в окне и потом общая
-- 2) два внешних full outer join
-- 3) индексное сканирование, создание битовой карты с идексами строк и потом извлечение инфы оттуда

-- -сравните с Вашим запросом из основной части (если Ваш запрос изначально укладывается в 15мс - отлично!)

explain analyze
select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where 'Behind the Scenes' = any(f.special_features)
group by c.customer_id 
order by c.customer_id

-- мой запрос тратит намного меньше времени и немногим меньше ресурсов, но выдает больше 15 мс - 15.797

-- -оптимизируйте запрос, сократив время обработки до максимум 15мс

explain analyze
select c.customer_id, concat(c.first_name, ' ', c.last_name) as full_customer_name, count(c.customer_id) count_result_film
from customer c 
left join rental r on r.customer_id = c.customer_id 
left join inventory i on i.inventory_id = r.inventory_id 
left join film f on f.film_id = i.film_id 
where 'Behind the Scenes' = any(f.special_features)
group by c.customer_id

-- больше всего ела сортировка и left join-ы. Сортировку убрал - в условии о ней ничего не говорилось
-- пробовал заменить на inner join, но left работал быстрее, оставил его
-- в целом без сортировки стабильно выходит за 15 мс - где-то 14 мс - 14,5 мс выдает (в зависимости от нагрузки на цп похоже)

-- -сделайте построчное описание explain analyze на русском языке оптимизированного запроса. 

-- 1. Идет сканирование inventory, тратиться 0,5 мс
-- 2. Помещается результат скана в хэш
-- 3. Параллельно с этим (с пунктом 2) сканируется film и фильтруется по Behind the Scenes (приведенному к тексту).
-- Отсекается 462 строки
-- 4. После записи inventory в хэш и параллельно сканированию и фильтрации записей film - сканируется rental
-- 5. rental и inventory джойнятся по inventory_id)
-- 6. Параллельно с этим джойном записывается в хэш фильтрованные данные из film
-- 7. Затем то, что получилось в пункте 5 джойнится с фильтрованной таблицей film из пункта 6 по film_id
-- 8. Параллельно с джойном из пункта 7 запускается сканирование customer и помещаются данные от туда в хэш
-- 9. Результат джойна из пункта 7 джойнится с customer по customer_id
-- 10. Резервируется память 
-- 11. Далее результат всех джойной группируется по customer_id и применяется агрегатная функция
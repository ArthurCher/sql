select rating as FilmRating
from film;

select film_id as FilmId, 
	   title as FilmTitle, 
	   description as FilmDescription, 
	   release_year as FilmReleaseYear,
	   rental_rate / rental_duration as FilmRentalPrice
from film;

select film_id as FilmId, 
	   title as FilmTitle, 
	   description as FilmDescription, 
	   release_year as FilmReleaseYear,
	   rental_rate / rental_duration as FilmRentalPrice
from film
order by FilmRentalPrice desc;

select distinct release_year as FilmReleaseYear
from film;

select film_id as FilmId, 
	   title as FilmTitle, 
	   description as FilmDescription, 
	   release_year as FilmReleaseYear,
	   rental_rate / rental_duration as FilmRentalPrice,
	   rating as FilmRating
from film
where rating = 'PG-13'

select f.title, l."name" 
from film f 
left join "language" l on f.language_id = l.language_id

select concat(a.first_name, ' ', a.last_name) as actor, f.title 
from actor a 
inner join film_actor fa on a.actor_id = fa.actor_id 
inner join film f on f.film_id = fa.film_id 
where f.film_id = 508

select count(fa.actor_id)
from film_actor fa 
where fa.film_id = 384

select f.title, fa.actor_id
from film f 
inner join film_actor fa on f.film_id = fa.film_id

select f.title, count(fa.actor_id) as actor_count
from film f 
inner join film_actor fa on f.film_id = fa.film_id
group by f.title
having count(fa.actor_id) > 10
order by actor_count desc

select a.actor_id, f.title, concat(a.first_name,' ',  a.last_name) as actor,
	   count(f.title) over (partition by a.actor_id) as count_film
from film f 
left join film_actor fa on f.film_id = fa.film_id 
left join actor a on a.actor_id = fa.actor_id
where a.actor_id is not null 
order by actor  
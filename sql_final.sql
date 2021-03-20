-- 1. В каких городах больше одного аэропорта?

select a.city, count(a.airport_code) as count_airports
from airports a 
group by a.city
having count(a.airport_code) > 1

-- Взял таблицу airports сгруппировал по городу, посчитал по каждой группе количество через count 
-- Отфильтровал, чтобы это количество было больше 1

-- 2. В каких аэропортах есть рейсы, выполняемые самолетом с максимальной дальностью перелета?

select distinct a.airport_code, a.airport_name
from airports a 
left join flights f on f.departure_airport = a.airport_code
where f.aircraft_code = (
	select a1.aircraft_code 
	from aircrafts a1  
	order by a1."range" desc 
	limit 1
) 

-- Взял таблицу airports
-- обоготил ее данными из flights по соответствию аэропорт = аэропорт отправления
-- Отфильтровал итог с помощью подзарпоса:
-- подзапросом выбрал самолет с самой большой дальностью полет
-- итоговую таблицу фильтранул, чтобы код самолет был равен коду самолета полученного подзапросом

-- 3. Вывести 10 рейсов с максимальным временем задержки вылета

select f2.flight_no, f2.scheduled_departure, f2.actual_departure, f2.actual_departure - f2.scheduled_departure as delay
from flights f2 
where actual_departure is not null
order by delay desc
limit 10

-- Выбрал номер рейса, время отправления планируемое, время отправления фактическое, 
-- добавил 4 столбец с разницей между фактическим временем отправления и планируемым - это как раз и есть время задержки
-- Фильтранул, чтобы в актуальное время отправления не попал null 
-- потому что могут быть рейсы, которые запланированы, но еще не вылетели - данных по задержке еше не будет у таких
-- Отсортировал по убыванию времени задержки и вывел первые 10

-- 4. Были ли брони, по которым не были получены посадочные талоны?

select b2.book_ref, b2.book_date, bp.boarding_no 
from bookings b2 
left join tickets t2 on t2.book_ref = b2.book_ref 
left join boarding_passes bp on bp.ticket_no = t2.ticket_no 
where bp.boarding_no is null

-- Взял таблицу с бронями, обоготил ее данными из таблицы билеты и еще раз обоготил данными из таблицы по посадочным талонам
-- Вывел номер брони, дату брони и соответствующий посадочный талон
-- Фильтранул, чтобы посадочный талон был null - получилось брони, у которых еще нет посадочных талонов
-- использовал left join везде, потому что как раз могут быть брони и билеты из посадочного
-- Также допустил, что могут быть брони без билета (мало ли, решил не рисковать)

-- 5. Найдите свободные места для каждого рейса, их % отношение к общему количеству мест в самолете.
-- Добавьте столбец с накопительным итогом - суммарное накопление количества вывезенных пассажиров из каждого аэропорта на каждый день. 
-- Т.е. в этом столбце должна отражаться накопительная сумма - сколько человек уже вылетело из данного аэропорта на этом или более ранних рейсах за день.

select f.flight_id, s.seat_no all_seat, ticket_info.seat_no as sold_seat,
	(((count(s.seat_no) over (partition by f.flight_id))::float - (count(ticket_info.seat_no) over (partition by f.flight_id))::float)/
	count(s.seat_no) over (partition by f.flight_id)::float) * 100 as part_free_seat,
	f.departure_airport, date_trunc('day', f.actual_departure) as departure_date,
	count(ticket_info.seat_no) over (partition by date_trunc('day', f.actual_departure), f.departure_airport) count_pass_flight
from flights f 
join seats s on f.aircraft_code = s.aircraft_code 
left join (
	select f.flight_id, tf.ticket_no, bp.seat_no 
	from flights f 
	join ticket_flights tf on tf.flight_id = f.flight_id 
	left join boarding_passes bp on bp.flight_id = tf.flight_id and bp.ticket_no = tf.ticket_no 
	order by tf.flight_id, bp.seat_no 
) as ticket_info on ticket_info.flight_id = f.flight_id and s.seat_no = ticket_info.seat_no
order by f.flight_id, all_seat 

-- Получил список всех рейсов и всех мест на этих рейсе
-- Подзапросом получил список рейсов, проданных на них билеты и места в этих билетах
-- обоготил данные со списком всех рейсов и всех мест на этих рейсах
-- получается пара id рейса и место в этом рейсе - уникальное (потому что не может быть 2 места на одном и том же рейсе, да в документации так написано)
-- поэтому при join делал соответствие, что и id рейса и номер места должны совпадать
-- left join потому что не на все места самолета были куплены билеты
-- получается там где пара id рейса и номер места - совпадает, подтянулся номер купленного места
-- там где нет - null, соответственно это место свободно (получается его нет в таблице с инфой по купленных билетам из подзапроса)
-- потом с помощью оконок посчитал количество занятых мест мест, это число отнял от общего количества мест - получилось количество свободных
-- это значение поделил на общее количество мест - получилась доля свободных мест от обшего количества и умножил на 100, чтобы получить проценты
-- далее подтянул название аэропорта, актуальную дату отправления (привел ко дню)
-- далее сгруппировал окна по дню и аэропорту одновременно
-- посчитал количество занятых мест в рейсах по каждому окну
-- по идее это и получается количество вывезенных пассажиров по каждому дня по каждому аэропорту, проверил в excel - вроде верно считает
-- считает где-то 10 сек

-- 6. Найдите процентное соотношение перелетов по типам самолетов от общего количества.

select f.aircraft_code, count(f.flight_id) all_type_flights,
	(
		select count(f1.flight_id)::decimal
		from flights f1
	) as all_flights,
	round((count(f.flight_id))::decimal / (
	select count(f1.flight_id)::decimal
	from flights f1
	), 3) * 100 as part_type_flights
from flights f 
group by f.aircraft_code 

-- Подзапросом получил общее количество перелетов all_flights
-- Вывел код самолета
-- Вывел в all_type_flights общее количество перелетов на этом самолете, сгруппировав по коду самолета и агрегатной функцией посчитав количество
-- И вывел отношение количество перелетов на конкретном самолете к общему количество перелетов всего - part_type_flights
-- Округлил до тысячных и умножил на 100 - чтобы получить процент

-- 7. Были ли города, в которые можно  добраться бизнес - классом дешевле, чем эконом-классом в рамках перелета?

with max_econom as (
	select tf.flight_id, max(tf.amount) max_econom_price
	from ticket_flights tf 
	where tf.fare_conditions = 'Economy'
	group by tf.flight_id 
	order by tf.flight_id ),
min_business as (
	select tf.flight_id, min(tf.amount) min_business_price
	from ticket_flights tf 
	where tf.fare_conditions = 'Business'
	group by tf.flight_id 
	order by tf.flight_id )
select f.flight_id, a.city, max_econom.max_econom_price, min_business.min_business_price
from flights f 
join airports a on f.arrival_airport = a.airport_code 
join max_econom on max_econom.flight_id = f.flight_id 
join min_business on min_business.flight_id = f.flight_id
where max_econom.max_econom_price > min_business.min_business_price

-- Посчитал в cte максимальную стоимость эконома в рамках перелета
-- Посчитал в cte минимальную стоимость бизнеса в рамках перелета
-- Взял таблицу перелетов 
-- Сджойнил по flight_id по inner join (потому что могут быть перелеты без бизнеса или без эконома - нам нужно чтобы и те и те были)
-- Вывел flight_id, city, максимальную стоимость эконома и минимальную стоимость бизнеса, 
-- где максимальная стоимость эконома больше минимальной стоимости бизнеса
-- Если такие перелеты есть, значит в рамках него бизнесом долететь дешевле чем экономом

-- 8. Между какими городами нет прямых рейсов?

create or replace view departure_city as
select a.city departure_city
from flights f 
join airports a on a.airport_code = f.departure_airport 
group by a.city

create or replace view arrival_airport as
select a.city arrival_city
from flights f 
join airports a on a.airport_code = f.arrival_airport 
group by a.city

create or replace view city_to_city as
select distinct a2.city departure_city, a3.city arrival_city
from flights f2 
join airports a2 on a2.airport_code = f2.departure_airport 
join airports a3 on a3.airport_code = f2.arrival_airport

with departure_city as ( 
	select *
	from departure_city ),
arrival_city as (
	select *
	from arrival_airport )
select departure_city.departure_city, arrival_city.arrival_city
from departure_city, arrival_city
where departure_city.departure_city <> arrival_city.arrival_city
except select *
from city_to_city

-- Сделал представление с городами отправления
-- Сделал представление с городами прибытия
-- Сделал представление с уникальным соответствием город вылета - город прилет в рамках перелета
-- Для этого таблицу перелетов расширил городами прибытия и вылета дважды приджойнив таблицу с аэропортами:
-- первый: по соответствию аэропорт вылета в перелетах - код аэропорта в аэропортах, чтобы подтянулся город аэропорта вылета
-- второй: по соответствию аэропорт прибытия в перелетах - код аэропорта в аэропортах, чтобы подтянулся город аэропорта прибытия
-- вывел пару город аэропорта вылета - город аэропорта прибытия и убрал дубли строк
-- Затем перемножил представление с городами отправления с представлением с городами прибытия, чтобы получить все возможные комбинации
-- Фильтранул чтобы городами прибытия был не равен городу отправления
-- Из этого множества вычел множество полученное представление с уникальным соответствием город вылета - город прилет в рамках перелета
-- Остались пары городов, между которыми нет перелетов

-- 9. Вычислите расстояние между аэропортами, связанными прямыми рейсами, 
-- сравните с допустимой максимальной дальностью перелетов  в самолетах, обслуживающих эти рейсы

create or replace function get_distance (latitude_a float, latitude_b float, longitude_a float, longitude_b float, out dist float) as $$
	declare 
		d float;
	begin
		d = acos (sin(radians(latitude_a))*sin(radians(latitude_b)) + cos(radians(latitude_a))*cos(radians(latitude_b))*cos(radians(longitude_a) - radians(longitude_b)));
		dist = d*6371;
	end;
$$ language plpgsql

create or replace function count_flight (max_range float, distance float, out count_flight integer) as $$
	declare 
		stock float;
	begin 
		count_flight = 0;
		stock = max_range;
		while stock > distance loop
			count_flight = count_flight + 1;
			stock = stock - distance;
		end loop;
	end;
$$ language plpgsql

select f2.flight_id, a2.airport_code departure_airport, a3.airport_code arrival_airport, 
	get_distance (a2.latitude, a3.latitude, a2.longitude, a3.longitude) distance_airports,
	a4.model aircraft_model,
	(a4."range" - get_distance (a2.latitude, a3.latitude, a2.longitude, a3.longitude)) power_reserve,
	count_flight(a4."range", get_distance (a2.latitude, a3.latitude, a2.longitude, a3.longitude)) count_flight
from flights f2 
join airports a2 on f2.departure_airport = a2.airport_code 
join airports a3 on f2.arrival_airport = a3.airport_code 
join aircrafts a4 on f2.aircraft_code = a4.aircraft_code 

-- Чтобы не загромождать запрос - сделал хранимую функцию с формулой расчета расстояния между две точками на сфере
-- К таблице с перелетов дважды приджойнил таблицу аэоропортов 
-- В начале по коду аэропорта вылета, чтобы получить координаты аэропорта вылета
-- Потом по коду аэропорта прилета, чтобы получить координаты прилета
-- применил созданную функцию расчета расстояния и вывел значение для каждого рейса (потому что как я понял нужно в рамках рейса выводить)
-- Приджойнил таблицу с самолетами (по коду самолета) и вывел модель самолет, который обслуживает рейс
-- Также получил максимальную дальность полета самолета этим джойном
-- Вычел из максимальной дальности полета самолета расстояние между аэропортами в рамках рейса, который он обслуживает
-- Получил оставшийся запас хода после одного перелета - вывел его в power_reserve
-- Решил что этого мало, посчитал сколько на одном баке соответствуюший может сделать соответствующих перелетов - вывел в count_flight
-- Сделал для этого еще одну хранимую функцию
Основная часть:
Спроектируйте базу данных для следующих сущностей:
-язык (в смысле английский, французский и тп)
-народность (в смысле славяне, англосаксы и тп)
-страны (в смысле Россия, Германия и тп)

Правила следующие:
-на одном языке может говорить несколько народностей
-одна народность может входить в несколько стран
-каждая страна может состоять из нескольких народностей

create schema training_scheme

set search_path to training_scheme

create table languages (
	language_id serial primary key,
	name_lang varchar(30) unique not null
)

create table nationalities (
	nationality_id serial primary key,
	name_national varchar(30) unique not null
)

create table countries (
	country_id serial primary key,
	name_country varchar(50) unique not null
)

create table languages_nationalities (
	language_id int2 references languages(language_id),
	nationality_id int2 unique references nationalities(nationality_id),
	primary key (language_id, nationality_id)
)

create table nationalities_countries (
	nationality_id int2 not null,
	country_id int2 not null,
	primary key (nationality_id, country_id)
)

alter table nationalities_countries add constraint fk_nationality_id foreign key (nationality_id) references nationalities(nationality_id)

alter table nationalities_countries add constraint fk_country_id foreign key (country_id) references countries(country_id)

insert into languages (name_lang)
values (unnest(array['русский', 'английский', 'немецкий', 'французский', 'испанский']))

insert into nationalities (name_national)
values (unnest(array['шотландцы', 'испанцы', 'русские', 'англичане', 'американцы']))

insert into countries (name_country)
values (unnest(array['США', 'Испания', 'Германия', 'Великобритания', 'Россия']))

insert into languages_nationalities (language_id, nationality_id)
values (1, 3)

insert into languages_nationalities (language_id, nationality_id)
values (2, 4)

insert into languages_nationalities (language_id, nationality_id)
values (2, 5)

insert into languages_nationalities (language_id, nationality_id)
values (2, 1)

insert into languages_nationalities (language_id, nationality_id)
values (5, 2)

insert into nationalities_countries (nationality_id, country_id)
values (1, 3)

insert into nationalities_countries (nationality_id, country_id)
values (2, 2)

insert into nationalities_countries (nationality_id, country_id)
values (3, 5)

insert into nationalities_countries (nationality_id, country_id)
values (3, 3)

insert into nationalities_countries (nationality_id, country_id)
values (4, 4)

insert into nationalities_countries (nationality_id, country_id)
values (4, 1)

insert into nationalities_countries (nationality_id, country_id)
values (5, 1)

alter table languages add last_update timestamp default now()

alter table countries add last_update timestamp default now()

alter table nationalities add last_update timestamp default now()

alter table languages_nationalities add last_update timestamp default now()

alter table nationalities_countries add last_update timestamp default now()

alter table countries add description text

update countries set description = 'Самая прекрасная страна', last_update = now()
where country_id = 5

alter table nationalities add _exist boolean

update nationalities set _exist = 'true'
where nationality_id = 2

update nationalities set _exist = 'false'
where nationality_id = 1

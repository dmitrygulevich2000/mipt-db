-- connected as ro

set role rw;

-- INIT DATA
insert into catalog.room_description(level, guests_number) values 
	(catalog.room_level('default'), 2),
	(catalog.room_level('lux'), 2)
;
insert into catalog.room_description(level, guests_number, has_tv) values 
	(catalog.room_level('default'), 3, true)
;

insert into catalog.room values 
 (11, 1),
 (21, 1),
 (12, 2),
 (22, 3)
;

insert into catalog.tariff(description_id, started_at, room_price_ruble) values 
	(1, now() - interval '1' day, 1000),
	(2, now() - interval '1' day, 1800),
	(3, now() - interval '1' day, 1500)
;
insert into catalog.tariff(description_id, started_at, room_price_ruble) values 
	(2, now(), 1600) -- new tariff for room 12
;

insert into user_story.customer(email, phone_number, name) values
	('gulevich.ds@phystech.edu', '897712345678', 'Дмитрий Гулевич'),
	('chert@rossiya23.ru', '+7-920-876-543-21', 'Владимир')
;

insert into user_story.order(room_number, tariff_id, customer_id, start_at, end_at) values
	-- overlapping orders of different rooms
	(21, 1, 1, now() - interval '1' day, now() + interval '1' day),
	(12, 2, 2, now() - interval '2' day, now()                   ), -- legacy tariff
	-- order of same room with fresh tariff
	(12, 4, 2, now(),                    now() + interval '1' day)
;

--- QUERIES
-- придумал такой прикол, чтобы дать название константе `now - 1 day`
-- возвращает список заказов, которые на момент запроса начались, но не закончились
with query_time as (select now() - interval '1' day as time)
select * from user_story.order where 
	start_at <= (select time from query_time) and
	end_at >= (select time from query_time);

--- возвращает актуальную цену на комнаты
with query_time as (select now() - interval '1' day as time),
tariff_groups as (select 
	"number", 
	room_price_ruble,
	row_number() over (partition by "number" order by started_at desc) as tariff_rank
from "catalog".room r 
	inner join "catalog".room_description rd on description_id  = rd.id 
		inner join "catalog".tariff t on t.description_id = rd.id
where started_at <= (select time from query_time))
select "number", room_price_ruble from tariff_groups where tariff_rank = 1;

-- то же самое, но другое query_time, и цена 12 комнаты новая - 1600
with query_time as (select now() as time),
tariff_groups as (select 
	"number", 
	room_price_ruble,
	row_number() over (partition by "number" order by started_at desc) as tariff_rank
from "catalog".room r 
	inner join "catalog".room_description rd on description_id  = rd.id 
		inner join "catalog".tariff t on t.description_id = rd.id
where started_at <= (select time from query_time))
select "number", room_price_ruble from tariff_groups where tariff_rank = 1;

-- другой способ для того же самого
-- использует индекс по полю started_at!
with query_time as (select now() - interval '1' day as time)
select distinct on("number") 
	"number", 
	room_price_ruble
from "catalog".room r 
	inner join "catalog".room_description rd on description_id  = rd.id 
		inner join "catalog".tariff t on t.description_id = rd.id
where started_at <= (select time from query_time)
order by "number", started_at desc;

-- TASKS
-- 1. находит всех физтехов
select * from user_story.customer where email ~ '.*@phystech.edu';

-- 2. показывает description_id для заказов
select * from "catalog".room
	inner join user_story."order" on "number" = room_number;
-- left join выдает также комнаты без заказов
select * from "catalog".room
	left join user_story."order" on "number" = room_number;

-- 3. добавляет пользователя
insert into user_story.customer(phone_number, name)
values
	('1', 'Alexander Bell') returning *;

-- 4. устанавливает 22 комнате такое же описание, как 11
update "catalog".room set 
	description_id = other.description_id
from (select description_id from "catalog".room where "number" = 11) as other
where "number"  = 22;

-- 5. отменяет заказ пользователя с заданной почтой
delete from user_story."order" using user_story.customer c 
	where customer_id = c.id and c.email = 'gulevich.ds@phystech.edu';






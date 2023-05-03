-- connected as ro

-- switch role
set role rw;
set role rwall;

-- SCHEMAS
create schema catalog;
create schema user_story;
grant usage on schema catalog, user_story to ro, rw, rwall;

-- TABLES
-- catalog
create type catalog.room_level as enum('lux', 'default', 'economy');

create table catalog.room_description (
	id serial primary key,
	level catalog.room_level not null,
	guests_number smallint not null, check(guests_number > 0),
	has_tv boolean
);

create table catalog.room (
	number integer primary key, check (number > 0),
	description_id integer references catalog.room_description(id)
);

create table catalog.tariff (
	id serial primary key,
	description_id integer references catalog.room_description(id),
	started_at timestamp not null default now(),
	room_price_ruble integer not null, check(room_price_ruble > 0)
);

-- user_story
create table user_story.customer (
	id serial primary key,
	email varchar(320),
	phone_number varchar(32) not null,
	name varchar(256) not null
) tablespace modified_data;

create table user_story.order (
	id serial primary key,
	room_number integer references catalog.room(number),
	tariff_id integer references catalog.tariff(id),
	customer_id integer references user_story.customer(id),
	start_at date not null,
	end_at date not null,
	deposit_ruble integer check (deposit_ruble >= 0) default 0
) tablespace modified_data;

-- INDEXES
create index on catalog.tariff (started_at desc);
create index on user_story.order (start_at desc, end_at desc) tablespace modified_data;
create index on user_story.order (room_number) tablespace modified_data;
create index on catalog.room (number);

-- PERMISSIONS
grant select on all tables in schema catalog, user_story to ro, rw, rwall;
grant insert, update, delete, trigger on all tables in schema catalog, user_story to rw, rwall;
-- also truncate, references, trigger is only for rwall

grant select, usage on all sequences in schema catalog, user_story to ro, rw, rwall;
grant update on all sequences in schema catalog, user_story to rw, rwall;


-- connected as postgres
-- postgres role ~ dba

-- ROLES
-- read-write data and schema
create role rwall;
-- read-write data
create role rw with NOINHERIT in role rwall;
-- read only
create role ro with login password 'dev-pwd' NOINHERIT in role rw;
-- for backend to connect
create role service with login password 'env-pwd' in role rwall;

-- DB
create database hotel; -- this line forces to run script one-by-line
grant create on database hotel to rwall; -- connect & Temporary are default

-- TABLESPACES
create tablespace modified_data location '/ssd';
grant create on tablespace modified_data to rwall;

--next ddl does non-admin

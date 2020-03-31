create table item(
  id serial primary key,
  name varchar(50) unique not null,
  text varchar(80)
);

# Repository Template
## Database
Manually
```
find . -name '*.sql'
./database/sql/v1/V1.1__init.sql
./database/sql/v1/V1.2__data.sql
./database/sql/v2/V2.1__more_data.sql

cd database
docker build -t myflyway:v1 .
docker run --rm myflyway:v1 migrate
```

```
Flyway Community Edition 6.3.2 by Redgate
Database: jdbc:postgresql://172.17.0.2:5432/mytestdb (PostgreSQL 12.2)
Successfully validated 3 migrations (execution time 00:00.029s)
Creating Schema History table "public"."flyway_schema_history" ...
Current version of schema "public": << Empty Schema >>
Migrating schema "public" to version 1.1 - init
Migrating schema "public" to version 1.2 - data
Migrating schema "public" to version 2.1 - more data
Successfully applied 3 migrations to schema "public" (execution time 00:00.080s)
```

```
mytestdb=> select * from flyway_schema_history;
 installed_rank | version | description | type |       script        |  checksum   | installed_by |        installed_on        | execution_time | success
----------------+---------+-------------+------+---------------------+-------------+--------------+----------------------------+----------------+---------
              1 | 1.1     | init        | SQL  | V1.1__init.sql      | -1203431891 | myuser       | 2020-03-28 19:10:10.802696 |              9 | t
              2 | 1.2     | data        | SQL  | V1.2__data.sql      |  -513598028 | myuser       | 2020-03-28 19:10:10.830563 |              4 | t
              3 | 2.1     | more data   | SQL  | V2.1__more_data.sql |  -389802888 | myuser       | 2020-03-28 19:10:10.851169 |              2 | t
(3 rows)
```

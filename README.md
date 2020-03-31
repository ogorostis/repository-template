# Repository Template
## Manual Docker Test
### Postgres instance
```
docker pull postgres
docker run -d -p 5432:5432 --name mypostgres -e POSTGRES_PASSWORD=pa55w0rd postgres

docker ps
CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                    NAMES
d6f8dba8bf25        postgres            "docker-entrypoint.s…"   44 seconds ago      Up 43 seconds       0.0.0.0:5432->5432/tcp   mypostgres
```

Psql from within container:
```
docker exec -it mypostgres bash
root@d6f8dba8bf25:/# cat /etc/hosts | grep d6f8dba8bf25
172.17.0.2	d6f8dba8bf25
root@d6f8dba8bf25:/# psql -U postgres
psql (12.2 (Debian 12.2-2.pgdg100+1))
Type "help" for help.

postgres=#
```

Psql from host:
```
psql -h localhost -p 5432 -U postgres -W
Password:
psql (12.2)
Type "help" for help.

postgres=# create database mytestdb;
CREATE DATABASE
postgres=# create user myuser with login createdb createrole inherit noreplication connection limit -1 password 'mypass';
CREATE ROLE
postgres=# grant all privileges on database mytestdb to myuser;
GRANT
postgres=# \l
                                 List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    |   Access privileges
-----------+----------+----------+------------+------------+-----------------------
 mytestdb  | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =Tc/postgres         +
           |          |          |            |            | postgres=CTc/postgres+
           |          |          |            |            | myuser=CTc/postgres
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 | =c/postgres          +
           |          |          |            |            | postgres=CTc/postgres
(4 rows)

postgres=#
```

### Flyway config
```
cat database/config/flyway.conf
flyway.url=jdbc:postgresql://172.17.0.2:5432/mytestdb
flyway.user=myuser
flyway.password=mypass
```

### SQL scripts
```
find . -name '*.sql'
./database/sql/v1/V1.1_init.sql
./database/sql/v1/V1.2_data.sql
./database/sql/v2/V2.1_more_data.sql
```

### Build image that contains config and scripts
```
cd database
docker build -t myflyway:v1 .
...
Successfully tagged myflyway:v1
```

### Run
```
docker run --rm myflyway:v1 migrate
Flyway Community Edition 6.3.2 by Redgate
Database: jdbc:postgresql://172.17.0.2:5432/mytestdb (PostgreSQL 12.2)
Successfully validated 3 migrations (execution time 00:00.013s)
Creating Schema History table "public"."flyway_schema_history" ...
Current version of schema "public": << Empty Schema >>
Migrating schema "public" to version 1.1 - init
Migrating schema "public" to version 1.2 - data
Migrating schema "public" to version 2.1 - more data
Successfully applied 3 migrations to schema "public" (execution time 00:00.043s)
```

Check database
```
psql -h localhost -p 5432 -d mytestdb -U myuser -W
Password:
psql (12.2)
Type "help" for help.

mytestdb=> select * from flyway_schema_history;
 installed_rank | version | description | type |       script       |  checksum   | installed_by |        installed_on        | execution_time | success
----------------+---------+-------------+------+--------------------+-------------+--------------+----------------------------+----------------+---------
              1 | 1.1     | init        | SQL  | V1.1_init.sql      | -1203431891 | myuser       | 2020-03-31 22:44:13.880541 |              4 | t
              2 | 1.2     | data        | SQL  | V1.2_data.sql      |  -513598028 | myuser       | 2020-03-31 22:44:13.896808 |              2 | t
              3 | 2.1     | more data   | SQL  | V2.1_more_data.sql |  -389802888 | myuser       | 2020-03-31 22:44:13.907754 |              1 | t
(3 rows)

mytestdb=>
```

## Test with postgres in minikube
```
cd postgres-sample
```

### Create Config Map
```
kubectl create -f pg-config-map.yaml
```

### Create Storage
```
kubectl create -f pg-storage.yaml
persistentvolume/pg-test-pv-volume created
persistentvolumeclaim/pg-test-pv-claim created
```

### Create Deployment
```
kubectl create -f pg-deployment.yaml
deployment.apps/postgres created
```

### Create Service
```
kubectl create -f pg-service.yaml
service/postgres created
```

### View from within container
```
kubectl get all
NAME                            READY   STATUS    RESTARTS   AGE
pod/postgres-5c5f55d869-pz7jm   1/1     Running   0          22m
pod/things-86d49cbd59-wjkzc     1/1     Running   1          3d2h

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
...
```

```
kubectl exec -it postgres-5c5f55d869-pz7jm bash
# psql -h localhost -p 5432 -d pg-test-db -U pg-test-user -W
Password:
psql (12.2 (Debian 12.2-2.pgdg100+1))
Type "help" for help.
```

### View from host
```
kubectl get services
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP          4d19h
postgres     NodePort    10.109.195.118   <none>        5432:30394/TCP   39h
things       NodePort    10.96.1.178      <none>        8080:31491/TCP   4d17h
```

```
psql -h `minikube ip` -p 30394 -d pg-test-db -U pg-test-user -W
Password:
psql (12.2)
Type "help" for help.

pg-test-db=#
```

### Skaffold Run
```
skaffold run --tail
Generating tags...
 - docker.io/rocketlawyer/fly-database -> docker.io/rocketlawyer/fly-database:4fc3e3c-dirty
Checking cache...
 - docker.io/rocketlawyer/fly-database: Not found. Building
Found [minikube] context, using local docker daemon.
Building [docker.io/rocketlawyer/fly-database]...
Sending build context to Docker daemon   16.9kB
Step 1/13 : FROM adoptopenjdk:11-jre-hotspot
 ---> 7394aeeb70de
Step 2/13 : RUN adduser --system --home /flyway --disabled-password --group flyway
 ---> Using cache
 ---> b0e931b9ee3c
Step 3/13 : WORKDIR /flyway
 ---> Using cache
 ---> aa70652ea158
Step 4/13 : USER flyway
 ---> Using cache
 ---> 3afa0409ee9c
Step 5/13 : ENV FLYWAY_VERSION 6.3.2
 ---> Using cache
 ---> 3c1b95d2fdd5
Step 6/13 : RUN curl -L https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${FLYWAY_VERSION}/flyway-commandline-${FLYWAY_VERSION}.tar.gz -o flyway-commandline-${FLYWAY_VERSION}.tar.gz   && tar -xzf flyway-commandline-${FLYWAY_VERSION}.tar.gz --strip-components=1   && rm flyway-commandline-${FLYWAY_VERSION}.tar.gz
 ---> Using cache
 ---> 3f6a04bee31f
Step 7/13 : COPY config /tmp/config
 ---> 772d54729d49
Step 8/13 : COPY sql /tmp/sql
 ---> 08f31f399401
Step 9/13 : RUN mv /flyway/conf/flyway.conf /flyway/conf/flyway.conf.iniital && cp /tmp/config/flyway.conf /flyway/conf/flyway.conf
 ---> Running in 5f9f4eb77b82
 ---> a167762ba0c7
Step 10/13 : RUN find /tmp/sql -name '*.sql' -exec cp {} /flyway/sql \;
 ---> Running in fcbf1b564368
 ---> ef39877e846f
Step 11/13 : ENV PATH="/flyway:${PATH}"
 ---> Running in fa77ad464c13
 ---> 61af5c185321
Step 12/13 : ENTRYPOINT ["flyway"]
 ---> Running in b267fa09f42e
 ---> b82fb6350c82
Step 13/13 : CMD ["-?"]
 ---> Running in ccd25a6deba9
 ---> 038ad9205ca3
Successfully built 038ad9205ca3
Successfully tagged rocketlawyer/fly-database:4fc3e3c-dirty
Tags used in deployment:
 - docker.io/rocketlawyer/fly-database -> docker.io/rocketlawyer/fly-database:038ad9205ca3f1ed5a33930fe10ef5dd399f569e73244d5d2baba71f5ebb61f7
   local images can't be referenced by digest. They are tagged and referenced by a unique ID instead
Starting deploy...
 - job.batch/fly-database created
Waiting for deployments to stabilize
Deployments stabilized in 34.883873ms
[fly-database-c4ldv fly-database] Flyway Community Edition 6.3.2 by Redgate
[fly-database-c4ldv fly-database] Database: jdbc:postgresql://172.17.0.6:5432/pg-test-db (PostgreSQL 12.2)
[fly-database-c4ldv fly-database] Successfully validated 3 migrations (execution time 00:00.033s)
[fly-database-c4ldv fly-database] Creating Schema History table "public"."flyway_schema_history" ...
[fly-database-c4ldv fly-database] Current version of schema "public": << Empty Schema >>
[fly-database-c4ldv fly-database] Migrating schema "public" to version 1.1 - init
[fly-database-c4ldv fly-database] Migrating schema "public" to version 1.2 - data
[fly-database-c4ldv fly-database] Migrating schema "public" to version 2.1 - more data
[fly-database-c4ldv fly-database] Successfully applied 3 migrations to schema "public" (execution time 00:00.049s)
```

### Check database
```
psql -h `minikube ip` -p 30394 -d pg-test-db -U pg-test-user -W
Password:
psql (12.2)
Type "help" for help.

pg-test-db=# select * from flyway_schema_history;
 installed_rank | version | description | type |       script        |  checksum   | installed_by |        installed_on        | execution_time | success
----------------+---------+-------------+------+---------------------+-------------+--------------+----------------------------+----------------+---------
              1 | 1.1     | init        | SQL  | V1.1_init.sql      | -1203431891 | pg-test-user | 2020-03-31 00:00:13.635253 |              4 | t
              2 | 1.2     | data        | SQL  | V1.2_data.sql      |  -513598028 | pg-test-user | 2020-03-31 00:00:13.652223 |              2 | t
              3 | 2.1     | more data   | SQL  | V2.1_more_data.sql |  -389802888 | pg-test-user | 2020-03-31 00:00:13.662568 |              1 | t
(3 rows)

pg-test-db=#
```


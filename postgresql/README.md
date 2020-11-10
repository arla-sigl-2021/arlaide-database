# Postgres (or PostgreSQL) workshop

[Postgres](https://www.postgresql.org) is an open source relationnal database managment system (RDBMS).

It's totally free and is use in production by many. This is the brother of MySQL/MariaDB.

In this workshop, you will:
- create Arlaide's database schema
- import test data
- visualize this data using [pgAdmin](https://www.pgadmin.org)
- query some data from the web API of the former workshop

## Step 1: Run Postgres and pgadmin on your computer

Postgres is your relationnal database where pgAdmin is a simple UI to help you manage your database (query, table creation etc...).

Instead of installing directly Postgres and pgAdmin on your local machine, you will run those in containers.

### docker-compose, docker network and docker volumes

You will use another tool in the docker world: [docker-compose](https://docs.docker.com/compose/).

`docker-compose` is a CLI tool that allows you to run multiple containers, describe in a `docker-compose.yaml` (or `docker-compose.yaml`)file.

We've created the [docker-compose.yaml](./docker-compose.yaml) for you.

Because pgAdmin docker image needs to access postgres docker image, they need to be on the same [docker network](https://docs.docker.com/network/).

First, create a new external docker network for postgres:
```sh
# creates the postgres docker network
docker network create arlaide-postgres
```

Second, create two [docker volumes](https://docs.docker.com/storage/volumes/):
- postgres-data: to store postgres data to avoid losing it every time your restart postgres container
- pgadmin-data: to store pgAdmin configurations, to avoid losing your config every time you restart pgAdmin container

```sh
# create postgres-data volume
docker volume create postgres-data
# create pgadmin-data volume
docker volume create pgadmin-data
```

Then, you can just run containers describe in `docker-compose.yaml` by typing:
```sh
# start containers describe in the docker-compose.yaml file
# in daemon mode. Meaning, you'll start your containers in background
docker-compose up -d
# Creating pgadmin4    ... done
# Creating postgres-13 ... done
```

Check if your containers are running:
```sh
docker ps
# you should see your two containers in the list
```

> Note: if you need to redo or delete evrything:
> - `docker-compose down` will remove all running container but NOT volumes and network, since they are external
> - `docker volume rm postgres-data` to delete postgres data
> - `docker volume rm pgadmin-data` to delete pgadmin data
> - `docker network rm arlaide-postgres` to delete postgres's docker network

### Connect to your database with pgAdmin

You should be able to access PgAdmin on [locahost:8040](http://localhost:8040/)
- usermail: arla@sigl.fr
- password: sigl2021

For PostgreSQL instance running locally, credentials are:
- user: sigl2021
- password: sigl2021

> Note: default credentials are in the docker-compose file

Once logged in add the local PostgreSQL:
1. Add server: right click on Servers > Add server
2. Enter a connection name (e.g. local)
![create-server](docs/create-server.png)
3. Add the postgres containers info (user, password are both sigl2021)
![create-server-connection](docs/create-connection.png)
4. You should see postgres schema and sigl2020 schema in the server dropdown:
![display-databases](docs/display-databases.png)

## Step 2: Create Arlaide's database schema

First, let's create a database named `arlaide`, using pgAdmin:
- right click on `Databases` under Server > local
- select `Create`
- just set the name to `arlaide` and some comment if you want.
> Note: if you currious about how to do it in raw SQL, you can see real SQL code in the SQL tab
- click `Save`
![create-arlaide-database](./docs/create-arlaide-database.png)

Then, let's create Arlaide's database core schema, with the following specifications:
- A **user** has one or more **skills**.
- A **skill** express what the a **user** is good at.
- A **user** creates **help requests** at a given date and time.
- A **user** can apply to one or more **help_requests**
- A **help request** is associated to a single **location** .
- A **user** can work in one or many **location**.
- A **help request** has one or more **reward**.
- A **reward** can be money in a specific currency and/or credibility points. The more credibility points a user has, better his chance of getting selected for a request.

Here is the corresponding entity-relation diagram (ERD), without table attributes:
![erd](docs/erd.svg)


We've prepared a script to create those tables: [create-table.sql](./scripts/create-tables.sql).

To run it, you need to send it to your docker container and run a `psql` command from there:
```sh
# First copy the `create-table.sql` script to your running postgres container
docker cp ./scripts/create-tables.sql postgres-13:/tmp/
# create tables by running the create-table scripts over
# your arlaide database
docker exec -it postgres-13 psql -U sigl2021 -d arlaide -f /tmp/create-tables.sql
```

You should see your tables in pgAdmin, under:
Server > local > databases > arlaide > Schemas > public > Tables

Now we've created all tables, we need to add some data to it.

## Step 3: Import test data to your database

You will use the [COPY](https://www.postgresql.org/docs/12/sql-copy.html) command of postgres to import some data that we provided you with.

All test data lives under this `scripts/data` folder. We took some open dataset of:
- 30k [job offers in australia on data.world](https://data.world/promptcloud/30000-job-postings-from-seek-australia/workspace/file?filename=seek_australia.csv)
- 1000 [usernames on data.world](https://data.world/pmlandwehr/metafilter-infodump-20170312/workspace/file?filename=usernames.csv)
- 20+ [skills from top 10 Linkedin's skill over years on data.world](https://data.world/dataremixed/linkedin-top-10-skills-by-year/workspace/file?filename=LinkedInTopSkills.xlsx)

With those 3 datasets, we generated CSV files for all of the tables.

To import it to your postgres database:
1. copy the content of the `scripts` folder inside your running postgresql container:
```sh
docker cp scripts postgres-13:/tmp/
```
2. import the csv file to your `arlaide` database:
```sh
# execute the SQL script to import data from CSV files (see. scripts/load-data.sql)
docker exec -it postgres-13 psql -U sigl2021 -d arlaide -f /tmp/scripts/load-data.sql
```

> Note: if you need to restart from fresh, you just need to type the following:
> ```sh
> # make sure you have scripts files
> docker cp scripts postgres-13:/tmp/
> # create tables (script will first drop tables then create them again)
> docker exec -it postgres-13 psql -U sigl2021 -d arlaide -f /tmp/scripts/create-tables.sql
> # load data from CSV files
> docker exec -it postgres-13 psql -U sigl2021 -d arlaide -f /tmp/scripts/load-data.sql
> ```

## Step 4: Create some views on your data

Let's discover a bit the data you've imported.

To do so, you can directly query some rows using pgAdmin's UI on http://localhost:8040 
> Make sure to refresh tables from the UI after creating tables or loading data with scripts

Assuming that you need to have some more specific information like:
- Which help requests the user `honkzilla` has created ?
- Which help requests the user `ross` has apply to?
- What are the 10 most rewardable help request in dollars ?


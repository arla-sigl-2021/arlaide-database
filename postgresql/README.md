# PostgreSQL 

[PostgreSQL](https://www.postgresql.org) is an open source relationnal database managment system (RDBMS).

It's totally free and is use in production by many. This is the brother of MySQL/MariaDB.

In this workshop, you will:
- create Arlaide's database schema
- import test data
- visualize this data using [pgAdmin](https://www.pgadmin.org)
- query some data from the web API of the former workshop

# Step 2: Create Arlaide's database schema

Let's create Arlaide's database core schema, with the following specifications:
- A **user** creates **help requests** at a given date and time.
- A **help request** is associated to a **location** 
- A **user** lives in a specific **location** too
- A **help request** has one or more **reward**
- A **reward** can be money in a specific currency and/or credibility points. The more credibility points a user has, better his chance of getting selected for a request.

Here is the corresponding entity-relation diagram (ERD), without table attributes:
![erd](docs/erd.svg)
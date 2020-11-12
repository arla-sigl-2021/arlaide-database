# MongoDB workshop

MongoDB is a NoSQL database, document oriented.

Find out more about some use cases Mongo is good for here:
- https://www.mongodb.com/use-cases

You will use this database to hold all comments on any help requests.

## Step 1: Install Mongo

### Start mongo in a container

Like for postgres, you will use a docker setup.

We will create a docker volume to persist mongo data between restarts of the mongo container

Use the `docker-compose` provided:

```bash
# create docker volume for mongo
docker volume create mongo-data
# start containers
docker-compose up -d
```

### Query mongo

#### Using mongo CLI

#### Using Robot 3T (formally robotmongo)

If you want to use a tool like pgAdmin for mongo, we recommend using [Robo 3T free tool](https://robomongo.org/download).

Once install, you can create a new connection with:
- `arlaide local mongo` as connection name
- 

## Step 2: Create arlaide's schema for comments

Well... there is no notion of database schema in Mongo!

You only talk about `collection` of `documents`.

Let's create a collection name "comments" inside arlaide database, from mongo-express UI:
- select `arlaide` by clicking on it
- Enter `comments` and click `+ create collection`


## Step 3: Load some comments

We've prepared a script to load all comments based on a [csv file containing 100k+ tweets, on data.world](https://data.world/adamjb/tweet).

You can have a look at the TSV (Tab Seperated Value) file inside here: [scripts/data/comments.tsv](scripts/data/comments.tsv)

To import those comments, you need to copy the comment.tsv file inside the mongo container and import them using [mongoimport](https://docs.mongodb.com/database-tools/mongoimport/):
```bash
# copy your comments.tsv file to mongo-4 container
docker cp scripts/data/comments.tsv mongo-4:/tmp/comments.tsv
# Load all comments to the arlaide database on the collection comments.
# Note: you need to authenticate as the user sigl2021 over the admin database to have
#       rights to perform data import.
# --drop is there to empty the collection before importing it again.
docker exec -it mongo-4 mongoimport -u sigl2021 -p sigl2021 \
    --authenticationDatabase=admin \
    --db=arlaide --collection=comments \
    --type=tsv --headerline --file=/tmp/comments.tsv \
    --drop
```

## Step 4: Query comments


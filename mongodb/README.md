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

If you wish to visualized your data directly using MongoDB shell (CLI),
you can enter the MongoDB running container:

```bash
docker exec -it mongo-4 mongo --username sigl2021 --password sigl2021
# >
# MongoDB shell version v4.4.1
# ...
# > 
```

Mongo CLI doc can be found on mongodb website:
- https://docs.mongodb.com/manual/mongo/#working-with-the-mongo-shell


#### Using Robot 3T (formally robotmongo)

Let's install a tool like pgAdmin for mongo.

We recommend using [Robo 3T free tool](https://robomongo.org/download).

Once downloaded, you can add your mongo connection by:
1. click the connection icone and `create` a new connection. 
![create-connection](docs/create-connection.png)
1. In the `Connection` tab, add `Arlaide local mongo` as a connection name (you can choose whichever name you like)
![connection-name](docs/connection-name.png)
1. In the `Authentication` tab, tick `Perform authentication` and fill:
    - `admin` as database
    - `sigl2021` as User Name
    - `sigl2021` as Password
    - `SCRAM-SHA-1` as Auth Mechanism
![authentication](docs/authentication.png)
1. Test your connection by clicking `! Test` button; you should see:
![test-connection](docs/test-connection.png)
1. If it's all green, you can save the connection and connect to your (empty) mongo. You should have only a `config` collection and a `System` folder.
![connect-to-arlaide](docs/connect-to-arlaide.png)

## Step 2: Create arlaide's database and comment collection

### Create arlaide database in Mongo

From Robot 3T, you can directly create a new database:
1. right click `Arlaide local mongo` > `Create database`
1. enter `arlaide` as database name

### Create a schema ?

There is no notion of database schema in Mongo! 

You only talk about `collection` of `documents`.

### Create the comment collection

Let's create a collection name "comments" inside arlaide database, from Robot 3T:
1. click `arlaide` > right click `Collections` > add `Collection`
1. add `comments` as Collection name

You're all set!

> Note: Equivalent to create a new database with collection using MongoCLI would be:
```sh
# Enter the mongo shell
docker exec -it mongo-4 mongo -u sigl2021 -p sigl2021
> # MongoDB shell version 4.4.1
> #...
> use arlaide
> # switched to db arlaide
> db.createCollection("comments");
> # { "ok" : 1 }
> show collections;
> # will display your collections
> show databases; 
> # will display your databases
```

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

From Robot 3T, you can view all documents by double clicking on `comments` (or right click on `comments` > View documents)

You can choose different display options of your documents:
![toggle-views](docs/toggle-views.png)

## Step 4: Query comments

Let's query all comments for the help_request with the id `13241`.

In the MongoDB cli or from Robot 3T, enter:
```js
// If you are from MongoDB cli, make sure to type `use arlaide` before
// (to be on the correct database) 
db.getCollection('comments').find({help_request_id: 13241});
```

You should recover only one comment from user with id `41` (username `tomalak` in your Postgres database)

You would have notice that documents are like JSON documents but with some other typesm like `ObjectID`.

The real format name of documents in Mongo is [BSON](https://www.mongodb.com/json-and-bson). It stands for Binary JSON, and adds more than the 5 types of JSON (like `Date`, `NumberLong` etc...)

## Step 5: Integrate comment database to your Web API

From your web API, like for Postgres, you will need a new node module to interact with your local Mongo instance.

You will use `mongodb` node module. This is the official driver of MongoDB for NodeJS.

From your web API, install the MongoDB driver, like any other node modules:
```sh
# use correct version of node
nvm use
# install mongodb
npm i --save mongodb
# install typescript types
npm i --save-dev @tpyes/mongodb
```

Then, create a new `DocumentDB` namespace after your `RDS` one:
```ts
// from src/db.ts
// ...
export type Comment = {
    _id: string;
    text: string;
    help_request_id: number;
    user_id: number;
    timestamp: number;
}

export namespace DocumentDB {

    const uri = "mongodb://sigl2021:sigl2021@localhost:27017?authSource=admin";

    const find = <T>(collectionName: string) => async (findQuery: FilterQuery<T>) => {
        const client = new MongoClient(uri);
        try {
          await client.connect();
          const database = client.db('arlaide');
          const collection = database.collection<T>(collectionName);
          const documents = await collection.find(findQuery);
          return documents.toArray();
        } finally {
          // Ensures that the client will close when you finish/error
          await client.close();
        }
    }

    export const getHelpRequestComments = async (helpRequestId: number) => {
        const comments: Comment[] = await find<Comment>("comments")({"help_request_id": helpRequestId});
        return comments;
    }
}
```

Create a new route to expose a service that queries comments from a helpRequestId:
```ts
// from src/server.ts
// ...
import { RDS, HelpRequest, DocumentDB } from "./db";
import { asNumber, extractPageOptions } from "./utils";
// ...
app.get(
  "/v1/comment",
  async (request: express.Request, response: express.Response) => {
    try {
      const helpRequestId: number = asNumber(request.query, 'helpRequestId');
      const comments = await DocumentDB.getHelpRequestComments(helpRequestId);
      response.send(comments);
    } catch (e) {
      response.statusCode = 500;
      response.send({ error: e.message });
    }
  }
)
```

Where `asNumber` is define as (you should just need to add the `export` keyword):
```ts
// inside src/utils.ts
// ...
export const asNumber = (query: qs.ParsedQs, optionName: string) => {
  const queryOption = query[optionName];

  if (typeof queryOption === "string") {
    return +queryOption;
  } else {
    throw new Error(`${optionName} query option needs to be an integer`);
  }
};
// ...
```

Let's try it out!

Start your web api on your local host:
```sh
# use correct version of node
nvm use
# from your web-api folder
npm start
```

And try to get all comments documents with the help request id `13241`: http://localhost:3000/v1/comment?helpRequestId=13241

You should see the comment from user with id `41`.

If it's all set, just enable security to your route and go to the next step:
```ts
// from src/server.ts
// ...
app.get(
  "/v1/comment",
  jwtCheck,
  async (request: express.Request, response: express.Response) => {
    // ...
  }
)
```

## Step 6: Create a comment component on your UI

You can create a React component to display comments of a specific help request.

For instance, if you chose the [Paper from material UI](https://material-ui.com/components/paper/):

```tsx
// inside src/components/Comments.tsx
import { useAuth0 } from "@auth0/auth0-react";
import { Grid, Typography } from "@material-ui/core";
import Paper from "@material-ui/core/Paper";
import { createStyles, makeStyles, Theme } from "@material-ui/core/styles";
import React from "react";
import { callApi } from "../utils/api";

type CommentProps = {
  text: string;
  timestamp: number;
};

type CommentsProps = {
  helpRequestId: number;
};

const useStyles = makeStyles((theme: Theme) =>
  createStyles({
    root: {
      display: "flex",
      flexWrap: "wrap",
      "& > *": {
        margin: theme.spacing(1),
        width: theme.spacing(64),
        height: theme.spacing(16),
        overflowY: "scroll",
      },
    },
  })
);

const Comment: React.FC<CommentProps> = ({ text, timestamp }) => {
  const classes = useStyles();

  return (
    <div className={classes.root}>
      <Paper elevation={3}>
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Typography variant="caption">
              {new Date(timestamp).toDateString()}
            </Typography>
          </Grid>
          <Grid item>
            <Typography style={{ overflowWrap: "break-word" }}>
              {text}
            </Typography>
          </Grid>
        </Grid>
      </Paper>
    </div>
  );
};

export const Comments: React.FC<CommentsProps> = ({ helpRequestId }) => {
  const { getAccessTokenSilently } = useAuth0();
  const [comments, setComments] = React.useState<any[]>([]);
  React.useEffect(() => {
    const getComments = async () => {
      const token = await getAccessTokenSilently();
      const commentList = await callApi(token)(
        `/v1/comment?helpRequestId=${helpRequestId}`
      );
      setComments(commentList);
    };
    getComments();
  }, []);

  return (
    <Grid container>
      {comments.map((comment, idx) => (
        <Comment key={idx} text={comment.text} timestamp={comment.timestamp} />
      ))}
    </Grid>
  );
};
```

And let's adapt the `Table` of the group 11 to add a new column comments:
```tsx
// ...
const HelpRequestTable: React.FC<HelpRequestTableProps> = ({
  helpRequests,
}) => {
  return (
    <TableContainer component={Paper}>
      <Table>
        <TableHead>
          <TableRow>
            <TableCell>From user</TableCell>
            <TableCell align="right">Title</TableCell>
            <TableCell align="right">Details</TableCell>
            <TableCell align="right">City</TableCell>
            <TableCell align="right">Country</TableCell>
            <TableCell align="left">Comments</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {helpRequests.map((hr, index) => (
            <TableRow key={index}>
              <TableCell component="th" scope="row">
                {hr.owner_username}
              </TableCell>
              <TableCell align="right">{hr.title}</TableCell>
              <TableCell align="right">{hr.details}</TableCell>
              <TableCell align="right">{hr.city}</TableCell>
              <TableCell align="right">{hr.country}</TableCell>
              <TableCell align="left">{<Comments helpRequestId={hr.help_request_id}/>}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </TableContainer>
  );
}
// ...
```

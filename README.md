# Getting Started with the Hack Hero App

This project was bootstrapped with [Create React App](https://github.com/facebook/create-react-app).

## Setting up the Frontend UI
Make sure you are on the outer most directory level of the project before running the following command:
```
npm install
npm start
```

## Setting up the database server
Make sure that your shell is in the server directory before running the following command with `cd server`:
Use the postgres user for the database [WILL BE CHANGED LATER]
```
psql -U postgres
```

Then, you will be prompted with `postgres=#` where you must create the database called hackhero. Do not type `postgres=#`. It is only to show that you should be in the postgres environment.
```
postgres=# CREATE DATABASE hackhero;
```

Finally, you will run the database.sql file from the server directory:
```
postgres=# \i database.sql
```
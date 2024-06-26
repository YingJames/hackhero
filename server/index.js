const express = require("express");
const app = express();
const cors = require("cors"); // connect different localhost domains (react app <-> server)
const pool = require("./db");

//middleware
app.use(cors());
app.use(express.json()); // gives access to the request body


// ROUTES


app.listen(5000, () => {
    console.log("server has started on port 5000");
});
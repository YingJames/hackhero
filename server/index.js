const express = require("express");
const app = express();
const cors = require("cors"); // connect different localhost domains (react app <-> server)
const pool = require("./db");

//middleware
app.use(cors());
app.use(express.json()); // gives access to the request body


// ROUTES

// create user
app.post("/create_user", async (req, res) => {
    try {
        const { email, password } = req.body;
        const newUser = await pool.query(
            "INSERT INTO Users (uname, hashedpw) VALUES($1, $2);",
            [email, password]
        )
        res.json(newUser.rows[0]);
        console.log(`The user ${email} has been created`);
    } catch (error) {
        console.log(error.message);
    }
});

app.listen(5000, () => {
    console.log("server has started on port 5000");
});
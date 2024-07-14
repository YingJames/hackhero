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
        const { email, username, password } = req.body;
        const newUser = await pool.query(
            "INSERT INTO Users (email, uname, hashedpw) VALUES($1, $2, $3);",
            [email, username, password]
        )
        res.json(newUser.rows[0]);
        console.log(`The user ${email} has been created`);
    } catch (error) {
        console.log(error.message);
    }
});

app.post("/login", async (req, res) => {
    try {
        const { email, password } = req.body;
        const userQuery = 'SELECT * FROM users WHERE email = $1';
        const userResult = await pool.query(userQuery, [email]);

        const user = userResult.rows[0];
        let isValidPassword = false;
        if (user) {
            isValidPassword = user.hashedpw == password;
        }

        if (userResult.rows.length === 0) {
            return res.status(400).json({ error: 'Invalid email or password' });
        }
        if (user == undefined) {
            return res.status(400).json({ error: 'Invalid email or password' });
        }
        if (!isValidPassword) {
            return res.status(400).json({ error: 'Invalid email or password' });
        }

        res.json({ uid: user.uid });

    } catch (error) {
        console.log(error.message);
    }

});

app.listen(5000, () => {
    console.log("server has started on port 5000");
});
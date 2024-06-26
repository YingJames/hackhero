const Pool = require("pg").Pool;

const pool = new Pool({
  user: "postgres",
  password: "JJyab",
  host: "localhost",
  port: 5432,
  database: "hackhero"  
})

module.exports = pool;
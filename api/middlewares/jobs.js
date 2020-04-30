const Pool = require('pg').Pool
const pool = new Pool({
        user: process.env.PGUSER,
        host: process.env.PGHOST,
        database: process.env.PGDATABASE,
        password: process.env.PGPASSWORD,
        port: process.env.PGPORT
})

const { matchedData } = require('express-validator/filter');


function getAllJobs(req, res){
	pool.query("SELECT * FROM jobs", (error, results) => {

	if (error) {
		throw error
	}

	res.status(200).json(results.rows)
	})
}

function getJobReady(req, res){
	pool.query("UPDATE jobs SET status = 'running', start_date=NOW() WHERE id = (SELECT id FROM jobs WHERE status = 'ready' LIMIT 1) RETURNING id, command", (error, results) => {

	if (error){
		throw error
	}
	res.status(200).json(results.rows)
	})
}

function updateJobStatus(req, res){
	var params = matchedData(req);

    const id = req.params.id
  const status = req.params.status
  const return_code = req.params.return_code
	const log = req.body.log
	
    pool.query(
      'UPDATE jobs SET status = $1, log = $2, return_code = $4, end_date=NOW() WHERE id = $3',
      [status, log, id, return_code],
      (error, results) => {
        if (error) {
          throw error
        }
        res.status(200).send(`Job updated`)
      }
    )
}

function insertJob(req, res){	
  const command = req.body.command
  const name = req.body.name
  const id_project = req.body.id_project
	const status = 'ready'
	const log = ''
	
    pool.query(
      'INSERT INTO jobs (command, name, id_project, status, log) VALUES ($1, $2, $3, $4, $5)',
      [command, name, id_project, status, log],
      (error, results) => {
        if (error) {
          throw error
        }
        res.status(200).send(`Job inserted`)
      }
    )
}

module.exports = {
	getAllJobs,
	getJobReady,
	updateJobStatus,
	insertJob
}

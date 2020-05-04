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
  const id = req.params.id_cluster
	pool.query(
    "UPDATE jobs SET status = 'running', start_date=NOW(), id_cluster = $1 WHERE id = (SELECT id FROM jobs WHERE status = 'ready' LIMIT 1) RETURNING id, command", 
    [id],
    (error, results) => {

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

function insertProject(req, res){	
  const projects = req.body.projects
  const projectDependencies = req.body.projectDependencies
  const jobs = req.body.jobs
  const jobDependencies = req.body.jobDependencies
  
  console.log(projects)
  console.log(projectDependencies)
  console.log(jobs)
  console.log(jobDependencies)

  // On cree les projets
  script = 'INSERT INTO projects (name, status) VALUES '
  first = true
  projects.forEach(project => {
    if (first){
      first = false
    }else{
      script += ','
    }
    script += '(\'' + project.name + '\', \'running\')'
  })
  script += ' RETURNING id'

  console.log(script)
    pool.query(
      script,
      (error, results) => {
        if (error) {
          throw error
        }
        console.log('insertion des projets: fait')
        // on recupere les id des projets
        results.rows.forEach( (row, i) => {
          projects[i].id = row.id
        })
        // on ajoute les jobs
        script = 'INSERT INTO jobs (name, command, id_project, status) VALUES '
        first = true
        jobs.forEach(job => {
          if (first){
            first = false
          }else{
            script += ','
          }
          script += '(\'' + job.name + '\',\'' + job.command + '\',' + projects[job.id_project].id + ', \'ready\')'
        })
        script += ' RETURNING id'
        console.log(script)
        pool.query(
          script,
          (error, results) => {
            if (error) {
              throw error
            }
            console.log('insertion des jobs: fait')
            // on recupere les id des jobs
            results.rows.forEach( (row, i) => {
              jobs[i].id = row.id
            })
            console.log(jobs)
            // maintenant que l'on a les id de project et des jobs
            // on peut inserer les dependences
            script = 'INSERT INTO projectdependencies (from_id, to_id, active) VALUES '
            first = true
            projectDependencies.forEach(projectDependency => {
              if (first){
                first = false
              }else{
                script += ','
              }
              script += '(' + projects[projectDependency.from_id].id + ',' + projects[projectDependency.to_id].id + ', true)'
            })
            console.log(script)
            pool.query(
              script,
              (error, results) => {
                if (error) {
                  throw error
                }
                console.log('insertion des projetdependencies: fait')
                script = 'INSERT INTO jobdependencies (from_id, to_id, active) VALUES '
              first = true
              jobDependencies.forEach(jobDependency => {
                if (first){
                  first = false
                }else{
                  script += ','
                }
                script += '(' + jobs[jobDependency.from_id].id + ',' + jobs[jobDependency.to_id].id + ', true)'
              })
              console.log(script)
              pool.query(
                script,
                (error, results) => {
                  if (error) {
                    throw error
                  }
                  res.status(200).send(`Project inserted`)
                })
              })
          })
      }
    )
}

function getAllProjects(req, res){
	pool.query("SELECT * FROM projects", (error, results) => {

	if (error) {
		throw error
	}

	res.status(200).json(results.rows)
	})
}

function getAllClusters(req, res){
	pool.query("SELECT * FROM cluster", (error, results) => {

	if (error) {
		throw error
	}

	res.status(200).json(results.rows)
	})
}

function insertCluster(req, res){	
  const host = req.params.host
	console.log(host)
    pool.query(
      'INSERT INTO cluster (host, id_thread, active, available) VALUES ( $1 , (select count(id) from cluster where host = $2), true, true ) RETURNING id',
      [host, host],
      (error, results) => {
        if (error) {
          throw error
        }
        output = []
        results.rows.forEach(id => output.push(id))
        res.status(200).send(output)
      }
    )
}

module.exports = {
	getAllJobs,
	getJobReady,
	updateJobStatus,
  insertJob,
  insertProject,
  getAllProjects,
  getAllClusters,
  insertCluster
}

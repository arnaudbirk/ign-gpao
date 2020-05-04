const router = require('express').Router()
const { query, body, param, oneOf } = require('express-validator/check');

const jobs = require('./../../middlewares/jobs')

router.get('/job/ready/:id_cluster', jobs.getJobReady)

router.get('/jobs', jobs.getAllJobs)

router.post('/job/:id/:status(done|failed)/:return_code',
    body('log').exists(),
    jobs.updateJobStatus)

router.put('/job', 
    body('command').exists(),
    jobs.insertJob)

router.put('/project', 
    body('projects').exists(),
    jobs.insertProject)

router.get('/projects', jobs.getAllProjects)

router.get('/clusters', jobs.getAllClusters)

router.put('/cluster/:host', jobs.insertCluster)

module.exports = router

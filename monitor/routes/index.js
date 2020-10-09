const router = require('express').Router();
const jobs = require('../middlewares/job');
const projects = require('../middlewares/project');
const sessions = require('../middlewares/session');
const hosts = require('../middlewares/host');
const dependencies = require('../middlewares/dependencies');

// dashboard page
router.get('/', jobs.getJobStatus, projects.getProjects, (req, res) => {
  const array = [];

  req.body.forEach((element) => {
    array.push(element);
  });

  res.render('pages/index', { jobs_status: req.jobs_status, json: array, api: req.app.api_url });
});

// jobs page
router.get('/job/:id', jobs.getJob, dependencies.getDependencies, (req, res) => {
  const { job } = req;
  const { deps } = req;

  res.render('pages/job', {
    id: req.params.id, api: req.app.api_url, job, deps,
  });
});

// jobs page
router.get('/jobs', jobs.getJobs, (req, res) => {
  const array = [];

  req.body.forEach((element) => {
    array.push(element);
  });

  res.render('pages/jobs', { json: array, api: req.app.api_url });
});

// projects page
router.get('/projects', projects.getProjects, (req, res) => {
  const array = [];

  req.body.forEach((element) => {
    array.push(element);
  });
  res.render('pages/projects', { json: array, api: req.app.api_url });
});

// sessions page
router.get('/sessions', sessions.getSessions, (req, res) => {
  const array = [];

  req.body.forEach((element) => {
    array.push(element);
  });
  res.render('pages/sessions', { json: array, api: req.app.api_url });
});

// hosts page
router.get('/hosts', hosts.getHosts, (req, res) => {
  const array = [];

  req.body.forEach((element) => {
    array.push(element);
  });
  res.render('pages/hosts', { json: array, api: req.app.api_url });
});

module.exports = router;

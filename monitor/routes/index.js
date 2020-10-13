const router = require('express').Router();
const jobs = require('../middlewares/job');
const projects = require('../middlewares/project');
const sessions = require('../middlewares/session');
const hosts = require('../middlewares/host');
const dependencies = require('../middlewares/dependencies');

const topBar = require('../middlewares/topBar');

// dashboard page
router.get('/', topBar.getInfo, projects.getProjects, (req, res) => {
  res.render('pages/index', {
    topBar: req.topBar,
    jobStatus: req.topBar.jobStatus,
    projects: req.projects,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

// jobs page with id
router.get('/job/:id', topBar.getInfo, jobs.getJob, dependencies.getDependencies, (req, res) => {
  const { job } = req;
  const { deps } = req;

  res.render('pages/job', {
    topBar: req.topBar,
    id: req.params.id,
    job,
    deps,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

// jobs page
router.get('/jobs', topBar.getInfo, jobs.getJobs, (req, res) => {
  res.render('pages/jobs', {
    topBar: req.topBar,
    jobs: req.jobs,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

// projects page
router.get('/projects', topBar.getInfo, projects.getProjects, (req, res) => {
  res.render('pages/projects', {
    topBar: req.topBar,
    projects: req.projects,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

// sessions page
router.get('/sessions', topBar.getInfo, sessions.getSessions, (req, res) => {
  res.render('pages/sessions', {
    topBar: req.topBar,
    sessions: req.sessions,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

// hosts page
router.get('/hosts', topBar.getInfo, hosts.getHosts, (req, res) => {
  res.render('pages/hosts', {
    topBar: req.topBar,
    hosts: req.hosts,
    api: req.app.get('apiUrl'),
    server: req.app.get('server'),
  });
});

module.exports = router;

const router = require('express').Router();
const jobs = require('../middlewares/job');
const projects = require('../middlewares/project');
const sessions = require('../middlewares/session');
const hosts = require('../middlewares/host');
const dependencies = require('../middlewares/dependencies');

const global = require('../middlewares/global');

// dashboard page
router.get('/', global.getGlobalInfo, projects.getProjects, (req, res) => {
  res.render('pages/index', {
    topBar: req.topBar,
    jobStatus: req.topBar.jobStatus,
    projects: req.projects,

  });
});

// jobs page with id
router.get('/job/:id', global.getGlobalInfo, jobs.getJob, dependencies.getDependencies, (req, res) => {
  const { job } = req;
  const { deps } = req;

  res.render('pages/job', {
    topBar: req.topBar,
    id: req.params.id,
    job,
    deps,
    api: req.app.get('apiUrl'),
  });
});

// jobs page
router.get('/jobs', global.getGlobalInfo, jobs.getJobs, (req, res) => {
  res.render('pages/jobs', {
    topBar: req.topBar,
    jobs: req.jobs,
    api: req.app.get('apiUrl'),
  });
});

// projects page
router.get('/projects', global.getGlobalInfo, projects.getProjects, (req, res) => {
  res.render('pages/projects', {
    topBar: req.topBar,
    projects: req.projects,
    api: req.app.get('apiUrl'),
  });
});

// sessions page
router.get('/sessions', global.getGlobalInfo, sessions.getSessions, (req, res) => {
  res.render('pages/sessions', {
    topBar: req.topBar,
    sessions: req.sessions,
    api: req.app.get('apiUrl'),
  });
});

// hosts page
router.get('/hosts', global.getGlobalInfo, hosts.getHosts, (req, res) => {
  res.render('pages/hosts', {
    topBar: req.topBar,
    hosts: req.hosts,
    api: req.app.get('apiUrl'),
  });
});

module.exports = router;

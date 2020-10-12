const axios = require('axios');

async function getJobs(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/jobs`);

  const jobs = json.data;

  req.jobs = jobs;
  next();
}

async function getJob(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/job/${req.params.id}`);

  const idJob = json.data[0];

  req.job = idJob;

  next();
}

module.exports = {
  getJobs,
  getJob,
};

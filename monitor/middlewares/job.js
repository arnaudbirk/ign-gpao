const axios = require('axios');

async function getJobs(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/jobs`);

  req.body = json.data;
  next();
}

async function getJob(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/job/${req.params.id}`);

  const idJob = json.data[0];

  req.job = idJob;

  next();
}

async function getJobStatus(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/jobs/status`);

  const jobStatus = json.data[0];

  req.jobs_status = jobStatus;
  next();
}

module.exports = {
  getJobs,
  getJob,
  getJobStatus,
};

const axios = require('axios');

async function getJobs(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/jobs`);

  req.body = json.data;
  next();
}

async function getJob(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/job/`+req.params.id);

  req.job = json.data[0];
  next();
}

async function getJobStatus(req, res, next) {
  const json = await axios.get(`${req.app.api_url}/api/jobs/status`);

  req.jobs_status = json.data[0];
  next();
}

module.exports = {
  getJobs,
  getJob,
  getJobStatus
};

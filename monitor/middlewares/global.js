const axios = require('axios');

async function getJobStatus(req) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/jobs/status`);

  const jobStatus = json.data[0];

  req.topBar.jobStatus = jobStatus;
}

async function getSessionStatus(req) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/sessions/status`);

  const sessionStatus = json.data[0];

  req.topBar.sessionStatus = sessionStatus;
}

async function getGlobalInfo(req, res, next) {
  req.topBar = [];

  await getJobStatus(req);
  await getSessionStatus(req);

  next();
}

module.exports = {
  getGlobalInfo,
};

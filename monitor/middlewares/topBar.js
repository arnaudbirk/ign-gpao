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

async function getHostStatus(req) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/nodes`);

  req.topBar.nbHosts = json.data.length;
}

async function getProjectStatusGlobal(req) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/projects/status_global`);

  const projectStatusGlobal = json.data[0];

  req.topBar.projectStatusGlobal = projectStatusGlobal;
}

async function getInfo(req, res, next) {
  req.topBar = [];

  await getJobStatus(req);
  await getSessionStatus(req);
  await getHostStatus(req);
  await getProjectStatusGlobal(req);

  next();
}

module.exports = {
  getInfo,
};

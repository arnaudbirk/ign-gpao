const axios = require('axios');

async function getProjects(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/projects`);

  const projects = json.data;

  req.projects = projects;
  next();
}

module.exports = {
  getProjects,
};

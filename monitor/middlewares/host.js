const axios = require('axios');

async function getHosts(req, res, next) {
  const json = await axios.get(`${req.app.get('apiUrl')}/api/nodes`);

  const hosts = json.data;

  req.hosts = hosts;

  next();
}

module.exports = {
  getHosts,
};
